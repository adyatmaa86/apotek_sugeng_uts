<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Gerbang admin khusus API (/api/...).
 * Dipakai bersama auth:sanctum: token wajib milik user dengan is_admin = true.
 */
class AdminApiAuth
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user('sanctum');

        if ($user === null) {
            return response()->json([
                'status' => 'gagal',
                'code' => '401',
                'message' => 'Silakan login terlebih dahulu.',
            ], 401);
        }

        if (! $user->is_admin) {
            return response()->json([
                'status' => 'gagal',
                'code' => '403',
                'message' => 'Hanya akun admin yang boleh mengelola produk via API.',
            ], 403);
        }

        return $next($request);
    }
}
