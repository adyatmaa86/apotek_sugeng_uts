# Proyek UTS: Toko Online Apotek & Alat Kesehatan
**Mata Kuliah:** Sistem Terdistribusi & Pemrograman Aplikasi Perangkat Bergerak  
**Penyusun:** 
1.Achmad Helmy Aziz Adyatma 24102001
2.Rifqi Bintang Syahputra 24102017
3.Risky Putra Adielia 24102020
4.Muhamad Septiyan 24102035
5.Sandy Agustiya Saputra 24102037
6.Zayyan Muhammad Ihsan Syafatullah 24102039
**Arsitektur:** REST API Laravel (Backend) + Flutter Mobile (Frontend)

---

## 1. Domain Bisnis & Aturan Khas
- **Domain:** Toko Online Apotek & Alat Kesehatan.
- **Aturan Bisnis Utama:**
  1. Produk obat berpenanda **`perlu_resep` = true** wajib menyertakan **Nomor Resep Dokter** saat checkout. Jika dikosongkan, pesanan **ditolak oleh server** dengan kode status `422 Unprocessable Content`.
  2. Pembelian melebihi batas **`batas_per_pembelian`** ditolak server dengan kode status `409 Conflict`.
  3. Pembelian item yang kehabisan stok (`stok` = 0) ditolak server dengan kode status `409 Conflict`.
  4. Seluruh perhitungan subtotal, ongkos kirim, dan total sepenuhnya ditentukan oleh server Laravel (Single Source of Truth).

---

## 2. Cara Menjalankan Backend Laravel (`Bapotek_online_uts`)

1. Masuk ke folder backend:
   ```bash
   cd Bapotek_online_uts
   ```
2. Pastikan file `.env` sudah terkonfigurasi dengan database MySQL lokal (`apotek_online_uts`).
3. Jalankan migrasi dan seeder data awal:
   ```bash
   php artisan migrate:fresh --seed
   ```
4. Jalankan server Laravel:
   ```bash
   php artisan serve --port=8000
   ```

---

## 3. Cara Menjalankan Aplikasi Mobile Flutter (`apotek_online_uts`)

1. Masuk ke folder Flutter:
   ```bash
   cd apotek_online_uts
   ```
2. Jalankan perintah dependensi (jika baru pertama kali / update packages):
   ```bash
   flutter pub get
   ```
3. Jalankan aplikasi pada Emulator Android:
   ```bash
   flutter run
   ```

### Tempat Mengubah Alamat Server:
- File: `apotek_online_uts/lib/services/layanan_api.dart`
- Konstanta: `baseUrl`
  - Default Emulator Android: `http://10.0.2.2:8000/api` (karena `localhost` merujuk ke internal emulator itu sendiri).
  - Untuk Web / Windows App / HP Fisik via Wi-Fi: ubah ke `http://127.0.0.1:8000/api` atau `http://<IP-LAN-Laptop>:8000/api`.

---

## 4. Pengenal Pelanggan (Statis Token)
- Menggunakan `pelanggan_id = pelanggan_uts_01` secara terpadu antara Laravel dan Flutter untuk mempermudah penilaian dan pengujian dosen penguji.

---

## 5. Ringkasan Endpoint REST API

| No | Metode | Jalur Endpoint | Keterangan |
|---|---|---|---|
| 1 | `GET` | `/api/produk` | Daftar katalog produk obat & alkes (?kategori= & ?cari=) |
| 2 | `GET` | `/api/produk/{id}` | Rincian detail produk spesifik |
| 3 | `POST` | `/api/produk` | Tambah produk baru (Admin CRUD) |
| 4 | `PUT` | `/api/produk/{id}` | Perbarui data produk |
| 5 | `DELETE`| `/api/produk/{id}` | Hapus produk (409 bila terkait pesanan aktif) |
| 6 | `GET` | `/api/keranjang` | Daftar isi keranjang & subtotal dari server |
| 7 | `POST` | `/api/keranjang` | Tambah item ke keranjang (cek stok & limit beli) |
| 8 | `PUT` | `/api/keranjang/{id}` | Ubah jumlah item keranjang |
| 9 | `DELETE`| `/api/keranjang/{id}` | Hapus item dari keranjang |
| 10 | `GET` | `/api/kurir` | Daftar kurir & tarif wilayah antar apotek |
| 11 | `POST` | `/api/checkout` | Buat pesanan (Wajib header `X-Kunci-Idempoten` & validasi resep) |
| 12 | `GET` | `/api/pesanan` | Riwayat pesanan pelanggan |
| 13 | `GET` | `/api/pesanan/{id}` | Detail pesanan dengan snapshot harga saat beli |
| 14 | `PATCH`| `/api/pesanan/{id}/status` | Ubah status pesanan (siklus transaksi sah) |
| 15 | `GET` | `/api/rajaongkir/kota` | **Fitur Unggulan**: Daftar kota RajaOngkir |
| 16 | `POST` | `/api/rajaongkir/ongkir` | **Fitur Unggulan**: Hitung tarif real-time RajaOngkir |
| 17 | `POST` | `/api/xendit/callback` | **Fitur Unggulan**: Webhook status transaksi Xendit |

---

## 6. Alur Status Transaksi & Idempotensi
1. **Siklus Status:**
   `menunggu_pembayaran` ➔ `menunggu_konfirmasi` ➔ `dibayar` ➔ `diproses` ➔ `dikirim` ➔ `selesai` (atau `dibatalkan` dari 2 status awal).
2. **Idempotensi:**
   Header `X-Kunci-Idempoten` dibuat unik via UUID di Flutter saat membuka sesi checkout. Jika terjadi kendala jaringan dan pengguna menekan tombol lagi, server mengenali kunci dan mengembalikan pesanan yang sama tanpa memotong stok ganda.

---

## 7. Tautan Video Demo & Kelengkapan
- **Video Demo Aplikasi & Pengujian 5 Jenis Galat:** `[Tautan Video Demo YouTube / GDrive]`
- **Dokumentasi PDF Endpoint API:** Terlampir pada berkas PDF tugas.
