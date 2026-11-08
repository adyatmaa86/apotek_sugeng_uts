<?php

namespace App\Services;

use Illuminate\Support\Facades\File;

class PengaturanAplikasi
{
    protected static function getPath(): string
    {
        return storage_path('app/settings.json');
    }

    public static function all(): array
    {
        $path = self::getPath();
        if (!File::exists($path)) {
            return [
                'mode_uts' => false,
            ];
        }

        try {
            $data = json_decode(File::get($path), true);
            return is_array($data) ? $data : ['mode_uts' => false];
        } catch (\Throwable $e) {
            return ['mode_uts' => false];
        }
    }

    public static function isModeUts(): bool
    {
        return (bool) (self::all()['mode_uts'] ?? false);
    }

    public static function setModeUts(bool $status): void
    {
        $settings = self::all();
        $settings['mode_uts'] = $status;

        $dir = dirname(self::getPath());
        if (!File::exists($dir)) {
            File::makeDirectory($dir, 0755, true);
        }

        File::put(self::getPath(), json_encode($settings, JSON_PRETTY_PRINT));
    }
}

