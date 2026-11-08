<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class AdminAuth
{
    public function handle(Request $request, Closure $next): Response
    {
        if (! Auth::check() || ! Auth::user()->is_admin) {
            if ($request->expectsJson()) {
                return response()->json(['message' => 'Silakan login sebagai admin terlebih dahulu.'], 401);
            }

            return redirect()->guest(route('admin.login'));
        }

        return $next($request);
    }
}
