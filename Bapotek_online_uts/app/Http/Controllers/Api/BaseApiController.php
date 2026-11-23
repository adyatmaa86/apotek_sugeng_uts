<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BaseApiController extends Controller
{
    /**
     * Resolusi identitas pelanggan:
     * - Jika request membawa token Sanctum yang valid -> "user_{id}".
     * - Jika tanpa token (Guest) -> "guest_" + HMAC(IP | User-Agent, APP_KEY).
     *
     * Header X-Guest-Id TIDAK dipercaya lagi: identitas tamu diturunkan dari
     * klien yang tidak bisa dipalsukan pihak lain tanpa mengetahui APP_KEY.
     */
    protected function pelangganId(Request $request): string
    {
        $user = $request->user('sanctum');

        if ($user !== null) {
            return 'user_' . $user->id;
        }

        $bahan = $request->ip() . '|' . $request->userAgent();

        return 'guest_' . substr(hash_hmac('sha256', $bahan, (string) config('app.key')), 0, 16);
    }

    /**
     * Cek kepemilikan baris milik pelanggan (404/403 sebelum operasi apa pun).
     */
    protected function milikSaya(Request $request, string $pelangganId): bool
    {
        return hash_equals($pelangganId, $this->pelangganId($request));
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
