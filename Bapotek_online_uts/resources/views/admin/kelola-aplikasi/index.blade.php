@extends('admin.layout')

@section('title', 'Kelola Aplikasi & Mode UTS')
@section('page_heading', 'Kelola Aplikasi')

@section('content')
<div class="card card-kelola-app">
    <div class="card-header">
        <div>
            <h4 class="card-title">Pengaturan Mode UTS (Kelola Produk)</h4>
            <p class="card-subtitle">
                Aktifkan tombol ini untuk memunculkan fitur Kelola Produk (CRUD Produk, Form Produk, Penyaring Kategori & Pencarian) di AppBar aplikasi Flutter.
            </p>
        </div>
        <div>
            @if($modeUts)
                <span class="badge badge-success badge-lg">Status: Mode UTS Aktif</span>
            @else
                <span class="badge badge-secondary badge-lg">Status: Mode UTS Nonaktif</span>
            @endif
        </div>
    </div>

    <div class="card-body">
        <div class="uts-feature-box">
            <div class="uts-feature-icon" aria-hidden="true">
                📦
            </div>
            <div class="uts-feature-details">
                <h5>Fitur yang Dikendalikan:</h5>
                <ul class="uts-feature-list">
                    <li><strong>CRUD Produk Lengkap:</strong> Akses tambah, ubah, dan hapus obat/alkes via aplikasi Flutter.</li>
                    <li><strong>Penyaring & Pencarian:</strong> Mengirim ulang permintaan ke server lewat parameter <code>?kategori=</code> dan <code>?cari=</code>.</li>
                    <li><strong>Formulir Produk:</strong> Menuju formulir produk dan kembali dengan hasil berhasil atau batal.</li>
                    <li><strong>Penanda Stok:</strong> Produk berstok 0 atau tidak tersedia memiliki penanda jelas dan tombol tambahnya dimatikan.</li>
                    <li><strong>Konfirmasi Hapus:</strong> Dialog konfirmasi sebelum permintaan penghapusan dikirim ke server.</li>
                </ul>
            </div>
        </div>

        <div class="uts-action-section">
            <form action="{{ route('admin.kelola-aplikasi.toggle') }}" method="POST">
                @csrf
                @if($modeUts)
                    <button type="submit" class="btn btn-danger btn-lg">
                        Keluar dari Mode UTS
                    </button>
                @else
                    <button type="submit" class="btn btn-primary btn-lg">
                        Masuk Mode UTS
                    </button>
                @endif
            </form>
            <p class="uts-note">
                Catatan: Setelah status diubah, aplikasi Flutter akan otomatis mendeteksi konfigurasi baru saat dibuka kembali atau halaman katalog disegarkan.
            </p>
        </div>
    </div>
</div>
@endsection

