<?php

namespace Tests\Feature;

use App\Models\Keranjang;
use App\Models\Kurir;
use App\Models\Pesanan;
use App\Models\PesananDetail;
use App\Models\Produk;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CheckoutTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Buat pembeli terautentikasi agar identitas pelanggan pada request
     * (user_{id}) sama dengan pelanggan_id baris keranjang/pesanan.
     */
    private function pembeliAktif(): User
    {
        $pengguna = User::factory()->create();

        Sanctum::actingAs($pengguna);

        return $pengguna;
    }

    private function buatProduk(int $stok = 10): Produk
    {
        return Produk::create([
            'nama' => 'Paracetamol',
            'harga' => 5000,
            'kategori' => 'Obat',
            'stok' => $stok,
            'tersedia' => true,
            'perlu_resep' => false,
            'batas_per_pembelian' => 10,
            'satuan' => 'Strip',
        ]);
    }

    private function buatKurir(): Kurir
    {
        return Kurir::create([
            'nama' => 'Kurir Test',
            'wilayah' => 'Kota',
            'tarif' => 8000,
            'estimasi' => '1 jam',
        ]);
    }

    private function isiKeranjang(User $pelanggan, Produk $produk, int $jumlah = 1): void
    {
        Keranjang::create([
            'pelanggan_id' => 'user_' . $pelanggan->id,
            'produk_id' => $produk->id,
            'jumlah' => $jumlah,
        ]);
    }

    public function test_checkout_menghitung_ongkir_di_server_dan_idempoten(): void
    {
        $pelanggan = $this->pembeliAktif();
        $produk = $this->buatProduk();
        $kurir = $this->buatKurir();
        $this->isiKeranjang($pelanggan, $produk);

        $body = [
            'nama_penerima' => 'Test',
            'alamat' => 'Yogyakarta',
            'kurir_id' => $kurir->id,
            'metode_pembayaran' => 'cod',
            'ongkos_kirim_override' => 0,
        ];

        $response = $this->postJson('/api/checkout', $body, [
            'X-Kunci-Idempoten' => 'kunci-test-001',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.ongkos_kirim', 8000)
            ->assertJsonPath('data.total', 13000);

        $this->assertSame(9, $produk->fresh()->stok);
        $this->assertSame(0, Keranjang::count());

        $pemanggilanKedua = $this->postJson('/api/checkout', $body, [
            'X-Kunci-Idempoten' => 'kunci-test-001',
        ]);

        $pemanggilanKedua->assertStatus(201)
            ->assertJsonPath('data.nomor_pesanan', $response->json('data.nomor_pesanan'));

        $this->assertSame(9, $produk->fresh()->stok);
        $this->assertSame(1, Pesanan::count());
    }

    public function test_checkout_rajaongkir_menghitung_tarif_di_server(): void
    {
        config(['services.rajaongkir.api_key' => 'kunci-uji']);

        // Layanan luar (Komerce) dipalsukan agar tes tidak bergantung jaringan.
        Http::fake([
            'https://rajaongkir.komerce.id/api/v1/destination/district/*' => Http::response([
                'data' => [['id' => 1234, 'name' => 'Tegalrejo']],
            ]),
            'https://rajaongkir.komerce.id/api/v1/calculate/domestic-cost' => Http::response([
                'data' => [[
                    'service' => 'REG',
                    'description' => 'Reguler',
                    'cost' => 18000,
                    'etd' => '2-3 days',
                ]],
            ]),
        ]);

        $pelanggan = $this->pembeliAktif();
        $produk = $this->buatProduk();
        $this->isiKeranjang($pelanggan, $produk);

        $response = $this->postJson('/api/checkout', [
            'nama_penerima' => 'Test',
            'alamat' => 'Yogyakarta',
            'metode_pembayaran' => 'cod',
            'rajaongkir_destination' => '151',
            'rajaongkir_courier' => 'jne',
            'rajaongkir_service' => 'REG',
        ], [
            'X-Kunci-Idempoten' => 'kunci-test-002',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.ongkos_kirim', 18000)
            ->assertJsonPath('data.rajaongkir_service', 'RajaOngkir JNE - REG');
    }

    public function test_checkout_tanpa_pilihan_pengiriman_ditolak(): void
    {
        $pelanggan = $this->pembeliAktif();
        $produk = $this->buatProduk();
        $this->isiKeranjang($pelanggan, $produk);

        $response = $this->postJson('/api/checkout', [
            'nama_penerima' => 'Test',
            'alamat' => 'Yogyakarta',
            'metode_pembayaran' => 'cod',
        ], [
            'X-Kunci-Idempoten' => 'kunci-test-003',
        ]);

        $response->assertStatus(422);
    }

    public function test_callback_expired_membatalkan_dan_mengembalikan_stok_sekali(): void
    {
        config(['services.xendit.callback_token' => 'token-test']);

        $produk = $this->buatProduk(8);
        $pesanan = Pesanan::create([
            'nomor_pesanan' => 'APT-TEST-XENDIT-001',
            'pelanggan_id' => 'pelanggan_uts_01',
            'nama_penerima' => 'Test',
            'alamat' => 'Yogyakarta',
            'ongkos_kirim' => 0,
            'subtotal' => 10000,
            'total' => 10000,
            'metode_pembayaran' => 'xendit',
            'status' => 'menunggu_pembayaran',
        ]);

        PesananDetail::create([
            'pesanan_id' => $pesanan->id,
            'produk_id' => $produk->id,
            'nama_produk' => $produk->nama,
            'harga_saat_beli' => 5000,
            'jumlah' => 2,
            'subtotal' => 10000,
            'perlu_resep' => false,
        ]);

        $headers = ['x-callback-token' => 'token-test'];
        $payload = ['external_id' => $pesanan->nomor_pesanan, 'status' => 'EXPIRED'];

        $this->postJson('/api/xendit/callback', $payload, $headers)->assertOk();
        $this->assertSame('dibatalkan', $pesanan->fresh()->status);
        $this->assertSame(10, $produk->fresh()->stok);

        $this->postJson('/api/xendit/callback', $payload, $headers)->assertOk();
        $this->assertSame(10, $produk->fresh()->stok);
    }

    public function test_callback_paid_tidak_menurunkan_status_selesai(): void
    {
        config(['services.xendit.callback_token' => 'token-test']);

        $pesanan = Pesanan::create([
            'nomor_pesanan' => 'APT-TEST-XENDIT-002',
            'pelanggan_id' => 'pelanggan_uts_01',
            'nama_penerima' => 'Test',
            'alamat' => 'Yogyakarta',
            'ongkos_kirim' => 0,
            'subtotal' => 5000,
            'total' => 5000,
            'metode_pembayaran' => 'xendit',
            'status' => 'selesai',
        ]);

        $this->postJson('/api/xendit/callback', [
            'external_id' => $pesanan->nomor_pesanan,
            'status' => 'PAID',
        ], ['x-callback-token' => 'token-test'])->assertOk();

        $this->assertSame('selesai', $pesanan->fresh()->status);
        $this->assertSame('PAID', $pesanan->fresh()->xendit_status);
    }

    public function test_callback_dengan_token_salah_ditolak(): void
    {
        config(['services.xendit.callback_token' => 'token-test']);

        $this->postJson('/api/xendit/callback', [
            'external_id' => 'APT-TEST-XENDIT-003',
            'status' => 'PAID',
        ], ['x-callback-token' => 'token-salah'])->assertStatus(401);
    }
}
