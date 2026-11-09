@extends('admin.layout')

@section('title', 'Pantau Keranjang Pelanggan')
@section('page_heading', 'Aktivitas Keranjang Belanja Flutter')

@section('content')
<div class="card">
    <div class="card-toolbar">
        <p style="margin: 0; color: #64748b; font-size: 0.9rem;">
            Menampilkan obat/alkes yang saat ini sedang disimpan di keranjang belanja oleh pelanggan melalui aplikasi Flutter.
        </p>
        @if($daftarKeranjang->isNotEmpty())
        <form action="{{ route('admin.keranjang.clearAll') }}" method="POST" class="form-confirm" data-confirm-title="Kosongkan Semua Keranjang?" data-confirm-text="Semua isi keranjang belanja pelanggan di aplikasi Flutter akan dihapus!" data-confirm-btn="Ya, Kosongkan!">
            @csrf
            @method('DELETE')
            <button type="submit" class="btn btn-danger btn-sm">Kosongkan Semua Keranjang</button>
        </form>
        @endif
    </div>

    <div class="table-responsive">
        <table class="data-table data-table-keranjang">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>ID Pelanggan (Device)</th>
                    <th>Produk Obat / Alkes</th>
                    <th>Harga Satuan</th>
                    <th>Jumlah Di Keranjang</th>
                    <th>Estimasi Subtotal</th>
                    <th>Waktu Masuk</th>
                    <th>Aksi</th>
                </tr>
            </thead>
            <tbody>
                @forelse($daftarKeranjang as $item)
                <tr>
                    <td>#{{ $item->id }}</td>
                    <td><span class="badge badge-teal">{{ $item->pelanggan_id }}</span></td>
                    <td style="font-weight: 600;">
                        {{ $item->produk ? $item->produk->nama : '[Produk Dihapus]' }}
                        @if($item->produk && $item->produk->perlu_resep)
                            <span class="badge badge-danger" style="font-size: 0.7rem;">Wajib Resep</span>
                        @endif
                    </td>
                    <td>Rp {{ number_format($item->produk ? $item->produk->harga : 0, 0, ',', '.') }}</td>
                    <td><strong>{{ $item->jumlah }}</strong> {{ $item->produk ? $item->produk->satuan : '' }}</td>
                    <td style="font-weight: 600; color: #0f766e;">
                        Rp {{ number_format(($item->produk ? $item->produk->harga : 0) * $item->jumlah, 0, ',', '.') }}
                    </td>
                    <td><small style="color: #64748b;">{{ $item->created_at->diffForHumans() }}</small></td>
                    <td>
                        <form class="inline-form form-confirm" action="{{ route('admin.keranjang.destroy', $item->id) }}" method="POST" data-confirm-title="Hapus Item Keranjang?" data-confirm-text="Item obat ini akan dikeluarkan dari keranjang belanja pelanggan." data-confirm-btn="Ya, Hapus!">
                            @csrf
                            @method('DELETE')
                            <button type="submit" class="btn btn-danger btn-sm">Hapus</button>
                        </form>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="8" style="text-align: center; color: #94a3b8; padding: 24px;">Tidak ada barang di keranjang belanja saat ini.</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection

