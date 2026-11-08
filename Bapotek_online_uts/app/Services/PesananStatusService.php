<?php

namespace App\Services;

use App\Models\Pesanan;
use App\Models\Produk;
use Illuminate\Support\Facades\DB;

class PesananStatusService
{
    public const TRANSISI_SAH = [
        'menunggu_pembayaran' => ['menunggu_konfirmasi', 'dibayar', 'dibatalkan'],
        'menunggu_konfirmasi' => ['dibayar', 'dibatalkan'],
        'dibayar' => ['diproses'],
        'diproses' => ['dikirim'],
        'dikirim' => ['selesai'],
        'selesai' => [],
        'dibatalkan' => [],
    ];

    public function bolehTransisi(string $statusLama, string $statusBaru): bool
    {
        if ($statusLama === $statusBaru) {
            return false;
        }

        return in_array($statusBaru, self::TRANSISI_SAH[$statusLama] ?? [], true);
    }

    public function ubahStatus(Pesanan $pesanan, string $statusBaru): Pesanan
    {
        return DB::transaction(function () use ($pesanan, $statusBaru) {
            /** @var Pesanan $terkunci */
            $terkunci = Pesanan::query()
                ->whereKey($pesanan->getKey())
                ->lockForUpdate()
                ->firstOrFail();

            if ($terkunci->status === $statusBaru) {
                return $terkunci->load(['details', 'kurir']);
            }

            $statusLama = $terkunci->status;

            if (! $this->bolehTransisi($statusLama, $statusBaru)) {
                throw new \DomainException(
                    "Perpindahan status dari '{$statusLama}' ke '{$statusBaru}' tidak sah"
                );
            }

            if ($statusBaru === 'dibatalkan') {
                $terkunci->load('details');

                foreach ($terkunci->details as $item) {
                    $produk = Produk::query()
                        ->whereKey($item->produk_id)
                        ->lockForUpdate()
                        ->first();

                    if ($produk) {
                        $produk->increment('stok', $item->jumlah);
                    }
                }
            }

            $terkunci->status = $statusBaru;
            $terkunci->save();

            return $terkunci->load(['details', 'kurir']);
        });
    }
}
