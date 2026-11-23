<?php

namespace Tests\Feature;

use App\Models\Produk;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Gerbang keamanan endpoint tulis produk (Mode UTS):
 * - tamu      -> 401
 * - user non  -> 403
 * - admin     -> boleh
 * - baca      -> tetap publik untuk katalog
 */
class ProdukAdminApiTest extends TestCase
{
    use RefreshDatabase;

    private function payloadProduk(array $tambahan = []): array
    {
        return array_merge([
            'nama' => 'Paracetamol 500mg',
            'harga' => 5000,
            'kategori' => 'Obat',
            'stok' => 10,
            'batas_per_pembelian' => 5,
        ], $tambahan);
    }

    public function test_tamu_tidak_bisa_menulis_produk(): void
    {
        $this->postJson('/api/produk', $this->payloadProduk())->assertStatus(401);

        $this->assertSame(0, Produk::count());
    }

    public function test_pengguna_non_admin_ditolak_menulis_produk(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/produk', $this->payloadProduk())->assertStatus(403);
        $this->deleteJson('/api/produk/1')->assertStatus(403);

        $this->assertSame(0, Produk::count());
    }

    public function test_admin_bisa_menulis_mengubah_dan_menghapus_produk(): void
    {
        Sanctum::actingAs(User::factory()->create(['is_admin' => true]));

        $id = $this->postJson('/api/produk', $this->payloadProduk())
            ->assertStatus(201)
            ->json('data.id');

        $this->putJson("/api/produk/{$id}", ['harga' => 6000])->assertOk();
        $this->assertSame(6000, Produk::find($id)->harga);

        $this->deleteJson("/api/produk/{$id}")->assertOk();
        $this->assertNull(Produk::find($id));
    }

    public function test_pembacaan_produk_tetap_publik(): void
    {
        $produk = Produk::create($this->payloadProduk([
            'tersedia' => true,
            'perlu_resep' => false,
            'satuan' => 'Strip',
            'deskripsi' => 'Obat bebas',
        ]));

        $this->getJson('/api/produk')->assertOk();
        $this->getJson("/api/produk/{$produk->id}")->assertOk();
    }
}
