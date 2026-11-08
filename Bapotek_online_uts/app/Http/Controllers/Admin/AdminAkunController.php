<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rules\Password;

class AdminAkunController extends Controller
{
    /**
     * Daftar akun admin + form penambahan admin baru.
     */
    public function index()
    {
        $daftarAdmin = User::query()
            ->where('is_admin', true)
            ->orderBy('name')
            ->get();

        return view('admin.akun.index', compact('daftarAdmin'));
    }

    /**
     * Tambahkan akun admin baru.
     */
    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:users,email',
            'password' => ['required', 'confirmed', Password::min(8)],
        ], [
            'name.required' => 'Nama admin wajib diisi',
            'email.required' => 'Email wajib diisi',
            'email.email' => 'Format email tidak valid',
            'email.unique' => 'Email sudah terdaftar',
            'password.required' => 'Password wajib diisi',
            'password.confirmed' => 'Konfirmasi password tidak cocok',
            'password.min' => 'Password minimal 8 karakter',
        ]);

        User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => $validated['password'], // otomatis ter-hash via cast
            'is_admin' => true,
        ]);

        return redirect()
            ->route('admin.akun.index')
            ->with('sukses', 'Akun admin baru berhasil ditambahkan.');
    }

    /**
     * Hapus akun admin (tidak boleh menghapus akun sendiri).
     */
    public function destroy(Request $request, User $user): RedirectResponse
    {
        if ($user->id === $request->user()->id) {
            return redirect()
                ->route('admin.akun.index')
                ->with('galat', 'Anda tidak dapat menghapus akun yang sedang login.');
        }

        $user->delete();

        return redirect()
            ->route('admin.akun.index')
            ->with('sukses', 'Akun admin berhasil dihapus.');
    }
}
