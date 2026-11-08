<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class AdminAuthController extends Controller
{
    public function showLogin(): View|RedirectResponse
    {
        if (Auth::check() && Auth::user()->is_admin) {
            return redirect()->route('admin.dashboard');
        }

        return view('admin.login');
    }

    public function login(Request $request): RedirectResponse
    {
        $credentials = $request->validate([
            'email' => 'required|email|max:150',
            'password' => 'required|string',
        ]);

        $berhasil = Auth::attempt([
            'email' => strtolower(trim($credentials['email'])),
            'password' => $credentials['password'],
            'is_admin' => true,
        ], $request->boolean('remember'));

        if (! $berhasil) {
            throw ValidationException::withMessages([
                'email' => 'Email atau password admin tidak sesuai.',
            ]);
        }

        $request->session()->regenerate();

        return redirect()->intended(route('admin.dashboard'))
            ->with('sukses', 'Selamat datang kembali, Admin.');
    }

    public function logout(Request $request): RedirectResponse
    {
        Auth::logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login')
            ->with('sukses', 'Anda telah keluar dari panel admin.');
    }
}
