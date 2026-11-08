<?php

namespace App\Http\Controllers\Api;

use App\Models\Keranjang;
use App\Models\Produk;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class KeranjangController extends BaseApiController
{
    /**
     * GET /api/keranjang
     * Isi keranjang beserta subtotal (Subtotal dihitung server, bukan Flutter)
     */
    public function index(Request $request): JsonResponse
    {
        $items = Keranjang::with('produk')
            ->where('pelanggan_id', $this->pelangganId($request))
            ->get();

        $subtotal = 0;
        $formattedItems = [];

        foreach ($items as $item) {
            $itemSubtotal = $item->jumlah * ($item->produk ? $item->produk->harga : 0);
            $subtotal += $itemSubtotal;

            $formattedItems[] = [
                'id' => $item->id,
                'pelanggan_id' => $item->pelanggan_id,
                'produk_id' => $item->produk_id,
                'jumlah' => $item->jumlah,
                'subtotal_item' => $itemSubtotal,
                'produk' => $item->produk,
            ];
        }

        return $this->sukses([
            'items' => $formattedItems,
            'total_item' => count($formattedItems),
            'subtotal' => $subtotal,
        ], 'Isi keranjang berhasil diambil', 200);
    }

    /**
     * POST /api/keranjang
     * Menambah item ke keranjang. Menerima produk_id dan jumlah; 409 bila stok tidak cukup / limit dilanggar
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'produk_id' => 'required|exists:produks,id',
            'jumlah' => 'required|integer|min:1',
        ], [
            'produk_id.required' => 'Produk ID wajib dikirim',
            'produk_id.exists' => 'Produk tidak ditemukan',
            'jumlah.required' => 'Jumlah produk wajib diisi',
            'jumlah.min' => 'Jumlah harus lebih besar dari nol',
        ]);

        if ($validator->fails()) {
            return $this->gagal('Validasi gagal', 422, $validator->errors()->toArray());
        }

        $produk = Produk::find($request->produk_id);

        if (!$produk->tersedia || $produk->stok <= 0) {
            return $this->gagal("Produk '{$produk->nama}' saat ini sedang habis atau tidak tersedia", 409);
        }

        $keranjang = Keranjang::where('pelanggan_id', $this->pelangganId($request))
            ->where('produk_id', $produk->id)
            ->first();

        $jumlahSekarang = $keranjang ? $keranjang->jumlah : 0;
        $totalJumlah = $jumlahSekarang + $request->jumlah;

        if ($totalJumlah > $produk->stok) {
            return $this->gagal("Stok produk tidak mencukupi. Tersedia: {$produk->stok}", 409);
        }

        if ($totalJumlah > $produk->batas_per_pembelian) {
            return $this->gagal("Pembelian melebihi batas maksimum untuk produk ini ({$produk->batas_per_pembelian} item)", 409);
        }

        if ($keranjang) {
            $keranjang->jumlah = $totalJumlah;
            $keranjang->save();
        } else {
            $keranjang = Keranjang::create([
                'pelanggan_id' => $this->pelangganId($request),
                'produk_id' => $produk->id,
                'jumlah' => $request->jumlah,
            ]);
        }

        return $this->sukses($keranjang->load('produk'), 'Produk berhasil ditambahkan ke keranjang', 200);
    }

    /**
     * PUT /api/keranjang/{id}
     * Mengubah jumlah item. Jumlah nol atau negatif ditolak dengan 422. Melebihi stok/batas ditolak 409.
     */
    public function update(Request $request, string|int $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'jumlah' => 'required|integer',
        ], [
            'jumlah.required' => 'Jumlah wajib diisi',
        ]);

        if ($validator->fails()) {
            return $this->gagal('Validasi gagal', 422, $validator->errors()->toArray());
        }

        if ($request->jumlah <= 0) {
            return $this->gagal('Jumlah harus lebih besar dari nol', 422, [
                'jumlah' => ['Jumlah harus lebih besar dari nol']
            ]);
        }

        $keranjang = Keranjang::with('produk')->find($id);

        if (!$keranjang || $keranjang->pelanggan_id !== $this->pelangganId($request)) {
            return $this->gagal('Item keranjang tidak ditemukan', 404);
        }

        $produk = $keranjang->produk;

        if ($request->jumlah > $produk->stok) {
            return $this->gagal("Stok produk tidak mencukupi. Tersedia: {$produk->stok}", 409);
        }

        if ($request->jumlah > $produk->batas_per_pembelian) {
            return $this->gagal("Pembelian melebihi batas maksimum ({$produk->batas_per_pembelian} item)", 409);
        }

        $keranjang->jumlah = $request->jumlah;
        $keranjang->save();

        return $this->sukses($keranjang, 'Jumlah item berhasil diperbarui', 200);
    }

    /**
     * DELETE /api/keranjang/{id}
     * Menghapus satu item keranjang.
     */
    public function destroy(Request $request, string|int $id): JsonResponse
    {
        $keranjang = Keranjang::find($id);

        if (!$keranjang || $keranjang->pelanggan_id !== $this->pelangganId($request)) {
            return $this->gagal('Item keranjang tidak ditemukan', 404);
        }

        $keranjang->delete();

        return $this->sukses(null, 'Item berhasil dihapus dari keranjang', 200);
    }
}
