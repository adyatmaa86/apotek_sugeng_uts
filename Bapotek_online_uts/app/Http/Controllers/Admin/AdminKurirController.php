<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Kurir;
use App\Models\Pesanan;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class AdminKurirController extends Controller
{
    public function index(): View
    {
        $daftarKurir = Kurir::latest()->get();
        return view('admin.kurir.index', compact('daftarKurir'));
    }

    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'nama' => 'required|string|max:255',
            'wilayah' => 'required|string|max:255',
            'tarif' => 'required|integer|min:0',
            'estimasi' => 'required|string|max:100',
        ]);

        Kurir::create($validated);

        return redirect()->route('admin.kurir.index')->with('sukses', 'Metode kurir internal baru berhasil ditambahkan.');
    }

    public function update(Request $request, Kurir $kurir): RedirectResponse
    {
        $validated = $request->validate([
            'nama' => 'required|string|max:255',
            'wilayah' => 'required|string|max:255',
            'tarif' => 'required|integer|min:0',
            'estimasi' => 'required|string|max:100',
        ]);

        $kurir->update($validated);

        return redirect()->route('admin.kurir.index')->with('sukses', 'Tarif dan data kurir berhasil diperbarui.');
    }

    public function destroy(Kurir $kurir): RedirectResponse
    {
        if (Pesanan::where('kurir_id', $kurir->id)->exists()) {
            return redirect()->route('admin.kurir.index')
                ->with('galat', 'Kurir tidak dapat dihapus karena sudah tercatat pada riwayat pesanan.');
        }

        $kurir->delete();
        return redirect()->route('admin.kurir.index')->with('sukses', 'Data kurir berhasil dihapus.');
    }
}

