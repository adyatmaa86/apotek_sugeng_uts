<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BaseApiController extends Controller
{
    /**
     * Identitas pelanggan UTS (mode tanpa autentikasi penuh).
     * Tetap dipakai sebagai fallback agar aplikasi tetap jalan tanpa login.
     */
    protected const PELANGGAN_UTS = 'pelanggan_uts_01';

    /**
     * Resolusi identitas pelanggan:
     * - Jika request membawa token Sanctum yang valid -> "user_{id}".
     * - Jika tanpa token -> pelanggan_id tetap UTS (ketentuan tugas).
     */
    protected function pelangganId(Request $request): string
    {
        $user = $request->user('sanctum');

        return $user !== null
            ? 'user_' . $user->id
            : self::PELANGGAN_UTS;
    }

    /**
     * Format response sukses seragam (PRD 7.2)
     */
    protected function sukses(mixed $data = null, string $message = 'Operasi berhasil', int $code = 200): JsonResponse
    {
        $response = [
            'status' => 'sukses',
            'code' => (string) $code,
            'message' => $message,
        ];

        if ($data !== null) {
            $response['data'] = $data;
        }

        return response()->json($response, $code);
    }

    /**
     * Format response gagal seragam (PRD 7.2)
     */
    protected function gagal(string $message = 'Terjadi kesalahan', int $code = 400, ?array $errors = null): JsonResponse
    {
        $response = [
            'status' => 'gagal',
            'code' => (string) $code,
            'message' => $message,
        ];

        if ($errors !== null) {
            $response['errors'] = $errors;
        }

        return response()->json($response, $code);
    }
}
