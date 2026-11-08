@extends('admin.layout')

@section('title', 'Kurir & Wilayah Pengantaran')
@section('page_heading', 'Pengaturan Kurir Internal Apotek')

@section('content')
<div class="card">
    <div class="card-toolbar">
        <p style="margin: 0; color: #64748b; font-size: 0.9rem;">
            Daftar kurir dan tarif ini akan langsung muncul di halaman checkout aplikasi Flutter (pilihan kurir internal).
        </p>
        <button type="button" class="btn btn-primary" id="btnBukaModalKurir" data-url-store="{{ route('admin.kurir.store') }}">
            + Tambah Kurir Baru
        </button>
    </div>

    <div class="table-responsive">
        <table class="data-table data-table-kurir">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Nama Kurir</th>
                    <th>Cakupan Wilayah</th>
                    <th>Tarif Ongkir</th>
                    <th>Estimasi Waktu</th>
                    <th>Aksi</th>
                </tr>
            </thead>
            <tbody>
                @forelse($daftarKurir as $kurir)
                <tr>
                    <td>#{{ $kurir->id }}</td>
                    <td style="font-weight: 600;">{{ $kurir->nama }}</td>
                    <td>{{ $kurir->wilayah }}</td>
                    <td style="font-weight: 600; color: #0f766e;">Rp {{ number_format($kurir->tarif, 0, ',', '.') }}</td>
                    <td><span class="badge badge-teal">{{ $kurir->estimasi }}</span></td>
                    <td>
                        <div class="table-actions">
                            <button type="button" class="btn btn-secondary btn-sm btn-edit-kurir"
                                data-id="{{ $kurir->id }}"
                                data-nama="{{ $kurir->nama }}"
                                data-wilayah="{{ $kurir->wilayah }}"
                                data-tarif="{{ $kurir->tarif }}"
                                data-estimasi="{{ $kurir->estimasi }}"
                                data-url-update="{{ route('admin.kurir.update', $kurir->id) }}">
                                Edit
                            </button>
                            <form action="{{ route('admin.kurir.destroy', $kurir->id) }}" method="POST" onsubmit="return confirm(@js('Hapus kurir ' . $kurir->nama . '?'))">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="btn btn-danger btn-sm">Hapus</button>
                            </form>
                        </div>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="6" style="text-align: center; color: #94a3b8; padding: 24px;">Belum ada data kurir internal apotek.</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>

<!-- Modal Form Kurir (Tambah / Edit) -->
<div class="modal-overlay" id="modalKurir">
    <div class="modal-content">
        <h3 id="modalKurirTitle" style="margin-top: 0; margin-bottom: 16px;">Tambah Kurir Baru</h3>
        <form id="formKurir" method="POST" action="{{ route('admin.kurir.store') }}">
            @csrf
            <input type="hidden" name="_method" id="kurirMethod" value="POST">

            <div class="form-group">
                <label class="form-label">Nama Kurir / Jenis Pengantaran *</label>
                <input type="text" name="nama" id="kurirNama" class="form-control" required placeholder="Contoh: Kurir Instan Apotek">
            </div>

            <div class="form-group">
                <label class="form-label">Cakupan Wilayah *</label>
                <input type="text" name="wilayah" id="kurirWilayah" class="form-control" required placeholder="Contoh: Dalam Kota (Radius 5km)">
            </div>

            <div class="form-group">
                <label class="form-label">Tarif Ongkos Kirim (Rupiah) *</label>
                <input type="number" name="tarif" id="kurirTarif" class="form-control" required min="0" placeholder="Contoh: 10000">
            </div>

            <div class="form-group">
                <label class="form-label">Estimasi Waktu Sampai *</label>
                <input type="text" name="estimasi" id="kurirEstimasi" class="form-control" required placeholder="Contoh: 30 - 60 menit">
            </div>

            <div style="display: flex; justify-content: flex-end; gap: 8px; margin-top: 20px;">
                <button type="button" class="btn btn-secondary" id="btnTutupModalKurir">Batal</button>
                <button type="submit" class="btn btn-primary">Simpan Data Kurir</button>
            </div>
        </form>
    </div>
</div>
@endsection

