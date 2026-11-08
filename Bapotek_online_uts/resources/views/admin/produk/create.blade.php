@extends('admin.layout')

@section('title', 'Tambah Produk Baru')
@section('page_heading', 'Tambah Obat atau Alat Kesehatan')

@section('content')
<div class="card" style="max-width: 800px;">
    <form action="{{ route('admin.produk.store') }}" method="POST" enctype="multipart/form-data">
        @csrf
        <div class="form-group">
            <label class="form-label">Nama Produk *</label>
            <input type="text" name="nama" value="{{ old('nama') }}" class="form-control" required placeholder="Contoh: Paracetamol 500mg Strip">
        </div>

        <div class="form-grid form-grid-2">
            <div class="form-group">
                <label class="form-label">Kategori *</label>
                <select name="kategori" class="form-control" required>
                    <option value="Obat" {{ old('kategori') == 'Obat' ? 'selected' : '' }}>Obat</option>
                    <option value="Alat Kesehatan" {{ old('kategori') == 'Alat Kesehatan' ? 'selected' : '' }}>Alat Kesehatan</option>
                </select>
            </div>
            <div class="form-group">
                <label class="form-label">Golongan Obat</label>
                <input type="text" name="golongan" value="{{ old('golongan', 'Bebas') }}" class="form-control" placeholder="Contoh: Bebas, Bebas Terbatas, Keras">
            </div>
        </div>

        <div class="form-grid form-grid-3">
            <div class="form-group">
                <label class="form-label">Harga Satuan (Rupiah Bulat) *</label>
                <input type="number" name="harga" value="{{ old('harga') }}" class="form-control" required min="0" placeholder="Contoh: 15000">
            </div>
            <div class="form-group">
                <label class="form-label">Stok Tersedia *</label>
                <input type="number" name="stok" value="{{ old('stok', 10) }}" class="form-control" required min="0">
            </div>
            <div class="form-group">
                <label class="form-label">Batas Per Transaksi *</label>
                <input type="number" name="batas_per_pembelian" value="{{ old('batas_per_pembelian', 5) }}" class="form-control" required min="1">
            </div>
        </div>

        <div class="form-group">
            <label class="form-label">Satuan Produk</label>
            <input type="text" name="satuan" value="{{ old('satuan', 'Strip') }}" class="form-control" placeholder="Strip / Botol / Box / Pcs / Tablet">
        </div>

        <div class="form-group">
            <label class="form-label">Foto Produk Obat / Alkes (Akan Tampil di Flutter)</label>
            <input type="file" name="foto" accept="image/*" class="form-control">
            <small style="color: #64748b;">Format: JPG, PNG, WEBP (Maksimal 3MB). Jika kosong akan menggunakan ikon standar kategori.</small>
        </div>

        <div class="form-group">
            <label class="form-label">Deskripsi Lengkap / Indikasi</label>
            <textarea name="deskripsi" rows="3" class="form-control" placeholder="Khasiat, aturan pakai, efek samping, dll...">{{ old('deskripsi') }}</textarea>
        </div>

        <div class="checkbox-row">
            <label class="checkbox-label">
                <input type="hidden" name="perlu_resep" value="0">
                <input type="checkbox" name="perlu_resep" value="1" @checked(old('perlu_resep') == '1')>
                <span>Wajib Nomor Resep Dokter (Obat Keras)</span>
            </label>
            <label class="checkbox-label">
                <input type="hidden" name="tersedia" value="0">
                <input type="checkbox" name="tersedia" value="1" @checked(old('tersedia', '1') == '1')>
                <span>Produk Aktif Dijual di Aplikasi Flutter</span>
            </label>
        </div>

        <div style="display: flex; gap: 12px; margin-top: 24px;">
            <button type="submit" class="btn btn-primary">Simpan Produk</button>
            <a href="{{ route('admin.produk.index') }}" class="btn btn-secondary">Batal</a>
        </div>
    </form>
</div>
@endsection

