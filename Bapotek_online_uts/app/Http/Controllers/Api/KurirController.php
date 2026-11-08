<?php

namespace App\Http\Controllers\Api;

use App\Models\Kurir;
use Illuminate\Http\JsonResponse;

class KurirController extends BaseApiController
{
    /**
     * GET /api/kurir
     * Daftar kurir / wilayah antar internal apotek beserta tarif (PRD 7.1)
     */
    public function index(): JsonResponse
    {
        $kurirs = Kurir::orderBy('tarif', 'asc')->get();

        return $this->sukses($kurirs, 'Daftar kurir dan tarif berhasil diambil', 200);
    }
}
