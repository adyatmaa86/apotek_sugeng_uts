<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::query()->firstOrNew([
            'email' => 'admin@apotek.test',
        ]);

        $admin->name = 'Administrator Apotek';
        $admin->is_admin = true;
        $admin->email_verified_at = now();

        if (! $admin->exists) {
            $admin->password = Hash::make('12345678');
        }

        $admin->save();

        $this->command?->info('Akun admin siap: admin@apotek.test');
    }
}
