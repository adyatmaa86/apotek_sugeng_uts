<?php

namespace App\Http\Controllers\Api;

use App\Services\PengaturanAplikasi;
use Illuminate\Http\JsonResponse;

class ConfigController extends BaseApiController
{
    /**
     * Mengembalikan konfigurasi publik yang aman untuk dikonsumsi Flutter.
     * API key sensitif (Xendit, RajaOngkir) TIDAK dikembalikan ke sini.
     */
    public function index(): JsonResponse
    {
        return $this->sukses([
            'google_maps_key' => (string) config('services.google.maps_key', ''),
            'mode_uts' => PengaturanAplikasi::isModeUts(),
        ]);
    }
}
