<?php

namespace App\Http\Controllers\Api;

use App\Models\Keranjang;
use App\Models\User;
use Firebase\JWT\ExpiredException;
use Firebase\JWT\JWK;
use Firebase\JWT\JWT;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rules\Password;
use Throwable;

class AuthController extends BaseApiController
{
    /**
     * POST /api/auth/register
     * Daftar akun pembeli baru (email + password).
     */
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:users,email',
            'password' => ['required', 'confirmed', Password::min(8)],
        ], [
            'name.required' => 'Nama wajib diisi',
            'email.required' => 'Email wajib diisi',
            'email.email' => 'Format email tidak valid',
            'email.unique' => 'Email sudah terdaftar',
            'password.required' => 'Password wajib diisi',
            'password.confirmed' => 'Konfirmasi password tidak cocok',
            'password.min' => 'Password minimal 8 karakter',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => $validated['password'], // otomatis ter-hash via cast
        ]);

        return $this->sukses(
            $this->bentukSesi($user, 'register'),
            'Pendaftaran berhasil',
            201,
        );
    }

    /**
     * POST /api/auth/login
     * Login pembeli dengan email + password.
     */
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ], [
            'email.required' => 'Email wajib diisi',
            'password.required' => 'Password wajib diisi',
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (! $user || ! password_verify($validated['password'], (string) $user->password)) {
            return $this->gagal('Email atau password salah', 401);
        }

        return $this->sukses($this->bentukSesi($user, 'login'), 'Login berhasil');
    }

    /**
     * POST /api/auth/google
     * Login / daftar otomatis lewat Google Sign-In.
     * Klien mengirim id_token dari Google; server memverifikasinya
     * langsung ke Google (JWKS) sehingga tidak bisa dipalsukan klien.
     */
    public function google(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'id_token' => 'required|string',
        ], [
            'id_token.required' => 'ID token Google wajib dikirim',
        ]);

        $clientId = (string) config('services.google.client_id');

        if ($clientId === '') {
            return $this->gagal(
                'Server belum mengonfigurasi GOOGLE_CLIENT_ID. Isi di .env server terlebih dahulu.',
                503,
            );
        }

        try {
            $payload = $this->verifikasiGoogleIdToken($validated['id_token'], $clientId);
        } catch (ExpiredException) {
            return $this->gagal('Sesi Google sudah kedaluwarsa, silakan coba lagi', 401);
        } catch (Throwable $e) {
            Log::warning('Verifikasi Google ID token gagal: ' . $e->getMessage());

            return $this->gagal('Token Google tidak valid', 401);
        }

        $user = User::updateOrCreate(
            ['google_id' => $payload['sub']],
            [
                'name' => $payload['name'] ?? 'Pengguna Google',
                'email' => $payload['email'],
            ],
        );

        return $this->sukses($this->bentukSesi($user, 'google'), 'Login Google berhasil');
    }

    /**
     * GET /api/auth/me — profil pengguna yang sedang login.
     */
    public function me(Request $request): JsonResponse
    {
        return $this->sukses($request->user(), 'Profil berhasil diambil');
    }

    /**
     * POST /api/auth/logout — cabut token yang sedang dipakai.
     */
    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->currentAccessToken()?->delete();

        // Keranjang TIDAK dihapus saat logout: isi keranjang akun tetap
        // tersimpan di pelanggan_id "user_{id}", dan barang yang ditambahkan
        // tamu tersimpan di pelanggan_id UTS. Saat login berikutnya,
        // gabungkanKeranjang() menggabungkan keduanya.

        return $this->sukses(null, 'Logout berhasil');
    }

    /**
     * POST /api/auth/profil — perbarui profil pengguna yang sedang login.
     * Mendukung unggah foto profil (multipart/form-data, field "foto").
     */
    public function updateProfil(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'foto' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:4096',
        ], [
            'foto.image' => 'Berkas yang diunggah harus berupa gambar',
            'foto.mimes' => 'Format foto harus jpg, jpeg, png, atau webp',
            'foto.max' => 'Ukuran foto maksimal 4 MB',
        ]);

        $user = $request->user();

        if ($request->hasFile('foto')) {
            // Hapus foto lama agar storage tidak menumpuk.
            if ($user->foto && Storage::disk('public')->exists($user->foto)) {
                Storage::disk('public')->delete($user->foto);
            }

            $user->foto = $request->file('foto')->store('profil', 'public');
            $user->save();
        }

        $user->refresh();

        return $this->sukses($user, 'Profil berhasil diperbarui');
    }

    /**
     * Bentuk payload sesi: token Sanctum + data user.
     * Sebelum sesi dibentuk, keranjang mode tamu dipindahkan ke akun
     * sehingga barang yang ditambahkan sebelum login tidak hilang.
     */
    protected function bentukSesi(User $user, string $perangkat): array
    {
        $this->gabungkanKeranjang(self::PELANGGAN_UTS, 'user_' . $user->id);

        $user->refresh();

        return [
            'token' => $user->createToken($perangkat)->plainTextToken,
            'user' => $user,
        ];
    }

    /**
     * Pindahkan isi keranjang dari satu pelanggan_id ke pelanggan_id lain.
     * Bila produk yang sama sudah ada di keranjang tujuan, jumlahnya digabung.
     */
    protected function gabungkanKeranjang(string $dariId, string $keId): void
    {
        if ($dariId === $keId) {
            return;
        }

        $items = Keranjang::where('pelanggan_id', $dariId)->get();

        foreach ($items as $item) {
            $tujuan = Keranjang::where('pelanggan_id', $keId)
                ->where('produk_id', $item->produk_id)
                ->first();

            if ($tujuan) {
                $tujuan->jumlah += $item->jumlah;
                $tujuan->save();
                $item->delete();
            } else {
                $item->pelanggan_id = $keId;
                $item->save();
            }
        }
    }

    /**
     * Verifikasi id_token Google secara server-to-server:
     * 1. Ambil kunci publik resmi Google (JWKS), di-cache 1 jam.
     * 2. Decode + verifikasi tanda tangan, iss, aud, dan exp.
     */
    protected function verifikasiGoogleIdToken(string $idToken, string $clientId): array
    {
        $jwks = Cache::remember('google_jwks', 3600, function () {
            $res = Http::timeout(10)->get('https://www.googleapis.com/oauth2/v3/certs');

            if (! $res->successful()) {
                throw new \RuntimeException('Gagal mengambil kunci publik Google (JWKS)');
            }

            return $res->json();
        });

        $payload = JWT::decode($idToken, JWK::parseKeySet($jwks));

        if (($payload->iss ?? '') !== 'accounts.google.com' && ($payload->iss ?? '') !== 'https://accounts.google.com') {
            throw new \RuntimeException('Issuer tidak dikenal');
        }

        if (! in_array($clientId, (array) ($payload->aud ?? []), true)) {
            throw new \RuntimeException('Audience tidak cocok dengan GOOGLE_CLIENT_ID');
        }

        return (array) $payload;
    }
}
