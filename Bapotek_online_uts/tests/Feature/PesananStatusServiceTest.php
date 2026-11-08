<?php

namespace Tests\Feature;

use App\Models\Kurir;
use App\Models\Pesanan;
use App\Models\PesananDetail;
use App\Models\Produk;
use App\Services\PesananStatusService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PesananStatusServiceTest extends TestCase
{
    use RefreshDatabase;

    public function test_pembatalan_mengembalikan_stok_produk(): void
    {
        $produk = Produk::create([
            'nama' => 'Paracetamol',
            'harga' => 5000,
            'kategori' => 'Obat',
            'stok' => 8,
            'tersedia' => true,
            'perlu_resep' => false,
            'batas_per_pembelian' => 10,
            'satuan' => 'Strip',
        ]);

        $kurir = Kurir::create([
            'nama' => 'Kurir Test',
            'wilayah' => 'Kota',
            'tarif' => 8000,
            'estimasi' => '1 jam',
        ]);

        $pesanan = Pesanan::create([
            'nomor_pesanan' => 'APT-TEST-001',
            'pelanggan_id' => 'pelanggan_uts_01',
            'nama_penerima' => 'Test',
            'alamat' => 'Test',
            'kurir_id' => $kurir->id,
            'ongkos_kirim' => 8000,
            'subtotal' => 10000,
            'total' => 18000,
            'metode_pembayaran' => 'cod',
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

        $hasil = app(PesananStatusService::class)->ubahStatus($pesanan, 'dibatalkan');

        $this->assertSame('dibatalkan', $hasil->status);
        $this->assertSame(10, $produk->fresh()->stok);
    }

    public function test_transisi_tidak_sah_ditolak(): void
    {
        $pesanan = Pesanan::create([
            'nomor_pesanan' => 'APT-TEST-002',
            'pelanggan_id' => 'pelanggan_uts_01',
            'nama_penerima' => 'Test',
            'alamat' => 'Test',
            'ongkos_kirim' => 0,
            'subtotal' => 5000,
            'total' => 5000,
            'metode_pembayaran' => 'cod',
            'status' => 'selesai',
        ]);

        $this->expectException(\DomainException::class);

        app(PesananStatusService::class)->ubahStatus($pesanan, 'menunggu_pembayaran');
    }
}
