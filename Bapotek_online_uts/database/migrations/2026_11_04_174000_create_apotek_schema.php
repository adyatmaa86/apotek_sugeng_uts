<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Tabel Produk
        Schema::create('produks', function (Blueprint $table) {
            $table->id();
            $table->string('nama');
            $table->unsignedBigInteger('harga'); // Rupiah bulat
            $table->string('kategori'); // e.g. Obat, Alat Kesehatan
            $table->integer('stok')->default(0);
            $table->boolean('tersedia')->default(true);
            $table->text('deskripsi')->nullable();
            $table->string('foto')->nullable();
            // Kolom khas domain Apotek & Alkes
            $table->boolean('perlu_resep')->default(false);
            $table->integer('batas_per_pembelian')->default(10);
            $table->string('satuan')->default('Pcs'); // opsional: Strip, Botol, Box, Pcs
            $table->string('golongan')->nullable(); // e.g. Bebas, Bebas Terbatas, Keras
            $table->timestamps();
        });

        // 2. Tabel Kurir / Wilayah Antar (Internal PRD)
        Schema::create('kurirs', function (Blueprint $table) {
            $table->id();
            $table->string('nama'); // e.g. Kurir Internal Apotek, JNE Kilat Internal
            $table->string('wilayah'); // e.g. Dalam Kota (Radius 5km), Antar Kota
            $table->unsignedBigInteger('tarif');
            $table->string('estimasi')->default('1-2 jam');
            $table->timestamps();
        });

        // 3. Tabel Keranjang
        Schema::create('keranjangs', function (Blueprint $table) {
            $table->id();
            $table->string('pelanggan_id')->default('pelanggan_uts_01');
            $table->foreignId('produk_id')->constrained('produks')->cascadeOnDelete();
            $table->integer('jumlah')->default(1);
            $table->timestamps();
        });

        // 4. Tabel Pesanan
        Schema::create('pesanans', function (Blueprint $table) {
            $table->id();
            $table->string('nomor_pesanan')->unique();
            $table->string('pelanggan_id')->default('pelanggan_uts_01');
            $table->string('nama_penerima');
            $table->text('alamat');
            $table->foreignId('kurir_id')->nullable()->constrained('kurirs')->nullOnDelete();
            $table->unsignedBigInteger('ongkos_kirim')->default(0);
            $table->unsignedBigInteger('subtotal');
            $table->unsignedBigInteger('total');
            $table->string('metode_pembayaran'); // cod, transfer_manual, xendit
            $table->string('status')->default('menunggu_pembayaran'); 
            // menunggu_pembayaran -> menunggu_konfirmasi -> dibayar -> diproses -> dikirim -> selesai (atau dibatalkan)
            $table->string('nomor_resep')->nullable(); // wajib jika ada item perlu_resep
            // Kolom integrasi RajaOngkir & Xendit
            $table->string('rajaongkir_service')->nullable();
            $table->string('xendit_invoice_id')->nullable();
            $table->string('xendit_payment_url')->nullable();
            $table->string('xendit_status')->nullable();
            $table->timestamps();
        });

        // 5. Tabel Pesanan Detail (Menyimpan snapshot harga saat pembelian)
        Schema::create('pesanan_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pesanan_id')->constrained('pesanans')->cascadeOnDelete();
            $table->foreignId('produk_id')->constrained('produks')->cascadeOnDelete();
            $table->string('nama_produk');
            $table->unsignedBigInteger('harga_saat_beli');
            $table->integer('jumlah');
            $table->unsignedBigInteger('subtotal');
            $table->boolean('perlu_resep')->default(false);
            $table->timestamps();
        });

        // 6. Tabel Kunci Idempoten (Sesuai Bab 9 PRD untuk X-Kunci-Idempoten)
        Schema::create('kunci_idempotens', function (Blueprint $table) {
            $table->id();
            $table->string('kunci')->unique();
            $table->foreignId('pesanan_id')->constrained('pesanans')->cascadeOnDelete();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('kunci_idempotens');
        Schema::dropIfExists('pesanan_details');
        Schema::dropIfExists('pesanans');
        Schema::dropIfExists('keranjangs');
        Schema::dropIfExists('kurirs');
        Schema::dropIfExists('produks');
    }
};
