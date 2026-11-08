@extends('admin.layout')

@section('title', 'Dashboard Utama')
@section('page_heading', 'Ringkasan Sistem & Statistik')

@section('content')
<div class="stats-grid">
    <div class="stat-card">
        <div class="stat-icon" style="background: #ccfbf1; color: #0f766e;">💊</div>
        <div>
            <div class="stat-label">Total Produk Obat/Alkes</div>
            <div class="stat-value">{{ $totalProduk }}</div>
            <small style="color: #64748b;">{{ $produkHabis }} produk habis</small>
        </div>
    </div>

    <div class="stat-card">
        <div class="stat-icon" style="background: #e0f2fe; color: #0369a1;">🛍️</div>
        <div>
            <div class="stat-label">Total Transaksi Pesanan</div>
            <div class="stat-value">{{ $totalPesanan }}</div>
            <small style="color: #0369a1; font-weight: 600;">{{ $pesananMenunggu }} pesanan baru</small>
        </div>
    </div>

    <div class="stat-card">
        <div class="stat-icon" style="background: #fef3c7; color: #b45309;">💰</div>
        <div>
            <div class="stat-label">Total Omset Terbayar</div>
            <div class="stat-value">Rp {{ number_format($totalPendapatan, 0, ',', '.') }}</div>
            <small style="color: #16a34a;">Status Paid / Delivered</small>
        </div>
    </div>

    <div class="stat-card">
        <div class="stat-icon" style="background: #f1f5f9; color: #475569;">🚚</div>
        <div>
            <div class="stat-label">Kurir Internal & Aktif</div>
            <div class="stat-value">{{ $totalKurir }}</div>
            <small style="color: #64748b;">{{ $totalKeranjangAktif }} item di keranjang user</small>
        </div>
    </div>
</div>

<div class="page-grid">
    <!-- Pesanan Terbaru -->
    <div class="card">
        <div class="card-head">
            <h4 style="margin: 0; font-size: 1.05rem;">Pesanan Masuk Terbaru (Flutter App)</h4>
            <a href="{{ route('admin.pesanan.index') }}" style="color: #0d9488; text-decoration: none; font-size: 0.85rem; font-weight: 600;">Lihat Semua &rarr;</a>
        </div>
        <div class="table-responsive">
            <table class="data-table data-table-dashboard">
                <thead>
                    <tr>
                        <th>No. Pesanan</th>
                        <th>Penerima</th>
                        <th>Total</th>
                        <th>Status</th>
                        <th>Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($pesananTerbaru as $p)
                    <tr>
                        <td style="font-weight: 600;">{{ $p->nomor_pesanan }}</td>
                        <td>
                            <div>{{ $p->nama_penerima }}</div>
                            <small style="color: #64748b;">{{ $p->details->count() }} item</small>
                        </td>
                        <td style="font-weight: 600; color: #0f766e; white-space: nowrap;">Rp {{ number_format($p->total, 0, ',', '.') }}</td>
                        <td>
                            @php
                                $badgeClass = match($p->status) {
                                    'dibayar', 'selesai' => 'badge-success',
                                    'menunggu_pembayaran', 'menunggu_konfirmasi' => 'badge-warning',
                                    'diproses', 'dikirim' => 'badge-info',
                                    'dibatalkan' => 'badge-danger',
                                    default => 'badge-teal',
                                };
                            @endphp
                            <span class="badge {{ $badgeClass }}">{{ str_replace('_', ' ', $p->status) }}</span>
                        </td>
                        <td>
                            <a href="{{ route('admin.pesanan.show', $p->id) }}" class="btn btn-secondary btn-sm">Rincian</a>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" style="text-align: center; color: #94a3b8; padding: 20px;">Belum ada pesanan dari aplikasi Flutter</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <!-- Peringatan Stok Obat -->
    <div class="card">
        <h4 style="margin: 0 0 16px 0; font-size: 1.05rem; color: #b91c1c;">⚠️ Peringatan Stok Menipis</h4>
        <p style="font-size: 0.85rem; color: #64748b; margin-top: 0;">Obat & Alkes berikut harus segera direstok agar pembeli di Flutter tidak kehabisan:</p>
        <ul style="list-style: none; padding: 0; margin: 0;">
            @forelse($produkStokKritis as $prod)
            <li class="stock-alert-item">
                <div>
                    <div style="font-weight: 600; font-size: 0.9rem;">{{ $prod->nama }}</div>
                    <small style="color: #64748b;">{{ $prod->kategori }} &middot; {{ $prod->satuan }}</small>
                </div>
                <div class="stock-alert-action">
                    <span class="badge {{ $prod->stok <= 0 ? 'badge-danger' : 'badge-warning' }}">
                        Sisa: {{ $prod->stok }}
                    </span>
                    <a href="{{ route('admin.produk.edit', $prod->id) }}">Edit</a>
                </div>
            </li>
            @empty
            <li style="text-align: center; color: #16a34a; padding: 20px;">Semua stok produk dalam kondisi aman!</li>
            @endforelse
        </ul>
    </div>
</div>
@endsection

