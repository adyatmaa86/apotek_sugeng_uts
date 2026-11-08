@extends('admin.layout')

@section('title', 'Ubah Produk - ' . $produk->nama)
@section('page_heading', 'Edit Produk Obat / Alkes')

@section('content')
<div class="card" style="max-width: 800px;">
    <form action="{{ route('admin.produk.update', $produk->id) }}" method="POST" enctype="multipart/form-data">
        @csrf
        @method('PUT')
        
        <div class="form-group">
            <label class="form-label">Nama Produk *</label>
            <input type="text" name="nama" value="{{ old('nama', $produk->nama) }}" class="form-control" required>
        </div>

        <div class="form-grid form-grid-2">
            <div class="form-group">
                <label class="form-label">Kategori *</label>
                <select name="kategori" class="form-control" required>
                    <option value="Obat" {{ old('kategori', $produk->kategori) == 'Obat' ? 'selected' : '' }}>Obat</option>
                    <option value="Alat Kesehatan" {{ old('kategori', $produk->kategori) == 'Alat Kesehatan' ? 'selected' : '' }}>Alat Kesehatan</option>
                </select>
            </div>
            <div class="form-group">
                <label class="form-label">Golongan Obat</label>
                <input type="text" name="golongan" value="{{ old('golongan', $produk->golongan) }}" class="form-control">
            </div>
        </div>

        <div class="form-grid form-grid-3">
            <div class="form-group">
                <label class="form-label">Harga Satuan (Rupiah Bulat) *</label>
                <input type="number" name="harga" value="{{ old('harga', $produk->harga) }}" class="form-control" required min="0">
            </div>
            <div class="form-group">
                <label class="form-label">Stok Tersedia *</label>
                <input type="number" name="stok" value="{{ old('stok', $produk->stok) }}" class="form-control" required min="0">
            </div>
            <div class="form-group">
                <label class="form-label">Batas Per Transaksi *</label>
                <input type="number" name="batas_per_pembelian" value="{{ old('batas_per_pembelian', $produk->batas_per_pembelian) }}" class="form-control" required min="1">
            </div>
        </div>

        <div class="form-group">
            <label class="form-label">Satuan Produk</label>
            <input type="text" name="satuan" value="{{ old('satuan', $produk->satuan) }}" class="form-control">
        </div>

        <div class="form-group">
            <label class="form-label">Foto Produk Obat / Alkes</label>
            @if($produk->foto_url)
                <div style="margin-bottom: 10px;">
                    <img src="{{ $produk->foto_url }}" alt="{{ $produk->nama }}" style="max-height: 120px; border-radius: 8px; border: 1px solid #cbd5e1;">
                </div>
            @endif
            <input type="file" name="foto" accept="image/*" class="form-control">
            <small style="color: #64748b;">Pilih file baru jika ingin mengganti foto saat ini. Format JPG, PNG, WEBP (Max 3MB).</small>
        </div>

        <div class="form-group">
            <label class="form-label">Deskripsi Lengkap / Indikasi</label>
            <textarea name="deskripsi" rows="3" class="form-control">{{ old('deskripsi', $produk->deskripsi) }}</textarea>
        </div>

        <div class="checkbox-row">
            <label class="checkbox-label">
                <input type="hidden" name="perlu_resep" value="0">
                <input type="checkbox" name="perlu_resep" value="1" @checked(old('perlu_resep', $produk->perlu_resep) == '1')>
                <span>Wajib Nomor Resep Dokter (Obat Keras)</span>
            </label>
            <label class="checkbox-label">
                <input type="hidden" name="tersedia" value="0">
                <input type="checkbox" name="tersedia" value="1" @checked(old('tersedia', $produk->tersedia) == '1')>
                <span>Produk Aktif Dijual di Aplikasi Flutter</span>
            </label>
        </div>

        <div style="display: flex; gap: 12px; margin-top: 24px;">
            <button type="submit" class="btn btn-primary">Simpan Perubahan</button>
            <a href="{{ route('admin.produk.index') }}" class="btn btn-secondary">Batal</a>
        </div>
    </form>
</div>
@endsection

