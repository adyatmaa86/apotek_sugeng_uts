<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

class AdminProfilController extends Controller
{
    /**
     * Halaman edit profil admin yang sedang login.
     */
    public function edit()
    {
        return view('admin.profil.edit', [
            'admin' => auth()->user(),
        ]);
    }

    /**
     * Perbarui data profil admin yang sedang login.
     */
    public function update(Request $request): RedirectResponse
    {
        $admin = $request->user();

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => [
                'required',
                'email',
                'max:255',
                Rule::unique('users', 'email')->ignore($admin->id),
            ],
            'password' => ['nullable', 'confirmed', Password::min(8)],
        ], [
            'name.required' => 'Nama lengkap wajib diisi',
            'email.required' => 'Email wajib diisi',
            'email.email' => 'Format email tidak valid',
            'email.unique' => 'Email sudah digunakan akun lain',
            'password.confirmed' => 'Konfirmasi password tidak cocok',
            'password.min' => 'Password minimal 8 karakter',
        ]);

        $admin->name = $validated['name'];
        $admin->email = $validated['email'];

        if (! empty($validated['password'])) {
            $admin->password = $validated['password']; // otomatis ter-hash via cast
        }

        $admin->save();

        return redirect()
            ->route('admin.profil.edit')
            ->with('sukses', 'Profil berhasil diperbarui.');
    }
}
