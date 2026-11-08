<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Keranjang;
use App\Models\Kurir;
use App\Models\Pesanan;
use App\Models\Produk;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(): View
    {
        $totalProduk = Produk::count();
        $produkHabis = Produk::where('stok', '<=', 0)->count();
        $totalPesanan = Pesanan::count();
        $pesananMenunggu = Pesanan::whereIn('status', ['menunggu_pembayaran', 'menunggu_konfirmasi'])->count();
        $totalPendapatan = Pesanan::whereIn('status', ['dibayar', 'diproses', 'dikirim', 'selesai'])->sum('total');
        $totalKurir = Kurir::count();
        $totalKeranjangAktif = Keranjang::count();

        $pesananTerbaru = Pesanan::with(['kurir', 'details'])
            ->latest()
            ->take(6)
            ->get();

        $produkStokKritis = Produk::where('stok', '<=', 5)
            ->orderBy('stok', 'asc')
            ->take(5)
            ->get();

        return view('admin.dashboard', compact(
            'totalProduk',
            'produkHabis',
            'totalPesanan',
            'pesananMenunggu',
            'totalPendapatan',
            'totalKurir',
            'totalKeranjangAktif',
            'pesananTerbaru',
            'produkStokKritis'
        ));
    }
}

