<?php

namespace App\Http\Controllers\Api;

use App\Models\Produk;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ProdukController extends BaseApiController
{
    /**
     * GET /api/produk
     * Mendukung ?kategori=, ?cari=, ?page=, dan ?per_page= (Paginasi Server / Infinite Scroll)
     */
    public function index(Request $request): JsonResponse
    {
        $query = Produk::query();

        if ($request->filled('kategori') && $request->kategori !== 'Semua') {
            $query->where('kategori', $request->kategori);
        }

        if ($request->filled('cari')) {
            $cari = $request->cari;
            $query->where(function ($q) use ($cari) {
                $q->where('nama', 'like', "%{$cari}%")
                  ->orWhere('deskripsi', 'like', "%{$cari}%");
            });
        }

        $query->orderBy('id', 'desc');

        // Jika klien meminta seluruh data tanpa paginasi (misal per_page=all atau -1)
        if ($request->input('per_page') === 'all' || $request->input('per_page') == -1) {
            $produks = $query->get();
            return response()->json([
                'success' => true,
                'message' => 'Daftar produk berhasil diambil',
                'data' => $produks,
                'pagination' => [
                    'current_page' => 1,
                    'last_page' => 1,
                    'per_page' => $produks->count(),
                    'total' => $produks->count(),
                    'has_more' => false,
                ],
            ], 200);
        }

        // Paginasi standar per halaman (default 8 produk per permintaan)
        $perPage = (int) $request->input('per_page', 8);
        $paginator = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'message' => 'Daftar produk berhasil diambil',
            'data' => $paginator->items(),
            'pagination' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'has_more' => $paginator->hasMorePages(),
            ],
        ], 200);
    }

    /**
     * GET /api/produk/{id}
     * 404 bila tidak ditemukan
     */
    public function show(string|int $id): JsonResponse
    {
        $produk = Produk::find($id);

        if (!$produk) {
            return $this->gagal('Produk tidak ditemukan', 404);
        }

        return $this->sukses($produk, 'Rincian produk berhasil diambil', 200);
    }

    /**
     * POST /api/produk
     * 201 bila berhasil, 422 bila validasi gagal
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'nama' => 'required|string|max:255',
            'harga' => 'required|integer|min:1',
            'kategori' => 'required|string|max:100',
            'stok' => 'required|integer|min:0',
            'tersedia' => 'boolean',
            'deskripsi' => 'nullable|string',
            'perlu_resep' => 'boolean',
            'batas_per_pembelian' => 'required|integer|min:1',
            'satuan' => 'nullable|string',
            'golongan' => 'nullable|string',
        ], [
            'nama.required' => 'Nama produk wajib diisi',
            'harga.required' => 'Harga produk wajib diisi',
            'harga.min' => 'Harga harus lebih besar dari 0',
            'kategori.required' => 'Kategori wajib dipilih',
            'stok.required' => 'Jumlah stok wajib diisi',
            'stok.min' => 'Stok tidak boleh negatif',
            'batas_per_pembelian.required' => 'Batas kuantitas per pembelian wajib diisi',
            'batas_per_pembelian.min' => 'Batas per pembelian minimal 1',
        ]);

        if ($validator->fails()) {
            return $this->gagal('Validasi gagal', 422, $validator->errors()->toArray());
        }

        $data = $validator->validated();
        $data['tersedia'] = $request->boolean('tersedia', true);
        $data['perlu_resep'] = $request->boolean('perlu_resep', false);

        $produk = Produk::create($data);

        return $this->sukses($produk, 'Produk berhasil ditambahkan', 201);
    }

    /**
     * PUT /api/produk/{id}
     * 200 bila berhasil, 404 bila tidak ditemukan
     */
    public function update(Request $request, string|int $id): JsonResponse
    {
        $produk = Produk::find($id);

        if (!$produk) {
            return $this->gagal('Produk tidak ditemukan', 404);
        }

        $validator = Validator::make($request->all(), [
            'nama' => 'sometimes|required|string|max:255',
            'harga' => 'sometimes|required|integer|min:1',
            'kategori' => 'sometimes|required|string|max:100',
            'stok' => 'sometimes|required|integer|min:0',
            'tersedia' => 'sometimes|boolean',
            'deskripsi' => 'nullable|string',
            'perlu_resep' => 'sometimes|boolean',
            'batas_per_pembelian' => 'sometimes|required|integer|min:1',
            'satuan' => 'nullable|string',
            'golongan' => 'nullable|string',
        ], [
            'nama.required' => 'Nama produk wajib diisi',
            'harga.min' => 'Harga harus lebih besar dari 0',
            'stok.min' => 'Stok tidak boleh negatif',
        ]);

        if ($validator->fails()) {
            return $this->gagal('Validasi gagal', 422, $validator->errors()->toArray());
        }

        $produk->update($validator->validated());

        return $this->sukses($produk, 'Produk berhasil diperbarui', 200);
    }

    /**
     * DELETE /api/produk/{id}
     * 409 bila produk masih tercatat pada riwayat pesanan mana pun
     */
    public function destroy(string|int $id): JsonResponse
    {
        $produk = Produk::find($id);

        if (!$produk) {
            return $this->gagal('Produk tidak ditemukan', 404);
        }

        if ($produk->pesananDetails()->exists()) {
            return $this->gagal('Produk tidak dapat dihapus karena sudah tercatat pada riwayat pesanan', 409);
        }

        $produk->delete();

        return $this->sukses(null, 'Produk berhasil dihapus', 200);
    }
}
