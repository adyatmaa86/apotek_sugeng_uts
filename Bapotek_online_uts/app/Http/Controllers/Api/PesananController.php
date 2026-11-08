<?php

namespace App\Http\Controllers\Api;

use App\Models\Keranjang;
use App\Models\KunciIdempoten;
use App\Models\Kurir;
use App\Models\Pesanan;
use App\Models\PesananDetail;
use App\Models\Produk;
use App\Services\PesananStatusService;
use App\Services\RajaOngkirService;
use App\Services\XenditService;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class PesananController extends BaseApiController
{
    protected XenditService $xenditService;
    protected RajaOngkirService $rajaOngkirService;
    protected PesananStatusService $statusService;

    public function __construct(
        XenditService $xenditService,
        RajaOngkirService $rajaOngkirService,
        PesananStatusService $statusService
    ) {
        $this->xenditService = $xenditService;
        $this->rajaOngkirService = $rajaOngkirService;
        $this->statusService = $statusService;
    }

    /**
     * POST /api/checkout
     * Wajib menerima header X-Kunci-Idempoten; 201 bila berhasil
     * Single DB transaction: cek stok dengan lock, validasi resep, simpan pesanan & snapshot harga, kurangi stok, kosongkan keranjang.
     */
    public function checkout(Request $request): JsonResponse
    {
        // 1. Cek Header Idempotensi (PRD Bab 7.1 & Bab 9)
        $idempotencyKey = $request->header('X-Kunci-Idempoten');
        if (empty($idempotencyKey)) {
            return $this->gagal('Header X-Kunci-Idempoten wajib disertakan pada permintaan checkout', 422, [
                'X-Kunci-Idempoten' => ['Header X-Kunci-Idempoten wajib disertakan'],
            ]);
        }

        // Cek apakah request dengan kunci ini sudah pernah diproses sukses sebelumnya
        $pesananExisting = $this->pesananBerdasarkanKunci($idempotencyKey);
        if ($pesananExisting) {
            return $this->sukses($pesananExisting, 'Pesanan telah diproses sebelumnya (Idempoten)', 201);
        }

        // 2. Validasi Input Form Checkout
        $validator = Validator::make($request->all(), [
            'nama_penerima' => 'required|string|max:255',
            'alamat' => 'required|string|max:500',
            'kurir_id' => 'nullable|required_without:rajaongkir_destination|exists:kurirs,id',
            'metode_pembayaran' => 'required|in:cod,transfer_manual,xendit',
            'nomor_resep' => 'nullable|string|max:100',
            'rajaongkir_destination' => 'nullable|string|max:20',
            'rajaongkir_courier' => 'required_with:rajaongkir_destination|nullable|string|in:jne,pos,tiki',
            'rajaongkir_service' => 'required_with:rajaongkir_destination|nullable|string|max:50',
        ], [
            'nama_penerima.required' => 'Nama penerima wajib diisi',
            'alamat.required' => 'Alamat pengiriman wajib diisi',
            'kurir_id.required_without' => 'Pilih kurir pengiriman atau layanan RajaOngkir',
            'metode_pembayaran.required' => 'Metode pembayaran wajib dipilih',
            'metode_pembayaran.in' => 'Metode pembayaran tidak valid',
            'rajaongkir_courier.required_with' => 'Kurir RajaOngkir wajib dipilih',
            'rajaongkir_service.required_with' => 'Layanan RajaOngkir wajib dipilih',
        ]);

        if ($validator->fails()) {
            return $this->gagal('Data yang dikirim tidak lengkap', 422, $validator->errors()->toArray());
        }

        // 3. Database Transaction & Pessimistic Row Locking
        try {
            $pesananBaru = DB::transaction(function () use ($request, $idempotencyKey) {
                // Ambil isi keranjang pelanggan
                $keranjangItems = Keranjang::where('pelanggan_id', $this->pelangganId($request))->get();

                if ($keranjangItems->isEmpty()) {
                    throw new \DomainException('Keranjang belanja Anda masih kosong', 409);
                }

                $subtotal = 0;
                $adaProdukPerluResep = false;
                $detailItemsToInsert = [];

                foreach ($keranjangItems as $item) {
                    // Lock baris produk untuk menghindari race condition
                    $produk = Produk::where('id', $item->produk_id)->lockForUpdate()->first();

                    if (!$produk || !$produk->tersedia) {
                        throw new \DomainException("Produk '{$item->produk_id}' sudah tidak tersedia", 409);
                    }

                    if ($produk->stok < $item->jumlah) {
                        throw new \DomainException("Stok produk '{$produk->nama}' tidak mencukupi (Tersedia: {$produk->stok})", 409);
                    }

                    if ($item->jumlah > $produk->batas_per_pembelian) {
                        throw new \DomainException("Jumlah pesanan untuk '{$produk->nama}' melebihi batas pembelian ({$produk->batas_per_pembelian})", 409);
                    }

                    if ($produk->perlu_resep) {
                        $adaProdukPerluResep = true;
                    }

                    $itemSubtotal = $item->jumlah * $produk->harga;
                    $subtotal += $itemSubtotal;

                    $detailItemsToInsert[] = [
                        'produk' => $produk,
                        'jumlah' => $item->jumlah,
                        'harga_saat_beli' => $produk->harga,
                        'subtotal' => $itemSubtotal,
                        'perlu_resep' => $produk->perlu_resep,
                    ];
                }

                // PRD Aturan Bisnis Apotek: Jika ada produk perlu resep, nomor resep WAJIB diisi
                if ($adaProdukPerluResep && empty(trim((string) $request->nomor_resep))) {
                    throw new \InvalidArgumentException('Pesanan memuat obat dengan tanda resep dokter. Nomor resep wajib diisi.', 422);
                }

                // Hitung ongkir sepenuhnya di server
                $ongkosKirim = 0;
                $rajaongkirService = null;

                if ($request->filled('rajaongkir_destination')) {
                    $courier = strtolower((string) $request->input('rajaongkir_courier', 'jne'));
                    $service = strtoupper((string) $request->input('rajaongkir_service'));
                    $hasilTarif = $this->rajaOngkirService->calculateCost(
                        (string) $request->input('rajaongkir_destination'),
                        1000,
                        $courier
                    );
                    $nilaiTarif = $this->cariTarifRajaOngkir($hasilTarif, $service);

                    if ($nilaiTarif === null) {
                        throw new \DomainException(
                            "Layanan RajaOngkir {$courier} {$service} tidak tersedia untuk kota tujuan tersebut",
                            409
                        );
                    }

                    $ongkosKirim = $nilaiTarif;
                    $rajaongkirService = 'RajaOngkir ' . strtoupper($courier) . ' - ' . $service;
                } else {
                    $kurir = Kurir::find($request->kurir_id);

                    if (! $kurir) {
                        throw new \DomainException('Kurir pengiriman tidak ditemukan', 409);
                    }

                    $ongkosKirim = (int) $kurir->tarif;
                }

                $total = $subtotal + $ongkosKirim;
                $nomorPesanan = 'APT-' . date('YmdHis') . '-' . strtoupper(Str::random(4));

                // Buat Pesanan
                $pesanan = Pesanan::create([
                    'nomor_pesanan' => $nomorPesanan,
                    'pelanggan_id' => $this->pelangganId($request),
                    'nama_penerima' => $request->nama_penerima,
                    'alamat' => $request->alamat,
                    'kurir_id' => $request->filled('rajaongkir_destination') ? null : $request->kurir_id,
                    'ongkos_kirim' => $ongkosKirim,
                    'subtotal' => $subtotal,
                    'total' => $total,
                    'metode_pembayaran' => $request->metode_pembayaran,
                    'status' => 'menunggu_pembayaran',
                    'nomor_resep' => $request->nomor_resep,
                    'rajaongkir_service' => $rajaongkirService,
                ]);

                // Simpan Detail & Potong Stok
                foreach ($detailItemsToInsert as $detail) {
                    PesananDetail::create([
                        'pesanan_id' => $pesanan->id,
                        'produk_id' => $detail['produk']->id,
                        'nama_produk' => $detail['produk']->nama,
                        'harga_saat_beli' => $detail['harga_saat_beli'],
                        'jumlah' => $detail['jumlah'],
                        'subtotal' => $detail['subtotal'],
                        'perlu_resep' => $detail['perlu_resep'],
                    ]);

                    // Kurangi stok produk
                    $detail['produk']->decrement('stok', $detail['jumlah']);
                }

                // Kosongkan keranjang di sisi server
                Keranjang::where('pelanggan_id', $this->pelangganId($request))->delete();

                // Catat kunci idempoten
                KunciIdempoten::create([
                    'kunci' => $idempotencyKey,
                    'pesanan_id' => $pesanan->id,
                ]);

                return $pesanan;
            });

            // Jika metode pembayaran Xendit, generate invoice
            if ($pesananBaru->metode_pembayaran === 'xendit') {
                $pesananBaru->load('details');
                $invoice = $this->xenditService->createInvoice($pesananBaru);
                if ($invoice) {
                    $pesananBaru->update([
                        'xendit_invoice_id' => $invoice['invoice_id'],
                        'xendit_payment_url' => $invoice['invoice_url'],
                        'xendit_status' => $invoice['status'],
                    ]);
                }
            }

            $pesananBaru->load(['details', 'kurir']);

            return $this->sukses($pesananBaru, 'Pesanan berhasil dibuat', 201);

        } catch (\InvalidArgumentException $e) {
            return $this->gagal($e->getMessage(), 422, ['nomor_resep' => [$e->getMessage()]]);
        } catch (\DomainException $e) {
            return $this->gagal($e->getMessage(), 409);
        } catch (QueryException $e) {
            if ($this->adalahDuplikatKunciIdempoten($e)) {
                $pesananExisting = $this->pesananBerdasarkanKunci($idempotencyKey);

                if ($pesananExisting) {
                    return $this->sukses($pesananExisting, 'Pesanan telah diproses sebelumnya (Idempoten)', 201);
                }
            }

            Log::error('Checkout gagal: ' . $e->getMessage(), ['exception' => $e]);
            return $this->gagal('Terjadi kesalahan pada server saat memproses checkout', 500);
        } catch (\Throwable $e) {
            Log::error('Checkout gagal: ' . $e->getMessage(), ['exception' => $e]);
            return $this->gagal('Terjadi kesalahan pada server saat memproses checkout', 500);
        }
    }

    private function pesananBerdasarkanKunci(string $kunci): ?Pesanan
    {
        $kunciIdempoten = KunciIdempoten::where('kunci', $kunci)->first();

        if (! $kunciIdempoten) {
            return null;
        }

        return Pesanan::with(['details', 'kurir'])->find($kunciIdempoten->pesanan_id);
    }

    private function adalahDuplikatKunciIdempoten(QueryException $e): bool
    {
        return (string) $e->getCode() === '23000'
            && str_contains(strtolower($e->getMessage()), 'kunci');
    }

    /**
     * GET /api/rajaongkir/provinsi
     */
    public function getRajaongkirProvinces(): JsonResponse
    {
        $provinces = $this->rajaOngkirService->getProvinces();
        return $this->sukses($provinces, 'Daftar provinsi berhasil diambil', 200);
    }

    /**
     * GET /api/rajaongkir/kota/{provinsi_id}
     */
    public function getRajaongkirCitiesByProvince(string $provinsiId): JsonResponse
    {
        $cities = $this->rajaOngkirService->getCitiesByProvince((int) $provinsiId);
        return $this->sukses($cities, 'Daftar kota berhasil diambil', 200);
    }

    /**
     * GET /api/rajaongkir/kecamatan/{kota_id}
     */
    public function getRajaongkirDistrictsByCity(string $kotaId): JsonResponse
    {
        $districts = $this->rajaOngkirService->getDistrictsByCity((int) $kotaId);
        return $this->sukses($districts, 'Daftar kecamatan berhasil diambil', 200);
    }

    /**
     * GET /api/rajaongkir/desa/{kecamatan_id}
     */
    public function getRajaongkirVillagesByDistrict(string $kecamatanId): JsonResponse
    {
        $villages = $this->rajaOngkirService->getVillagesByDistrict((int) $kecamatanId);
        return $this->sukses($villages, 'Daftar desa berhasil diambil', 200);
    }

    private function cariTarifRajaOngkir(array $hasil, string $service): ?int
    {
        $serviceUpper = strtoupper(trim($service));
        $serviceClean = trim(preg_replace('/^(jne|pos|tiki)\s+/i', '', $serviceUpper));

        foreach ($hasil as $kurir) {
            foreach (($kurir['costs'] ?? []) as $opsi) {
                $opsiService = strtoupper(trim((string) ($opsi['service'] ?? '')));
                if ($opsiService === $serviceUpper || $opsiService === $serviceClean) {
                    $nilai = $opsi['cost'][0]['value'] ?? null;

                    if (is_numeric($nilai)) {
                        return (int) $nilai;
                    }
                }
            }
        }

        return null;
    }

    /**
     * GET /api/pesanan
     * Riwayat pesanan diurutkan dari yang terbaru (PRD 7.1)
     */
    public function index(Request $request): JsonResponse
    {
        $pesanan = Pesanan::with(['details', 'kurir'])
            ->where('pelanggan_id', $this->pelangganId($request))
            ->orderBy('id', 'desc')
            ->get();

        return $this->sukses($pesanan, 'Riwayat pesanan berhasil diambil', 200);
    }

    /**
     * GET /api/pesanan/{id}
     * Rincian pesanan beserta itemnya (memuat harga saat pembelian) (PRD 7.1)
     */
    public function show(string|int $id): JsonResponse
    {
        $pesanan = Pesanan::with(['details', 'kurir'])->find($id);

        if (!$pesanan) {
            return $this->gagal('Pesanan tidak ditemukan', 404);
        }

        return $this->sukses($pesanan, 'Rincian pesanan berhasil diambil', 200);
    }

    /**
     * GET /api/pesanan/{id}/xendit/status
     * Sinkronisasi status invoice Xendit secara server-to-server.
     * Dipakai karena webhook Xendit tidak dapat menjangkau server lokal/LAN:
     * alih-alih menunggu callback, backend yang menanyakan status invoice
     * langsung ke API Xendit lalu memperbarui status pesanan.
     */
    public function checkXenditStatus(string|int $id): JsonResponse
    {
        $pesanan = Pesanan::with(['details', 'kurir'])->find($id);

        if (!$pesanan) {
            return $this->gagal('Pesanan tidak ditemukan', 404);
        }

        $invoiceId = (string) $pesanan->xendit_invoice_id;
        $invoiceSimulasi = str_starts_with($invoiceId, 'INV-SIM-');

        // Sinkron hanya untuk invoice asli Xendit yang masih menunggu pembayaran
        if (
            $pesanan->metode_pembayaran === 'xendit'
            && $invoiceId !== ''
            && ! $invoiceSimulasi
            && $pesanan->status === 'menunggu_pembayaran'
        ) {
            $invoice = $this->xenditService->getInvoice($invoiceId);

            if ($invoice !== null) {
                $statusInvoice = strtoupper((string) ($invoice['status'] ?? ''));

                if ($statusInvoice !== '' && $statusInvoice !== strtoupper((string) $pesanan->xendit_status)) {
                    $pesanan->xendit_status = $statusInvoice;
                    $pesanan->save();
                }

                $statusTarget = match ($statusInvoice) {
                    'PAID', 'SETTLED' => 'dibayar',
                    'EXPIRED' => 'dibatalkan',
                    default => null,
                };

                if (
                    $statusTarget !== null
                    && $this->statusService->bolehTransisi($pesanan->status, $statusTarget)
                ) {
                    try {
                        $pesanan = $this->statusService->ubahStatus($pesanan, $statusTarget);
                    } catch (\DomainException $e) {
                        Log::warning('Sinkronisasi Xendit tidak mengubah status: ' . $e->getMessage());
                    }
                }
            }
        }

        return $this->sukses($pesanan->fresh(['details', 'kurir']), 'Status pembayaran terkini', 200);
    }

    /**
     * PATCH /api/pesanan/{id}/status
     * Mengubah status pesanan. Hanya menerima perpindahan status yang sah (PRD Bab 8)
     * Transisi: menunggu_pembayaran -> menunggu_konfirmasi -> dibayar -> diproses -> dikirim -> selesai
     * Dibatalkan: hanya dari menunggu_pembayaran atau menunggu_konfirmasi
     * Perpindahan tidak sah wajib ditolak server dengan kode 409
     */
    public function updateStatus(Request $request, string|int $id): JsonResponse
    {
        $pesanan = Pesanan::find($id);

        if (!$pesanan) {
            return $this->gagal('Pesanan tidak ditemukan', 404);
        }

        $validator = Validator::make($request->all(), [
            'status' => 'required|string|in:menunggu_pembayaran,menunggu_konfirmasi,dibayar,diproses,dikirim,selesai,dibatalkan',
        ], [
            'status.required' => 'Status pesanan wajib diisi',
            'status.in' => 'Status pesanan tidak valid',
        ]);

        if ($validator->fails()) {
            return $this->gagal('Validasi status gagal', 422, $validator->errors()->toArray());
        }

        try {
            $pesanan = $this->statusService->ubahStatus($pesanan, $request->status);
        } catch (\DomainException $e) {
            return $this->gagal($e->getMessage(), 409);
        }

        return $this->sukses($pesanan, 'Status pesanan berhasil diperbarui', 200);
    }

    /**
     * Webhook Xendit / Mock Callback
     * POST /api/xendit/callback
     */
    public function xenditCallback(Request $request): JsonResponse
    {
        $callbackToken = (string) config('services.xendit.callback_token');

        if ($callbackToken === '') {
            return response()->json([
                'status' => 'error',
                'message' => 'Token callback Xendit belum dikonfigurasi',
            ], 503);
        }

        if (! hash_equals($callbackToken, (string) $request->header('x-callback-token'))) {
            return response()->json(['status' => 'error', 'message' => 'Token callback Xendit tidak valid'], 401);
        }

        $externalId = (string) $request->input('external_id', '');
        $status = strtoupper((string) $request->input('status', ''));

        if ($externalId === '' || $status === '') {
            return response()->json([
                'status' => 'error',
                'message' => 'external_id dan status wajib dikirim',
            ], 422);
        }

        $pesanan = Pesanan::where('nomor_pesanan', $externalId)->first();

        if (! $pesanan) {
            return response()->json(['status' => 'ok', 'message' => 'Pesanan tidak ditemukan, callback diabaikan']);
        }

        $pesanan->xendit_status = $status;
        $pesanan->save();

        $statusTarget = match ($status) {
            'PAID' => 'dibayar',
            'EXPIRED' => 'dibatalkan',
            default => null,
        };

        if ($statusTarget !== null && $this->statusService->bolehTransisi($pesanan->status, $statusTarget)) {
            try {
                $this->statusService->ubahStatus($pesanan, $statusTarget);
            } catch (\DomainException $e) {
                Log::warning('Callback Xendit tidak mengubah status: ' . $e->getMessage());
            }
        }

        return response()->json(['status' => 'ok']);
    }

    /**
     * GET /api/rajaongkir/kota
     * Fitur unggulan RajaOngkir Kota
     */
    public function getRajaongkirCities(): JsonResponse
    {
        $cities = $this->rajaOngkirService->getCities();
        return $this->sukses($cities, 'Daftar kota RajaOngkir berhasil diambil', 200);
    }

    /**
     * POST /api/rajaongkir/ongkir
     * Fitur unggulan RajaOngkir Hitung Ongkir
     */
    public function checkRajaongkirCost(Request $request): JsonResponse
    {
        $destination = $request->input('destination', '151');
        $weight = (int) $request->input('weight', 1000);
        $courier = $request->input('courier', 'jne');

        $costs = $this->rajaOngkirService->calculateCost($destination, $weight, $courier);
        return $this->sukses($costs, 'Tarif RajaOngkir berhasil dihitung', 200);
    }
}
