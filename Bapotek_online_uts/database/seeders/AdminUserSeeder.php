<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        $password = (string) env('SEED_ADMIN_PASSWORD', '');

        // Kredensial lemah (12345678) hanya diizinkan untuk demo lokal.
        // Di lingkungan lain wajib mengisi SEED_ADMIN_PASSWORD sendiri.
        if ($password === '') {
            if (! app()->isLocal()) {
                $this->command?->warn('SEED_ADMIN_PASSWORD belum diisi — akun admin tidak dibuat (bukan lingkungan local).');

                return;
            }

            $password = '12345678';
        }

        $admin = User::query()->firstOrNew([
            'email' => 'admin@apotek.test',
        ]);

        $admin->name = 'Administrator Apotek';
        $admin->is_admin = true;
        $admin->email_verified_at = now();

        if (! $admin->exists) {
            $admin->password = Hash::make($password);
        }

        $admin->save();

        $this->command?->info('Akun admin siap: admin@apotek.test');
    }
}
