<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use App\Services\PesananStatusService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class AdminPesananController extends Controller
{
    public function __construct(private PesananStatusService $statusService)
    {
    }

    public function index(Request $request): View
    {
        $query = Pesanan::with(['kurir', 'details']);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('cari')) {
            $cari = $request->cari;
            $query->where(function ($q) use ($cari) {
                $q->where('nomor_pesanan', 'like', "%{$cari}%")
                  ->orWhere('nama_penerima', 'like', "%{$cari}%")
                  ->orWhere('nomor_resep', 'like', "%{$cari}%");
            });
        }

        $daftarPesanan = $query->latest()->paginate(10)->withQueryString();

        return view('admin.pesanan.index', compact('daftarPesanan'));
    }

    public function show(Pesanan $pesanan): View
    {
        $pesanan->load(['kurir', 'details.produk']);
        return view('admin.pesanan.show', compact('pesanan'));
    }

    public function updateStatus(Request $request, Pesanan $pesanan): RedirectResponse
    {
        $validated = $request->validate([
            'status' => 'required|in:menunggu_pembayaran,menunggu_konfirmasi,dibayar,diproses,dikirim,selesai,dibatalkan',
        ]);

        try {
            $this->statusService->ubahStatus($pesanan, $validated['status']);
        } catch (\DomainException $e) {
            return redirect()->route('admin.pesanan.show', $pesanan->id)
                ->with('galat', $e->getMessage());
        }

        return redirect()->route('admin.pesanan.show', $pesanan->id)
            ->with('sukses', "Status pesanan #{$pesanan->nomor_pesanan} berhasil diubah menjadi: {$validated['status']}");
    }
}

