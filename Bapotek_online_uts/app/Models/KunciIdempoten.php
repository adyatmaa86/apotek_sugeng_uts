<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class KunciIdempoten extends Model
{
    use HasFactory;

    protected $table = 'kunci_idempotens';

    protected $fillable = [
        'kunci',
        'pesanan_id',
    ];

    public function pesanan()
    {
        return $this->belongsTo(Pesanan::class, 'pesanan_id');
    }
}
