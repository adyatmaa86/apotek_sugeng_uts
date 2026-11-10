<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Pesanan extends Model
{
    use HasFactory;

    protected $table = 'pesanans';

    protected $fillable = [
        'nomor_pesanan',
        'pelanggan_id',
        'nama_penerima',
        'alamat',
        'kurir_id',
        'ongkos_kirim',
        'subtotal',
        'total',
        'metode_pembayaran',
        'status',
        'nomor_resep',
        'foto_resep',
        'rajaongkir_service',
        'xendit_invoice_id',
        'xendit_payment_url',
        'xendit_status',
    ];

    protected $casts = [
        'ongkos_kirim' => 'integer',
        'subtotal' => 'integer',
        'total' => 'integer',
    ];

    public function kurir()
    {
        return $this->belongsTo(Kurir::class, 'kurir_id');
    }

    public function details()
    {
        return $this->hasMany(PesananDetail::class, 'pesanan_id');
    }

    public function kunciIdempoten()
    {
        return $this->hasOne(KunciIdempoten::class, 'pesanan_id');
    }
}
