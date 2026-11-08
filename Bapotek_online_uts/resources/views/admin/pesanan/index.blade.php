@extends('admin.layout')

@section('title', 'Daftar Pesanan Masuk')
@section('page_heading', 'Kelola Pesanan Pelanggan (Flutter App)')

@section('content')
<div class="card">
    <!-- Filter -->
    <form method="GET" action="{{ route('admin.pesanan.index') }}" class="filter-form">
        <input type="text" name="cari" value="{{ request('cari') }}" placeholder="Cari No. Pesanan / Penerima / Resep..." class="form-control filter-search">
        
        <select name="status" class="form-control filter-select">
            <option value="">Semua Status Pesanan</option>
            <option value="menunggu_pembayaran" {{ request('status') == 'menunggu_pembayaran' ? 'selected' : '' }}>Menunggu Pembayaran</option>
            <option value="menunggu_konfirmasi" {{ request('status') == 'menunggu_konfirmasi' ? 'selected' : '' }}>Menunggu Konfirmasi</option>
            <option value="dibayar" {{ request('status') == 'dibayar' ? 'selected' : '' }}>Dibayar</option>
            <option value="diproses" {{ request('status') == 'diproses' ? 'selected' : '' }}>Diproses Apoteker</option>
            <option value="dikirim" {{ request('status') == 'dikirim' ? 'selected' : '' }}>Sedang Dikirim</option>
            <option value="selesai" {{ request('status') == 'selesai' ? 'selected' : '' }}>Selesai</option>
            <option value="dibatalkan" {{ request('status') == 'dibatalkan' ? 'selected' : '' }}>Dibatalkan</option>
        </select>

        <button type="submit" class="btn btn-secondary">Filter</button>
        <a href="{{ route('admin.pesanan.index') }}" class="btn btn-secondary">Reset</a>
    </form>

    <div class="table-responsive">
        <table class="data-table data-table-pesanan">
            <thead>
                <tr>
                    <th>No. Pesanan</th>
                    <th>Waktu</th>
                    <th>Penerima & Alamat</th>
                    <th>Metode & Kurir</th>
                    <th>Nomor Resep</th>
                    <th>Total Biaya</th>
                    <th>Status Pesanan</th>
                    <th>Aksi</th>
                </tr>
            </thead>
            <tbody>
                @forelse($daftarPesanan as $pesanan)
                <tr>
                    <td style="font-weight: 700; color: #0f172a;">{{ $pesanan->nomor_pesanan }}</td>
                    <td>
                        <small style="color: #64748b;">{{ $pesanan->created_at->format('d M Y, H:i') }}</small>
                    </td>
                    <td>
                        <div style="font-weight: 600;">{{ $pesanan->nama_penerima }}</div>
                        <small style="color: #64748b;">{{ \Illuminate\Support\Str::limit($pesanan->alamat, 35) }}</small>
                    </td>
                    <td>
                        <span class="badge badge-teal">{{ strtoupper($pesanan->metode_pembayaran) }}</span>
                        <div style="font-size: 0.8rem; color: #475569; margin-top: 4px;">
                            {{ $pesanan->kurir ? $pesanan->kurir->nama : ($pesanan->rajaongkir_service ?: 'Internal') }}
                        </div>
                    </td>
                    <td>
                        @if($pesanan->nomor_resep)
                            <span class="badge badge-info" title="Obat Resep">{{ $pesanan->nomor_resep }}</span>
                        @else
                            <small style="color: #94a3b8;">Tidak ada</small>
                        @endif
                    </td>
                    <td style="font-weight: 700; color: #0f766e; white-space: nowrap;">
                        Rp {{ number_format($pesanan->total, 0, ',', '.') }}
                    </td>
                    <td>
                        @php
                            $badgeClass = match($pesanan->status) {
                                'dibayar', 'selesai' => 'badge-success',
                                'menunggu_pembayaran', 'menunggu_konfirmasi' => 'badge-warning',
                                'diproses', 'dikirim' => 'badge-info',
                                'dibatalkan' => 'badge-danger',
                                default => 'badge-teal',
                            };
                        @endphp
                        <span class="badge {{ $badgeClass }}">{{ str_replace('_', ' ', $pesanan->status) }}</span>
                    </td>
                    <td>
                        <a href="{{ route('admin.pesanan.show', $pesanan->id) }}" class="btn btn-primary btn-sm" style="white-space: nowrap;">Kelola</a>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="8" style="text-align: center; color: #94a3b8; padding: 24px;">Belum ada data transaksi pesanan.</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div style="margin-top: 20px;">
        {{ $daftarPesanan->links() }}
    </div>
</div>
@endsection

