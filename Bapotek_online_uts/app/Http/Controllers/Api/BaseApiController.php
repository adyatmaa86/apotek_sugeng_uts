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
     * - Jika tanpa token (Guest) -> diidentifikasi dari header X-Guest-Id atau alamat IP klien.
     */
    protected function pelangganId(Request $request): string
    {
        $user = $request->user('sanctum');

        if ($user !== null) {
            return 'user_' . $user->id;
        }

        // Mode Guest Murni: gunakan header X-Guest-Id bila dikirim, atau fallback hash IP
        $guestId = $request->header('X-Guest-Id');
        if (! empty($guestId)) {
            return 'guest_' . preg_replace('/[^a-zA-Z0-9_-]/', '', $guestId);
        }

        return 'guest_' . substr(md5($request->ip() . $request->userAgent()), 0, 16);
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
