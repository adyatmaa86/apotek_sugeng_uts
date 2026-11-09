@extends('admin.layout')

@section('title', 'Kelola Produk Obat & Alkes')
@section('page_heading', 'Daftar Produk Obat & Alat Kesehatan')

@section('content')
<div class="card">
    <!-- Filter Bar -->
    <form method="GET" action="{{ route('admin.produk.index') }}" class="filter-form">
        <input type="text" name="cari" value="{{ request('cari') }}" placeholder="Cari nama produk / deskripsi..." class="form-control filter-search">
        
        <select name="kategori" class="form-control filter-select">
            <option value="">Semua Kategori</option>
            @foreach($daftarKategori as $kat)
                <option value="{{ $kat }}" {{ request('kategori') == $kat ? 'selected' : '' }}>{{ $kat }}</option>
            @endforeach
        </select>

        <select name="status_stok" class="form-control filter-select">
            <option value="">Semua Status Stok</option>
            <option value="tersedia" {{ request('status_stok') == 'tersedia' ? 'selected' : '' }}>Stok Tersedia (>0)</option>
            <option value="habis" {{ request('status_stok') == 'habis' ? 'selected' : '' }}>Stok Habis (0)</option>
        </select>

        <button type="submit" class="btn btn-secondary">Filter</button>
        <a href="{{ route('admin.produk.index') }}" class="btn btn-secondary">Reset</a>
        <a href="{{ route('admin.produk.create') }}" class="btn btn-primary filter-add">+ Tambah Produk Baru</a>
    </form>

    <div class="table-responsive">
        <table class="data-table data-table-produk">
            <thead>
                <tr>
                    <th>Foto</th>
                    <th>Nama Produk</th>
                    <th>Kategori / Golongan</th>
                    <th>Harga</th>
                    <th>Stok & Satuan</th>
                    <th>Limit Pembelian</th>
                    <th>Status Resep</th>
                    <th>Status Jual</th>
                    <th>Aksi</th>
                </tr>
            </thead>
            <tbody>
                @forelse($daftarProduk as $p)
                <tr>
                    <td>
                        @if($p->foto_url)
                            <img src="{{ $p->foto_url }}" alt="{{ $p->nama }}" style="width: 44px; height: 44px; object-fit: cover; border-radius: 8px; border: 1px solid #e2e8f0;">
                        @else
                            <div style="width: 44px; height: 44px; background: #f1f5f9; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 1.2rem;">
                                {{ $p->kategori === 'Obat' ? '💊' : '🩺' }}
                            </div>
                        @endif
                    </td>
                    <td>
                        <div style="font-weight: 600;">{{ $p->nama }}</div>
                        <small style="color: #64748b;">#{{ $p->id }} • {{ \Illuminate\Support\Str::limit($p->deskripsi, 40) }}</small>
                    </td>
                    <td>
                        <div><span class="badge badge-teal">{{ $p->kategori }}</span></div>
                        <small style="color: #64748b;">{{ $p->golongan ?: 'Obat Bebas' }}</small>
                    </td>
                    <td style="font-weight: 600; color: #0f766e; white-space: nowrap;">Rp {{ number_format($p->harga, 0, ',', '.') }}</td>
                    <td>
                        <span class="badge {{ $p->stok <= 0 ? 'badge-danger' : ($p->stok <= 5 ? 'badge-warning' : 'badge-success') }}">
                            {{ $p->stok }} {{ $p->satuan }}
                        </span>
                    </td>
                    <td>Max: {{ $p->batas_per_pembelian }} {{ $p->satuan }}</td>
                    <td>
                        @if($p->perlu_resep)
                            <span class="badge badge-danger">Wajib Resep</span>
                        @else
                            <span class="badge badge-success">Bebas</span>
                        @endif
                    </td>
                    <td>
                        @if($p->tersedia)
                            <span class="badge badge-success">Aktif</span>
                        @else
                            <span class="badge badge-danger">Nonaktif</span>
                        @endif
                    </td>
                    <td>
                        <div class="table-actions">
                            <a href="{{ route('admin.produk.edit', $p->id) }}" class="btn btn-secondary btn-sm">Edit</a>
                            <form action="{{ route('admin.produk.destroy', $p->id) }}" method="POST" class="form-confirm" data-confirm-title="Hapus Produk?" data-confirm-text="{{ 'Apakah Anda yakin ingin menghapus produk ' . $p->nama . '?' }}" data-confirm-btn="Ya, Hapus!">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="btn btn-danger btn-sm">Hapus</button>
                            </form>
                        </div>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="9" style="text-align: center; color: #94a3b8; padding: 24px;">Tidak ada data produk yang ditemukan.</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div style="margin-top: 20px;">
        {{ $daftarProduk->links() }}
    </div>
</div>
@endsection

