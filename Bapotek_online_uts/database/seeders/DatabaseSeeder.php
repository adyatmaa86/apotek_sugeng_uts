<?php

namespace Database\Seeders;

use App\Models\Kurir;
use App\Models\Pesanan;
use App\Models\PesananDetail;
use App\Models\Produk;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     * Sesuai ketentuan PRD Bab 14 (Ukuran Minimum Data Seeder):
     * - Minimal 2 kategori produk
     * - Minimal 12 produk tersebar (Obat dan Alat Kesehatan)
     * - Minimal 2 produk berstok nol / tidak tersedia
     * - Minimal 3 kurir / wilayah antar dengan tarif berbeda
     * - Minimal 2 metode pembayaran simulasi
     * - Minimal 3 pesanan contoh dengan status berbeda
     */
    public function run(): void
    {
        $this->call(AdminUserSeeder::class);

        if (Kurir::query()->exists() || Produk::query()->exists() || Pesanan::query()->exists()) {
            $this->command?->info('Seeder dilewati: data master atau pesanan sudah tersedia.');
            return;
        }

        // 1. KURIR & WILAYAH ANTAR (Internal Apotek)
        $kurir1 = Kurir::create([
            'nama' => 'Kurir Cepat Apotek (Dalam Kota)',
            'wilayah' => 'Radius <= 5 KM (Yogyakarta Pusat)',
            'tarif' => 8000,
            'estimasi' => '30 - 60 Menit',
        ]);

        $kurir2 = Kurir::create([
            'nama' => 'Kurir Standar Apotek (Sleman & Bantul)',
            'wilayah' => 'Radius 5 - 15 KM (Sleman/Bantul)',
            'tarif' => 15000,
            'estimasi' => '1 - 2 Jam',
        ]);

        $kurir3 = Kurir::create([
            'nama' => 'Ekspedisi Pendingin Obat (Khusus Termolabil)',
            'wilayah' => 'Antar Kota (DIY & Sekitarnya)',
            'tarif' => 25000,
            'estimasi' => 'Same Day (Hari yang Sama)',
        ]);

        // 2. PRODUK OBAT & ALAT KESEHATAN (Total 14 produk)
        // Kategori 1: Obat
        $p1 = Produk::create([
            'nama' => 'Paracetamol 500mg Strip',
            'harga' => 7500,
            'kategori' => 'Obat',
            'stok' => 100,
            'tersedia' => true,
            'deskripsi' => 'Meredakan demam dan nyeri ringan seperti sakit kepala dan sakit gigi.',
            'perlu_resep' => false,
            'batas_per_pembelian' => 10,
            'satuan' => 'Strip (10 Tablet)',
            'golongan' => 'Obat Bebas',
        ]);

        $p2 = Produk::create([
            'nama' => 'Amoxicillin 500mg Kapsul',
            'harga' => 18000,
            'kategori' => 'Obat',
            'stok' => 50,
            'tersedia' => true,
            'deskripsi' => 'Antibiotik untuk infeksi saluran pernapasan, saluran kemih, dan kulit. Wajib resep dokter.',
            'perlu_resep' => true,
            'batas_per_pembelian' => 3,
            'satuan' => 'Strip (10 Kapsul)',
            'golongan' => 'Obat Keras',
        ]);

        $p3 = Produk::create([
            'nama' => 'OBH Sirup Obat Batuk 100ml',
            'harga' => 23000,
            'kategori' => 'Obat',
            'stok' => 35,
            'tersedia' => true,
            'deskripsi' => 'Obat batuk hitam untuk meredakan batuk berdahak dan melegakan tenggorokan.',
            'perlu_resep' => false,
            'batas_per_pembelian' => 5,
            'satuan' => 'Botol (100ml)',
            'golongan' => 'Obat Bebas Terbatas',
        ]);

        $p4 = Produk::create([
            'nama' => 'Cefixime 100mg Kapsul',
            'harga' => 35000,
            'kategori' => 'Obat',
            'stok' => 20,
            'tersedia' => true,
            'deskripsi' => 'Antibiotik sefalosporin generasi ketiga untuk infeksi bakteri berat. Wajib resep dokter.',
            'perlu_resep' => true,
            'batas_per_pembelian' => 2,
            'satuan' => 'Strip (10 Kapsul)',
            'golongan' => 'Obat Keras',
        ]);

        $p5 = Produk::create([
            'nama' => 'Vitamin C 500mg IPI Botol',
            'harga' => 12000,
            'kategori' => 'Obat',
            'stok' => 80,
            'tersedia' => true,
            'deskripsi' => 'Suplemen vitamin C untuk menjaga daya tahan tubuh dan masa penyembuhan.',
            'perlu_resep' => false,
            'batas_per_pembelian' => 10,
            'satuan' => 'Botol (45 Tablet)',
            'golongan' => 'Suplemen Makanan',
        ]);

        $p6 = Produk::create([
            'nama' => 'Antasida Doen Tablet Kunyah',
            'harga' => 6000,
            'kategori' => 'Obat',
            'stok' => 60,
            'tersedia' => true,
            'deskripsi' => 'Mengurangi gejala mual, perih lambung, dan kembung akibat asam lambung berlebih.',
            'perlu_resep' => false,
            'batas_per_pembelian' => 8,
            'satuan' => 'Strip (10 Tablet)',
            'golongan' => 'Obat Bebas',
        ]);

        // Produk Habis / Stok Nol (Obat 1)
        $p7Habis = Produk::create([
            'nama' => 'Metformin 500mg (Habis/Uji Galat)',
            'harga' => 14000,
            'kategori' => 'Obat',
            'stok' => 0,
            'tersedia' => false,
            'deskripsi' => 'Obat antidiabetes untuk mengontrol kadar gula darah. [Stok Sengaja Dikosongkan]',
            'perlu_resep' => true,
            'batas_per_pembelian' => 3,
            'satuan' => 'Strip (10 Tablet)',
            'golongan' => 'Obat Keras',
        ]);

        // Kategori 2: Alat Kesehatan
        $p8 = Produk::create([
            'nama' => 'Tensimeter Digital Lengan Omron',
            'harga' => 450000,
            'kategori' => 'Alat Kesehatan',
            'stok' => 15,
            'tersedia' => true,
            'deskripsi' => 'Alat ukur tekanan darah digital akurat dengan layar LCD dan manset nyaman.',
            'perlu_resep' => false,
            'batas_per_pembelian' => 2,
            'satuan' => 'Unit (Box)',
            'golongan' => 'Alat Kesehatan Diagnostik',
        ]);

        $p9 = Produk::create([
            'nama' => 'Termometer Infrared Digital Dahi',
            'harga' => 125000,
            'kategori' => 'Alat Kesehatan',
            'stok' => 25,
            'tersedia' => true,
            'deskripsi' => 'Pengukur suhu tubuh non-kontak tanpa sentuh dengan akurasi tinggi dan cepat 1 detik.',
            'perlu_resep' => false,
            'batas_per_pembelian' => 3,
            'satuan' => 'Unit (Box)',
            'golongan' => 'Alat Kesehatan Diagnostik',
        ]);

        $p10 = Produk::create([
            'nama' => 'Pulse Oximeter Fingertip Spo2',
            'harga' => 85000,
            'kategori' => 'Alat Kesehatan',
            'stok' => 30,
            'tersedia' => true,
            'deskripsi' => 'Alat ukur kadar saturasi oksigen dalam darah dan detak nadi jari.',
            'perlu_resep' => false,
            'batas_per_pembelian' => 4,
            'satuan' => 'Pcs (Box)',
            'golongan' => 'Alat Kesehatan Diagnostik',
        ]);

        $p11 = Produk::create([
            'nama' => 'Masker Medis 3 Ply Bedah BFE 99%',
            'harga' => 28000,
            'kategori' => 'Alat Kesehatan',
            'stok' => 50,
            'tersedia' => true,
            'deskripsi' => 'Masker bedah 3 lapis pelindung pernapasan dari droplet, debu, dan bakteri.',
            'perlu_resep' => false,
            'batas_per_pembelian' => 10,
            'satuan' => 'Box (50 Pcs)',
            'golongan' => 'Alat Kesehatan Habis Pakai',
        ]);

        $p12 = Produk::create([
            'nama' => 'Alat Cek Gula Darah EasyTouch GCU',
            'harga' => 215000,
            'kategori' => 'Alat Kesehatan',
            'stok' => 12,
            'tersedia' => true,
            'deskripsi' => 'Alat tes 3-in-1 untuk memeriksa kadar Gula Darah, Kolesterol, dan Asam Urat.',
            'perlu_resep' => false,
            'batas_per_pembelian' => 2,
            'satuan' => 'Unit Kit',
            'golongan' => 'Alat Kesehatan Diagnostik',
        ]);

        $p13 = Produk::create([
            'nama' => 'Kasa Steril Onemed 16x16 Box',
            'harga' => 11000,
            'kategori' => 'Alat Kesehatan',
            'stok' => 40,
            'tersedia' => true,
            'deskripsi' => 'Kasa steril pembersih dan penutup luka luar agar tidak infeksi.',
            'perlu_resep' => false,
            'batas_per_pembelian' => 10,
            'satuan' => 'Box (16 Lembar)',
            'golongan' => 'Alat Kesehatan Habis Pakai',
        ]);

        // Produk Habis / Stok Nol (Alat Kesehatan 2)
        $p14Habis = Produk::create([
            'nama' => 'Tabung Oksigen Portable 500cc (Habis/Uji Galat)',
            'harga' => 65000,
            'kategori' => 'Alat Kesehatan',
            'stok' => 0,
            'tersedia' => false,
            'deskripsi' => 'Tabung oksigen murni praktis saat sesak napas darurat. [Stok Sengaja Dikosongkan]',
            'perlu_resep' => false,
            'batas_per_pembelian' => 2,
            'satuan' => 'Kaleng (500cc)',
            'golongan' => 'Alat Kesehatan Habis Pakai',
        ]);

        // 3. TIGA CONTOH PESANAN AWAL (Status Berbeda: menunggu_pembayaran, dibayar, selesai)
        // Pesanan 1: menunggu_pembayaran (COD)
        $pesanan1 = Pesanan::create([
            'nomor_pesanan' => 'APT-20261104-1001',
            'pelanggan_id' => 'pelanggan_uts_01',
            'nama_penerima' => 'Ceo Adyatma86',
            'alamat' => 'Jl. Kaliurang KM 9, Sleman, DI Yogyakarta',
            'kurir_id' => $kurir1->id,
            'ongkos_kirim' => 8000,
            'subtotal' => 15000,
            'total' => 23000,
            'metode_pembayaran' => 'cod',
            'status' => 'menunggu_pembayaran',
            'nomor_resep' => null,
        ]);
        PesananDetail::create([
            'pesanan_id' => $pesanan1->id,
            'produk_id' => $p1->id,
            'nama_produk' => $p1->nama,
            'harga_saat_beli' => $p1->harga,
            'jumlah' => 2,
            'subtotal' => 15000,
            'perlu_resep' => false,
        ]);

        // Pesanan 2: dibayar (Transfer Manual) - ada resep dokter
        $pesanan2 = Pesanan::create([
            'nomor_pesanan' => 'APT-20261104-1002',
            'pelanggan_id' => 'pelanggan_uts_01',
            'nama_penerima' => 'Ceo Adyatma86',
            'alamat' => 'Jl. Gejayan No. 45, Gondokusuman, Yogyakarta',
            'kurir_id' => $kurir2->id,
            'ongkos_kirim' => 15000,
            'subtotal' => 36000,
            'total' => 51000,
            'metode_pembayaran' => 'transfer_manual',
            'status' => 'dibayar',
            'nomor_resep' => 'RSP-DR-BUDI-2026-889',
        ]);
        PesananDetail::create([
            'pesanan_id' => $pesanan2->id,
            'produk_id' => $p2->id,
            'nama_produk' => $p2->nama,
            'harga_saat_beli' => $p2->harga,
            'jumlah' => 2,
            'subtotal' => 36000,
            'perlu_resep' => true,
        ]);

        // Pesanan 3: selesai (Xendit)
        $pesanan3 = Pesanan::create([
            'nomor_pesanan' => 'APT-20261104-1003',
            'pelanggan_id' => 'pelanggan_uts_01',
            'nama_penerima' => 'Ceo Adyatma86',
            'alamat' => 'Jl. Malioboro No. 12, Kota Yogyakarta',
            'kurir_id' => $kurir1->id,
            'ongkos_kirim' => 8000,
            'subtotal' => 450000,
            'total' => 458000,
            'metode_pembayaran' => 'xendit',
            'status' => 'selesai',
            'nomor_resep' => null,
            'xendit_invoice_id' => 'INV-XND-0012984',
            'xendit_payment_url' => 'https://checkout.xendit.co/web/APT-20261104-1003',
            'xendit_status' => 'PAID',
        ]);
        PesananDetail::create([
            'pesanan_id' => $pesanan3->id,
            'produk_id' => $p8->id,
            'nama_produk' => $p8->nama,
            'harga_saat_beli' => $p8->harga,
            'jumlah' => 1,
            'subtotal' => 450000,
            'perlu_resep' => false,
        ]);
    }
}
