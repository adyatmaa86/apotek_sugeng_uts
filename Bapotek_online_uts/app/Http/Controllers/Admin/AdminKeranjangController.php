<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Keranjang;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\View;

class AdminKeranjangController extends Controller
{
    public function index(): View
    {
        $daftarKeranjang = Keranjang::with('produk')->latest()->get();
        return view('admin.keranjang.index', compact('daftarKeranjang'));
    }

    public function destroy(Keranjang $keranjang): RedirectResponse
    {
        $keranjang->delete();
        return redirect()->route('admin.keranjang.index')->with('sukses', 'Item keranjang berhasil dihapus.');
    }

    public function clearAll(): RedirectResponse
    {
        Keranjang::truncate();
        return redirect()->route('admin.keranjang.index')->with('sukses', 'Semua isi keranjang berhasil dikosongkan.');
    }
}

