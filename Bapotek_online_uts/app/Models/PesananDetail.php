<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PesananDetail extends Model
{
    use HasFactory;

    protected $table = 'pesanan_details';

    protected $fillable = [
        'pesanan_id',
        'produk_id',
        'nama_produk',
        'harga_saat_beli',
        'jumlah',
        'subtotal',
        'perlu_resep',
    ];

    protected $casts = [
        'harga_saat_beli' => 'integer',
        'jumlah' => 'integer',
        'subtotal' => 'integer',
        'perlu_resep' => 'boolean',
    ];

    public function pesanan()
    {
        return $this->belongsTo(Pesanan::class, 'pesanan_id');
    }

    public function produk()
    {
        return $this->belongsTo(Produk::class, 'produk_id');
    }
}
