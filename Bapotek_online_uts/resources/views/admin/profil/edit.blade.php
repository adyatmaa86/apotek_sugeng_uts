@extends('admin.layout')

@section('title', 'Edit Profil Admin')
@section('page_heading', 'Edit Profil Admin')

@section('content')
<div class="card" style="max-width: 560px;">
    <h4 style="margin: 0 0 6px 0;">Data Akun Anda</h4>
    <p style="margin: 0 0 20px 0; color: #64748b; font-size: 0.85rem;">
        Perbarui identitas akun admin. Password hanya berubah bila diisi.
    </p>

    <form action="{{ route('admin.profil.update') }}" method="POST">
        @csrf
        @method('PUT')

        <div class="form-group">
            <label class="form-label" for="name">Nama Lengkap</label>
            <input type="text" id="name" name="name" class="form-control"
                value="{{ old('name', $admin->name) }}" required>
        </div>

        <div class="form-group">
            <label class="form-label" for="email">Email</label>
            <input type="email" id="email" name="email" class="form-control"
                value="{{ old('email', $admin->email) }}" required>
        </div>

        <div class="form-group">
            <label class="form-label" for="password">Password Baru <small style="color: #94a3b8;">(opsional)</small></label>
            <input type="password" id="password" name="password" class="form-control"
                placeholder="Biarkan kosong bila tidak ingin mengganti">
        </div>

        <div class="form-group">
            <label class="form-label" for="password_confirmation">Ulangi Password Baru</label>
            <input type="password" id="password_confirmation" name="password_confirmation" class="form-control"
                placeholder="Ulangi password baru di sini">
        </div>

        <button type="submit" class="btn btn-primary">Simpan Perubahan</button>
    </form>
</div>
@endsection
