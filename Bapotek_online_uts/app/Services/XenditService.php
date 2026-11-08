<?php

namespace App\Services;

use App\Models\Pesanan;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class XenditService
{
    protected string $secretKey;

    public function __construct()
    {
        $this->secretKey = (string) config('services.xendit.secret_key');
    }

    /**
     * Buat Invoice Pembayaran Xendit
     */
    public function createInvoice(Pesanan $pesanan): ?array
    {
        if ($this->secretKey === '') {
            return $this->mockInvoice($pesanan);
        }

        try {
            $endpoint = 'https://api.xendit.co/v2/invoices';
            
            $payload = [
                'external_id' => $pesanan->nomor_pesanan,
                'amount' => $pesanan->total,
                'description' => "Pembayaran Pesanan Apotek #{$pesanan->nomor_pesanan}",
                'invoice_duration' => 86400, // 24 jam
                'customer' => [
                    'given_names' => $pesanan->nama_penerima,
                ],
                'currency' => 'IDR',
                'items' => $pesanan->details->map(function ($item) {
                    return [
                        'name' => $item->nama_produk,
                        'quantity' => $item->jumlah,
                        'price' => $item->harga_saat_beli,
                    ];
                })->toArray(),
            ];

            // Tambahkan ongkos kirim jika ada
            if ($pesanan->ongkos_kirim > 0) {
                $payload['items'][] = [
                    'name' => 'Ongkos Kirim',
                    'quantity' => 1,
                    'price' => $pesanan->ongkos_kirim,
                ];
            }

            $response = Http::withBasicAuth($this->secretKey, '')
                ->timeout(15)
                ->withHeaders(['Content-Type' => 'application/json'])
                ->post($endpoint, $payload);

            Log::info('Xendit API response: status=' . $response->status() . ' body=' . substr($response->body(), 0, 500));

            if ($response->successful()) {
                $data = $response->json();
                return [
                    'invoice_id' => $data['id'] ?? null,
                    'invoice_url' => $data['invoice_url'] ?? null,
                    'status' => $data['status'] ?? 'PENDING',
                ];
            }

            Log::warning('Xendit invoice creation fallback due to response: ' . $response->body());
        } catch (\Throwable $e) {
            Log::error('Xendit Service Error: ' . $e->getMessage());
        }

        // Fallback simulated invoice jika sandbox offline atau request gagal
        return $this->mockInvoice($pesanan);
    }

    /**
     * Ambil status invoice Xendit berdasarkan ID (server-to-server).
     * Mengembalikan null jika gagal / tidak tersedia.
     */
    public function getInvoice(string $invoiceId): ?array
    {
        if ($this->secretKey === '' || $invoiceId === '') {
            return null;
        }

        try {
            $response = Http::withBasicAuth($this->secretKey, '')
                ->timeout(15)
                ->acceptJson()
                ->get("https://api.xendit.co/v2/invoices/{$invoiceId}");

            if ($response->successful()) {
                return $response->json();
            }

            Log::warning('Xendit getInvoice gagal: ' . substr($response->body(), 0, 300));
        } catch (\Throwable $e) {
            Log::error('Xendit getInvoice error: ' . $e->getMessage());
        }

        return null;
    }

    protected function mockInvoice(Pesanan $pesanan): array
    {
        // URL simulasi pembayaran Xendit (sandbox demo)
        $invoiceId = 'INV-SIM-' . strtoupper(substr(md5($pesanan->nomor_pesanan), 0, 8));
        return [
            'invoice_id' => $invoiceId,
            'invoice_url' => "https://checkout-staging.xendit.co/v2/invoices/{$invoiceId}",
            'status' => 'PENDING',
        ];
    }
}
