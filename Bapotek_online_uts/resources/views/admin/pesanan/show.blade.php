@extends('admin.layout')

@section('title', 'Rincian Pesanan - ' . $pesanan->nomor_pesanan)
@section('page_heading', 'Rincian & Pembaruan Status Pesanan')

@section('content')
<div style="margin-bottom: 16px;">
    <a href="{{ route('admin.pesanan.index') }}" class="btn btn-secondary btn-sm">&larr; Kembali ke Daftar Pesanan</a>
</div>

<div class="page-grid">
    <!-- Informasi & Item Pesanan -->
    <div>
        <div class="card">
            <div class="order-header">
                <div>
                    <h3 style="margin: 0; color: #0f172a;">Pesanan #{{ $pesanan->nomor_pesanan }}</h3>
                    <small style="color: #64748b;">Waktu Transaksi: {{ $pesanan->created_at->format('d F Y, H:i:s') }}</small>
                </div>
                <div>
                    @php
                        $badgeClass = match($pesanan->status) {
                            'dibayar', 'selesai' => 'badge-success',
                            'menunggu_pembayaran', 'menunggu_konfirmasi' => 'badge-warning',
                            'diproses', 'dikirim' => 'badge-info',
                            'dibatalkan' => 'badge-danger',
                            default => 'badge-teal',
                        };
                    @endphp
                    <span class="badge {{ $badgeClass }}" style="font-size: 0.9rem; padding: 6px 12px;">{{ strtoupper(str_replace('_', ' ', $pesanan->status)) }}</span>
                </div>
            </div>

            <!-- Detail Obat yang Dipesan -->
            <h4 style="margin: 0 0 12px 0;">Daftar Obat & Alkes yang Dipesan:</h4>
            <div class="table-responsive">
                <table class="data-table data-table-detail">
                    <thead>
                        <tr>
                            <th>Nama Obat</th>
                            <th>Status Resep</th>
                            <th>Harga Snapshot</th>
                            <th>Jumlah</th>
                            <th>Subtotal</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($pesanan->details as $item)
                        <tr>
                            <td style="font-weight: 600;">
                                {{ $item->nama_produk }}
                                @if($item->produk)
                                    <div style="font-size: 0.8rem; color: #64748b;">Kategori: {{ $item->produk->kategori }} ({{ $item->produk->satuan }})</div>
                                @endif
                            </td>
                            <td>
                                @if($item->perlu_resep)
                                    <span class="badge badge-danger">Obat Resep</span>
                                @else
                                    <span class="badge badge-success">Bebas</span>
                                @endif
                            </td>
                            <td style="white-space: nowrap;">Rp {{ number_format($item->harga_saat_beli, 0, ',', '.') }}</td>
                            <td>{{ $item->jumlah }}</td>
                            <td style="font-weight: 600; color: #0f766e; white-space: nowrap;">Rp {{ number_format($item->subtotal, 0, ',', '.') }}</td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            <!-- Rincian Biaya -->
            <div class="cost-summary">
                <div class="cost-row">
                    <span>Subtotal Produk:</span>
                    <span style="font-weight: 600;">Rp {{ number_format($pesanan->subtotal, 0, ',', '.') }}</span>
                </div>
                <div class="cost-row">
                    <span>Ongkos Kirim:</span>
                    <span style="font-weight: 600;">Rp {{ number_format($pesanan->ongkos_kirim, 0, ',', '.') }}</span>
                </div>
                <div class="cost-row cost-total">
                    <span>Total Akhir:</span>
                    <span>Rp {{ number_format($pesanan->total, 0, ',', '.') }}</span>
                </div>
            </div>
        </div>
    </div>

    <!-- Panel Kontrol Aksi & Info Penerima -->
    <div>
        <!-- Update Status -->
        <div class="card">
            <h4 style="margin: 0 0 16px 0;">Perbarui Status Pesanan</h4>
            <p style="font-size: 0.85rem; color: #64748b; margin-top: 0;">
                Perubahan status di sini akan langsung terupdate secara real-time di aplikasi Flutter pelanggan!
            </p>
            @php
                $aksiStatus = [
                    'menunggu_pembayaran' => [
                        ['dibayar', 'Tandai Dibayar', 'btn-primary'],
                        ['dibatalkan', 'Batalkan Pesanan', 'btn-danger'],
                    ],
                    'menunggu_konfirmasi' => [
                        ['dibayar', 'Konfirmasi Pembayaran Diterima', 'btn-primary'],
                        ['dibatalkan', 'Batalkan Pesanan', 'btn-danger'],
                    ],
                    'dibayar' => [
                        ['diproses', 'Proses Obat (Apoteker)', 'btn-primary'],
                    ],
                    'diproses' => [
                        ['dikirim', 'Serahkan ke Kurir Pengantar', 'btn-primary'],
                    ],
                    'dikirim' => [
                        ['selesai', 'Tandai Pesanan Selesai', 'btn-primary'],
                    ],
                ];
            @endphp

            @if(isset($aksiStatus[$pesanan->status]))
                @foreach($aksiStatus[$pesanan->status] as [$target, $label, $btnClass])
                    <form action="{{ route('admin.pesanan.updateStatus', $pesanan->id) }}" method="POST"
                        style="margin-bottom: 10px;"
                        class="form-confirm"
                        data-confirm-title="Ubah Status Pesanan?"
                        data-confirm-text="Status pesanan ini akan diperbarui menjadi '{{ strtoupper($target) }}'."
                        data-confirm-btn="Ya, Ubah Status">
                        @csrf
                        @method('PATCH')
                        <input type="hidden" name="status" value="{{ $target }}">
                        <button type="submit" class="btn {{ $btnClass }}" style="width: 100%;">{{ $label }}</button>
                    </form>
                @endforeach
            @else
                <p style="font-size: 0.9rem; color: #94a3b8; margin: 0;">
                    Tidak ada aksi status — pesanan sudah @if($pesanan->status == 'selesai') selesai @else dibatalkan @endif.
                </p>
            @endif
        </div>

        <!-- Info Penerima & Pengiriman -->
        <div class="card">
            <h4 style="margin: 0 0 14px 0;">Data Penerima & Kurir</h4>
            <div style="font-size: 0.9rem; line-height: 1.6;">
                <div style="margin-bottom: 8px;">
                    <strong style="color: #475569;">Nama Penerima:</strong>
                    <div>{{ $pesanan->nama_penerima }}</div>
                </div>
                <div style="margin-bottom: 8px;">
                    <strong style="color: #475569;">Alamat Antar:</strong>
                    <div>{{ $pesanan->alamat }}</div>
                </div>
                <div style="margin-bottom: 8px;">
                    <strong style="color: #475569;">Kurir / Pengiriman:</strong>
                    <div>{{ $pesanan->kurir ? $pesanan->kurir->nama . ' (' . $pesanan->kurir->wilayah . ')' : ($pesanan->rajaongkir_service ?: 'Internal') }}</div>
                </div>
                <div style="margin-bottom: 8px;">
                    <strong style="color: #475569;">Metode Pembayaran:</strong>
                    <div><span class="badge badge-teal">{{ strtoupper($pesanan->metode_pembayaran) }}</span></div>
                </div>
                <div style="margin-bottom: 8px;">
                    <strong style="color: #475569;">Nomor Resep Dokter:</strong>
                    <div>
                        @if($pesanan->nomor_resep)
                            <span class="badge badge-danger">{{ $pesanan->nomor_resep }}</span>
                        @else
                            <span style="color: #94a3b8;">Tidak Memerlukan Resep</span>
                        @endif
                    </div>
                </div>
                <div style="margin-bottom: 8px;">
                    <strong style="color: #475569;">Foto Resep Dokter:</strong>
                    <div style="margin-top: 6px;">
                        @if($pesanan->foto_resep)
                            <a href="{{ Storage::url($pesanan->foto_resep) }}" target="_blank">
                                <img src="{{ Storage::url($pesanan->foto_resep) }}"
                                     alt="Foto Resep"
                                     style="max-width: 100%; max-height: 220px; border-radius: 8px; border: 1px solid #e2e8f0; cursor: pointer; object-fit: contain;">
                            </a>
                        @else
                            <span style="color: #94a3b8; font-size: 0.85rem;">Tidak ada foto resep diunggah</span>
                        @endif
                    </div>
                </div>
                @if($pesanan->xendit_invoice_id)
                <div style="margin-top: 12px; padding: 10px; background: #eef2ff; border-radius: 8px;">
                    <strong style="color: #4338ca; font-size: 0.85rem;">Xendit Invoice ID:</strong>
                    <div style="font-size: 0.8rem; word-break: break-all;">{{ $pesanan->xendit_invoice_id }}</div>
                    @if($pesanan->xendit_payment_url)
                        <a href="{{ $pesanan->xendit_payment_url }}" target="_blank" style="display: inline-block; margin-top: 4px; font-size: 0.8rem; color: #4f46e5; font-weight: 600;">Lihat Invoice Xendit &rarr;</a>
                    @endif
                </div>
                @endif
            </div>
        </div>
    </div>
</div>
@endsection

