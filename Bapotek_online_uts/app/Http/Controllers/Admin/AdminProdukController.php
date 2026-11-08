<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Produk;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;

class AdminProdukController extends Controller
{
    public function index(Request $request): View
    {
        $query = Produk::query();

        if ($request->filled('cari')) {
            $cari = $request->cari;
            $query->where(function ($q) use ($cari) {
                $q->where('nama', 'like', "%{$cari}%")
                  ->orWhere('deskripsi', 'like', "%{$cari}%");
            });
        }

        if ($request->filled('kategori')) {
            $query->where('kategori', $request->kategori);
        }

        if ($request->filled('status_stok')) {
            if ($request->status_stok === 'habis') {
                $query->where('stok', '<=', 0);
            } elseif ($request->status_stok === 'tersedia') {
                $query->where('stok', '>', 0);
            }
        }

        $daftarProduk = $query->latest()->paginate(10)->withQueryString();
        $daftarKategori = Produk::select('kategori')->distinct()->pluck('kategori');

        return view('admin.produk.index', compact('daftarProduk', 'daftarKategori'));
    }

    public function create(): View
    {
        return view('admin.produk.create');
    }

    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'nama' => 'required|string|max:255',
            'harga' => 'required|integer|min:0',
            'kategori' => 'required|string|max:100',
            'stok' => 'required|integer|min:0',
            'batas_per_pembelian' => 'required|integer|min:1',
            'satuan' => 'nullable|string|max:50',
            'golongan' => 'nullable|string|max:50',
            'deskripsi' => 'nullable|string',
            'foto' => 'nullable|image|mimes:jpeg,png,jpg,webp|max:3072',
        ]);

        $validated['perlu_resep'] = $request->has('perlu_resep');
        $validated['tersedia'] = $request->has('tersedia');
        $validated['satuan'] = ($validated['satuan'] ?? null) ?: 'Pcs';

        if ($request->hasFile('foto')) {
            $path = $request->file('foto')->store('produk_fotos', 'public');
            $validated['foto'] = $path;
        }

        Produk::create($validated);

        return redirect()->route('admin.produk.index')->with('sukses', 'Produk obat/alkes berhasil ditambahkan.');
    }

    public function edit(Produk $produk): View
    {
        return view('admin.produk.edit', compact('produk'));
    }

    public function update(Request $request, Produk $produk): RedirectResponse
    {
        $validated = $request->validate([
            'nama' => 'required|string|max:255',
            'harga' => 'required|integer|min:0',
            'kategori' => 'required|string|max:100',
            'stok' => 'required|integer|min:0',
            'batas_per_pembelian' => 'required|integer|min:1',
            'satuan' => 'nullable|string|max:50',
            'golongan' => 'nullable|string|max:50',
            'deskripsi' => 'nullable|string',
            'foto' => 'nullable|image|mimes:jpeg,png,jpg,webp|max:3072',
        ]);

        $validated['perlu_resep'] = $request->has('perlu_resep');
        $validated['tersedia'] = $request->has('tersedia');
        $validated['satuan'] = ($validated['satuan'] ?? null) ?: 'Pcs';

        if ($request->hasFile('foto')) {
            if ($produk->foto && Storage::disk('public')->exists($produk->foto)) {
                Storage::disk('public')->delete($produk->foto);
            }
            $path = $request->file('foto')->store('produk_fotos', 'public');
            $validated['foto'] = $path;
        }

        $produk->update($validated);

        return redirect()->route('admin.produk.index')->with('sukses', 'Data produk berhasil diperbarui.');
    }

    public function destroy(Produk $produk): RedirectResponse
    {
        if ($produk->pesananDetails()->exists()) {
            return redirect()->route('admin.produk.index')
                ->with('galat', 'Produk tidak dapat dihapus karena sudah tercatat pada riwayat pesanan.');
        }

        if ($produk->foto && Storage::disk('public')->exists($produk->foto)) {
            Storage::disk('public')->delete($produk->foto);
        }
        $produk->delete();
        return redirect()->route('admin.produk.index')->with('sukses', 'Produk berhasil dihapus.');
    }
}

