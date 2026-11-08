<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\PengaturanAplikasi;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class AdminKelolaAplikasiController extends Controller
{
    public function index(): View
    {
        $modeUts = PengaturanAplikasi::isModeUts();
        return view('admin.kelola-aplikasi.index', compact('modeUts'));
    }

    public function toggleModeUts(Request $request): RedirectResponse
    {
        $statusSekarang = PengaturanAplikasi::isModeUts();
        $statusBaru = !$statusSekarang;
        PengaturanAplikasi::setModeUts($statusBaru);

        $pesan = $statusBaru
            ? 'Mode UTS berhasil diaktifkan! Fitur Kelola Produk kini muncul di aplikasi Flutter.'
            : 'Mode UTS berhasil dinonaktifkan.';

        return redirect()->route('admin.kelola-aplikasi.index')->with('sukses', $pesan);
    }
}

