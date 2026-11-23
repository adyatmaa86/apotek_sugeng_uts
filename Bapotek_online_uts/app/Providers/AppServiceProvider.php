<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Pagination\Paginator;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Paginator::defaultView('pagination.admin');

        // Batasi percobaan autentikasi API (login/register/google) per IP
        // agar brute-force kredensial dan pembuatan akun massal tidak mungkin.
        RateLimiter::for('api-auth', function (Request $request) {
            return Limit::perMinute(10)->by(strtolower((string) $request->ip()));
        });
    }
}
