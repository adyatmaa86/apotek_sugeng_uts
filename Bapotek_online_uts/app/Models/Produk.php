<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Produk extends Model
{
    use HasFactory;

    protected $table = 'produks';

    protected $fillable = [
        'nama',
        'harga',
        'kategori',
        'stok',
        'tersedia',
        'deskripsi',
        'foto',
        'perlu_resep',
        'batas_per_pembelian',
        'satuan',
        'golongan',
    ];

    protected $appends = ['foto_url'];

    public function getFotoUrlAttribute(): ?string
    {
        if ($this->foto) {
            return asset('storage/' . $this->foto);
        }
        return null;
    }

    protected $casts = [
        'harga' => 'integer',
        'stok' => 'integer',
        'tersedia' => 'boolean',
        'perlu_resep' => 'boolean',
        'batas_per_pembelian' => 'integer',
    ];

    public function keranjangs()
    {
        return $this->hasMany(Keranjang::class, 'produk_id');
    }

    public function pesananDetails()
    {
        return $this->hasMany(PesananDetail::class, 'produk_id');
    }
}
