@extends('admin.layout')

@section('title', 'Kelola Admin')
@section('page_heading', 'Kelola Akun Admin')

@section('content')
<div class="card" style="max-width: 560px;">
    <h4 style="margin: 0 0 6px 0;">Tambah Admin Baru</h4>
    <p style="margin: 0 0 20px 0; color: #64748b; font-size: 0.85rem;">
        Akun baru dapat langsung login ke panel admin dengan email dan password yang didaftarkan.
    </p>

    <form action="{{ route('admin.akun.store') }}" method="POST">
        @csrf

        <div class="form-group">
            <label class="form-label" for="name">Nama Admin</label>
            <input type="text" id="name" name="name" class="form-control"
                value="{{ old('name') }}" placeholder="cth: Budi Apoteker" required>
        </div>

        <div class="form-group">
            <label class="form-label" for="email">Email</label>
            <input type="email" id="email" name="email" class="form-control"
                value="{{ old('email') }}" placeholder="cth: budi@apoteksehat.test" required>
        </div>

        <div class="form-group">
            <label class="form-label" for="password">Password</label>
            <input type="password" id="password" name="password" class="form-control"
                placeholder="Minimal 8 karakter" required>
        </div>

        <div class="form-group">
            <label class="form-label" for="password_confirmation">Ulangi Password</label>
            <input type="password" id="password_confirmation" name="password_confirmation" class="form-control"
                placeholder="Ulangi password di sini" required>
        </div>

        <button type="submit" class="btn btn-primary">+ Tambah Admin</button>
    </form>
</div>

<div class="card">
    <h4 style="margin: 0 0 16px 0;">Daftar Admin ({{ $daftarAdmin->count() }})</h4>
    <div class="table-responsive">
        <table class="data-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Nama</th>
                    <th>Email</th>
                    <th>Terdaftar</th>
                    <th>Aksi</th>
                </tr>
            </thead>
            <tbody>
                @forelse($daftarAdmin as $admin)
                <tr>
                    <td>#{{ $admin->id }}</td>
                    <td style="font-weight: 600;">
                        {{ $admin->name }}
                        @if($admin->id === auth()->id())
                            <span class="badge badge-teal">Anda</span>
                        @endif
                    </td>
                    <td>{{ $admin->email }}</td>
                    <td>{{ $admin->created_at?->format('d M Y') ?? '-' }}</td>
                    <td>
                        @if($admin->id === auth()->id())
                            <span style="color: #94a3b8; font-size: 0.85rem;">Tidak dapat dihapus</span>
                        @else
                            <form action="{{ route('admin.akun.destroy', $admin) }}" method="POST"
                                onsubmit="return confirm('Hapus akun admin {{ $admin->name }}?');">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="btn btn-danger btn-sm">Hapus</button>
                            </form>
                        @endif
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="5" style="text-align: center; color: #94a3b8;">Belum ada akun admin.</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection
