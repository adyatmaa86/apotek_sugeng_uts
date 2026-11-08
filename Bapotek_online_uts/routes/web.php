<?php

use App\Http\Controllers\Admin\AdminAuthController;
use App\Http\Controllers\Admin\AdminAkunController;
use App\Http\Controllers\Admin\AdminKelolaAplikasiController;
use App\Http\Controllers\Admin\AdminKeranjangController;
use App\Http\Controllers\Admin\AdminKurirController;
use App\Http\Controllers\Admin\AdminPesananController;
use App\Http\Controllers\Admin\AdminProdukController;
use App\Http\Controllers\Admin\AdminProfilController;
use App\Http\Controllers\Admin\DashboardController;
use Illuminate\Support\Facades\Route;

// Redirect root ke admin dashboard
Route::get('/', function () {
    return redirect()->route('admin.dashboard');
});

// Admin Panel Routes
Route::prefix('admin')->name('admin.')->group(function () {
    Route::get('login', [AdminAuthController::class, 'showLogin'])->name('login');
    Route::post('login', [AdminAuthController::class, 'login'])
        ->middleware('throttle:5,1')
        ->name('login.submit');

    Route::middleware('admin.auth')->group(function () {
        Route::post('logout', [AdminAuthController::class, 'logout'])->name('logout');

        Route::get('/', [DashboardController::class, 'index'])->name('dashboard');

        // Edit Profil Admin
        Route::get('profil', [AdminProfilController::class, 'edit'])->name('profil.edit');
        Route::put('profil', [AdminProfilController::class, 'update'])->name('profil.update');

        // Kelola Akun Admin
        Route::get('akun-admin', [AdminAkunController::class, 'index'])->name('akun.index');
        Route::post('akun-admin', [AdminAkunController::class, 'store'])->name('akun.store');
        Route::delete('akun-admin/{user}', [AdminAkunController::class, 'destroy'])->name('akun.destroy');

        // Kelola Produk (CRUD)
        Route::resource('produk', AdminProdukController::class)->except(['show']);

        // Kelola Pesanan (Index, Show, Update Status)
        Route::get('pesanan', [AdminPesananController::class, 'index'])->name('pesanan.index');
        Route::get('pesanan/{pesanan}', [AdminPesananController::class, 'show'])->name('pesanan.show');
        Route::patch('pesanan/{pesanan}/status', [AdminPesananController::class, 'updateStatus'])->name('pesanan.updateStatus');

        // Kelola Kurir & Tarif
        Route::get('kurir', [AdminKurirController::class, 'index'])->name('kurir.index');
        Route::post('kurir', [AdminKurirController::class, 'store'])->name('kurir.store');
        Route::put('kurir/{kurir}', [AdminKurirController::class, 'update'])->name('kurir.update');
        Route::delete('kurir/{kurir}', [AdminKurirController::class, 'destroy'])->name('kurir.destroy');

        // Pantau Keranjang
        Route::get('keranjang', [AdminKeranjangController::class, 'index'])->name('keranjang.index');
        Route::delete('keranjang/{keranjang}', [AdminKeranjangController::class, 'destroy'])->name('keranjang.destroy');
        Route::delete('keranjang-clear', [AdminKeranjangController::class, 'clearAll'])->name('keranjang.clearAll');

        // Kelola Aplikasi (Mode UTS)
        Route::get('kelola-aplikasi', [AdminKelolaAplikasiController::class, 'index'])->name('kelola-aplikasi.index');
        Route::post('kelola-aplikasi/toggle', [AdminKelolaAplikasiController::class, 'toggleModeUts'])->name('kelola-aplikasi.toggle');
    });
});
