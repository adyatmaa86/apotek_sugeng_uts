<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class RajaOngkirService
{
    protected string $apiKey;
    protected string $baseUrl;
    protected int $originDistrictId; // Default kecamatan apotek: Tegalrejo, Kota Yogyakarta

    public function __construct()
    {
        $this->apiKey = (string) config('services.rajaongkir.api_key', 'sjojZewy641172cd8395717cWZAg8DvX');
        $this->baseUrl = (string) config('services.rajaongkir.base_url', 'https://rajaongkir.komerce.id/api/v1');
        $this->originDistrictId = (int) config('services.rajaongkir.origin_district', 2581); // Default: Tegalrejo, Kota Yogyakarta
    }

    /**
     * Cache hasil API hanya jika TIDAK kosong, agar kegagalan (mis. limit harian
     * habis / API down) tidak ter-cache 24 jam dan mengunci fitur ongkir.
     */
    protected function rememberIfNotEmpty(string $key, int $ttlSeconds, callable $fetch): array
    {
        $cached = Cache::get($key);
        if (is_array($cached) && ! empty($cached)) {
            return $cached;
        }

        $result = $fetch();

        if (! empty($result)) {
            Cache::put($key, $result, $ttlSeconds);
        }

        return $result;
    }

    /**
     * Dapatkan daftar seluruh kota/kabupaten se-Indonesia langsung dari API resmi Komerce RajaOngkir
     * Hasil di-cache dalam waktu 24 jam agar cepat dan tidak membebani limit API
     */
    public function getCities(): array
    {
        return $this->rememberIfNotEmpty('rajaongkir_komerce_all_cities', 2592000, function () {
            try {
                // 1. Ambil 34 provinsi se-Indonesia
                $provResponse = Http::withHeaders([
                    'key' => $this->apiKey,
                ])->timeout(10)->get("{$this->baseUrl}/destination/province");

                if (!$provResponse->successful()) {
                    Log::warning('Gagal mengambil provinsi RajaOngkir Komerce: ' . $provResponse->body());
                    return [];
                }

                $provinces = $provResponse->json('data') ?? [];
                $allCities = [];

                // 2. Loop setiap provinsi untuk mengumpulkan seluruh kota & kabupaten se-Indonesia
                foreach ($provinces as $prov) {
                    $provId = $prov['id'];
                    $provName = $prov['name'];

                    $cityResponse = Http::withHeaders([
                        'key' => $this->apiKey,
                    ])->timeout(10)->get("{$this->baseUrl}/destination/city/{$provId}");

                    if ($cityResponse->successful()) {
                        $cities = $cityResponse->json('data') ?? [];
                        foreach ($cities as $c) {
                            $namaKota = $c['name'];
                            $tipe = str_contains(strtoupper($namaKota), 'KAB') ? 'Kabupaten' : 'Kota';

                            $allCities[] = [
                                'city_id' => (string) $c['id'],
                                'province_id' => (string) $provId,
                                'province' => $provName,
                                'type' => $tipe,
                                'city_name' => $namaKota,
                                'postal_code' => '',
                            ];
                        }
                    }
                }

                // Urutkan abjad kota
                usort($allCities, fn($a, $b) => strcmp($a['city_name'], $b['city_name']));

                return $allCities;
            } catch (\Throwable $e) {
                Log::error('Error getCities Komerce: ' . $e->getMessage());
                return [];
            }
        });
    }

    /**
     * Daftar provinsi (dipakai untuk dropdown pertama)
     */
    public function getProvinces(): array
    {
        return $this->rememberIfNotEmpty('rajaongkir_komerce_provinces', 2592000, function () {
            try {
                $res = Http::withHeaders(['key' => $this->apiKey])->timeout(10)->get("{$this->baseUrl}/destination/province");
                if ($res->successful()) {
                    return $res->json('data') ?? [];
                }
            } catch (\Throwable $e) {
                Log::error('getProvinces error: ' . $e->getMessage());
            }
            return [];
        });
    }

    /**
     * Daftar kota/kabupaten berdasarkan provinsi_id
     */
    public function getCitiesByProvince(int $provinceId): array
    {
        return $this->rememberIfNotEmpty("rajaongkir_komerce_cities_prov_{$provinceId}", 2592000, function () use ($provinceId) {
            try {
                $res = Http::withHeaders(['key' => $this->apiKey])->timeout(10)->get("{$this->baseUrl}/destination/city/{$provinceId}");
                if ($res->successful()) {
                    return $res->json('data') ?? [];
                }
            } catch (\Throwable $e) {
                Log::error('getCitiesByProvince error: ' . $e->getMessage());
            }
            return [];
        });
    }

    /**
     * Daftar kecamatan berdasarkan city_id
     */
    public function getDistrictsByCity(int $cityId): array
    {
        return $this->rememberIfNotEmpty("rajaongkir_komerce_districts_city_{$cityId}", 2592000, function () use ($cityId) {
            try {
                $res = Http::withHeaders(['key' => $this->apiKey])->timeout(10)->get("{$this->baseUrl}/destination/district/{$cityId}");
                if ($res->successful()) {
                    return $res->json('data') ?? [];
                }
            } catch (\Throwable $e) {
                Log::error('getDistrictsByCity error: ' . $e->getMessage());
            }
            return [];
        });
    }

    /**
     * Daftar desa/kelurahan berdasarkan district_id
     */
    public function getVillagesByDistrict(int $districtId): array
    {
        return $this->rememberIfNotEmpty("rajaongkir_komerce_villages_dist_{$districtId}", 2592000, function () use ($districtId) {
            try {
                $res = Http::withHeaders(['key' => $this->apiKey])->timeout(10)->get("{$this->baseUrl}/destination/sub-district/{$districtId}");
                if ($res->successful()) {
                    return $res->json('data') ?? [];
                }
            } catch (\Throwable $e) {
                Log::error('getVillagesByDistrict error: ' . $e->getMessage());
            }
            return [];
        });
    }

    /**
     * Hitung ongkos kirim real-time via API RajaOngkir Komerce
     */
    public function calculateCost(int|string $destinationCityId, int $weightGram = 1000, string $courier = 'jne'): array
    {
        try {
            // Dapatkan kecamatan pertama di dalam kota tujuan untuk perhitungan tarif district
            $districtId = $this->getDistrictIdForCity((int) $destinationCityId);

            $response = Http::asForm()->withHeaders([
                'key' => $this->apiKey,
            ])->timeout(10)->post("{$this->baseUrl}/calculate/domestic-cost", [
                'origin' => $this->originDistrictId,
                'destination' => $districtId,
                'weight' => $weightGram,
                'courier' => strtolower($courier),
            ]);

            if ($response->successful()) {
                $rawResults = $response->json('data') ?? [];
                
                // Format agar cocok dengan kontrak response Flutter
                $costs = [];
                foreach ($rawResults as $item) {
                    $costs[] = [
                        'service' => $item['service'] ?? 'REG',
                        'description' => $item['description'] ?? 'Layanan Pengiriman',
                        'cost' => [
                            [
                                'value' => (int) ($item['cost'] ?? 0),
                                'etd' => str_replace([' day', ' days', ' hari'], '', $item['etd'] ?? '1-2'),
                                'note' => '',
                            ]
                        ]
                    ];
                }

                return [
                    [
                        'code' => $courier,
                        'name' => 'Jalur Nugraha Ekakurir (JNE)',
                        'costs' => $costs,
                    ]
                ];
            } else {
                Log::warning('Komerce calculateCost error response: ' . $response->body());
            }
        } catch (\Throwable $e) {
            Log::error('Komerce calculateCost exception: ' . $e->getMessage());
        }

        return [];
    }

    /**
     * Dapatkan ID kecamatan referensi untuk kota tujuan
     */
    protected function getDistrictIdForCity(int $cityId): int
    {
        $key = "komerce_first_district_for_city_{$cityId}";
        $cached = Cache::get($key);
        if (is_int($cached) && $cached > 0) {
            return $cached;
        }

        try {
            $res = Http::withHeaders([
                'key' => $this->apiKey,
            ])->timeout(8)->get("{$this->baseUrl}/destination/district/{$cityId}");

            if ($res->successful()) {
                $districts = $res->json('data') ?? [];
                if (!empty($districts)) {
                    $districtId = (int) $districts[0]['id'];
                    Cache::put($key, $districtId, 2592000);

                    return $districtId;
                }
            }
        } catch (\Throwable $e) {
            Log::warning("Gagal ambil district kota {$cityId}: " . $e->getMessage());
        }

        return $cityId;
    }
}
