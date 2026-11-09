# Proyek UTS: Toko Online Apotek & Alat Kesehatan
**Nama Kelompok:** Pandawa + 1  
**Mata Kuliah:** Sistem Terdistribusi & Pemrograman Aplikasi Perangkat Bergerak  
**Arsitektur:** REST API Laravel (Backend) + Flutter Mobile (Frontend)

## 1. Tim Penyusun

| No | Nama Mahasiswa | NIM | Peran |
|:--:|:--------------:|:---:|:-----:|
| 1 | Achmad Helmy Aziz Adyatma | 24102001 | Project Manager |
| 2 | Rifqi Bintang Syahputra | 24102017 | Backend Developer |
| 3 | Risky Putra Adielia | 24102020 | Frontend Developer |
| 4 | Muhamad Septiyan | 24102035 | UI/UX Designer |
| 5 | Sandy Agustiya Saputra | 24102037 | Frontend Developer |
| 6 | Zayyan Muhammad Ihsan Syafatullah | 24102039 | Backend Developer |

---

## 2. Domain Bisnis & Aturan Khas
- **Domain:** Toko Online Apotek & Alat Kesehatan.
- **Aturan Bisnis Utama:**
  1. Produk obat berpenanda **`perlu_resep` = true** wajib menyertakan **Nomor Resep Dokter** saat checkout. Jika dikosongkan, pesanan **ditolak oleh server** dengan kode status `422 Unprocessable Content`.
  2. Pembelian melebihi batas **`batas_per_pembelian`** ditolak server dengan kode status `409 Conflict`.
  3. Pembelian item yang kehabisan stok (`stok` = 0) ditolak server dengan kode status `409 Conflict`.
  4. Seluruh perhitungan subtotal, ongkos kirim, dan total sepenuhnya ditentukan oleh server Laravel (Single Source of Truth).

---

## 3. Cara Menjalankan Backend Laravel (`Bapotek_online_uts`)

1. Masuk ke folder backend:
   ```bash
   cd Bapotek_online_uts
   ```
2. Install dependensi PHP via Composer:
   ```bash
   composer install
   ```
3. Salin file konfigurasi environment:
   ```bash
   cp .env.example .env
   ```
4. Generate application key:
   ```bash
   php artisan key:generate
   ```
5. Pastikan file `.env` sudah terkonfigurasi dengan database MySQL lokal (`apotek_online_uts`):
   ```env
   DB_DATABASE=apotek_online_uts
   DB_USERNAME=root
   DB_PASSWORD=
   ```
6. Jalankan migrasi dan seeder data awal:
   ```bash
   php artisan migrate:fresh --seed
   ```
7. Install dependensi JavaScript dan build aset:
   ```bash
   npm install
   npm run build
   ```
8. Jalankan server Laravel:
   ```bash
   php artisan serve --port=8000
   ```

---

## 4. Cara Menjalankan Aplikasi Mobile Flutter (`apotek_online_uts`)

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
- Getter: `baseUrl` (baris 14-25)

---

## 5. Alamat Server Saat Pengembangan & Alasan Penggunaan
- **Alamat yang Digunakan:** `http://192.168.1.6:8000/api`
- **Alasan Pemilihan:**
  - Aplikasi diuji dan dijalankan langsung menggunakan **perangkat smartphone Android fisik (Real Device)** yang terhubung dalam satu jaringan Wi-Fi/LAN lokal dengan laptop server Laravel.
  - Dengan IP LAN lokal `192.168.1.6`, smartphone fisik dapat langsung berkomunikasi dengan REST API Laravel tanpa hambatan firewall localhost.
- **Panduan Pengujian untuk Dosen / Penguji:**
  - **Jika Menggunakan Emulator Android Resmi (AVD):** Ganti `baseUrl` ke `http://10.0.2.2:8000/api` (karena IP `10.0.2.2` adalah perutean alias khusus virtual router emulator Android untuk mengakses `localhost` mesin host laptop).
  - **Jika Menggunakan Desktop Windows / Web / iOS Simulator:** Gunakan `http://127.0.0.1:8000/api`.

---

## 6. Akun Uji Coba Penguji (Demo Account & Mode Guest)
- **Mode Guest Murni:** Saat aplikasi Flutter pertama kali dibuka tanpa login, pengguna berstatus sebagai **Tamu (Guest)** dengan keranjang belanja bersih mandiri.
- **Akun Demo Penguji (Opsi Login):** Penguji dapat langsung masuk melalui menu **Akun Saya ➔ Masuk / Daftar Akun** menggunakan kredensial statis berikut:
  - **Email:** `uts@apotek.test`
  - **Password:** `12345678`
  - **Nama Profil:** `Ceo Adyatma86`
- **Data Statis yang Terhubung:** Setelah login dengan akun demo ini, sistem otomatis memuat 3 riwayat pesanan awal (status: `menunggu_pembayaran`, `dibayar`, dan `selesai` via Xendit) yang telah disediakan di database seeder.

---

## 7. Daftar Ringkas Endpoint REST API & Tautan Dokumentasi

> **Tautan Dokumentasi Lengkap:**  
> Rincian spesifikasi skema request, response JSON, dan parameter pengujian lengkap dapat dilihat pada:
> - **Dokumentasi PDF Lengkap:** Terlampir pada berkas PDF tugas UTS (`Dokumentasi_API_Apotek_Sugeng.pdf`).
> - **Collection / Uji Endpoint:** Sesuai standar routing di `Bapotek_online_uts/routes/api.php`.

### Ringkasan Tabel Endpoint:

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

## 8. Alur Status Transaksi & Idempotensi
1. **Siklus Status:**
   `menunggu_pembayaran` ➔ `menunggu_konfirmasi` ➔ `dibayar` ➔ `diproses` ➔ `dikirim` ➔ `selesai` (atau `dibatalkan` dari 2 status awal).
2. **Idempotensi:**
   Header `X-Kunci-Idempoten` dibuat unik via UUID di Flutter saat membuka sesi checkout. Jika terjadi kendala jaringan dan pengguna menekan tombol lagi, server mengenali kunci dan mengembalikan pesanan yang sama tanpa memotong stok ganda.

---

## 9. Kelengkapan
- **Dokumentasi PDF Endpoint API:** Terlampir pada berkas PDF tugas.

---

## 10. Pernyataan Pemanfaatan Kecerdasan Buatan (AI Usage Statement)

Sebagai bentuk transparansi akademik, proyek ini memanfaatkan kecerdasan buatan (*Artificial Intelligence* / AI) sebagai sarana asistensi dan akselerasi pengembangan (*AI-assisted development*):

### 10.1. Alat AI yang Digunakan
* **Google Gemini / Antigravity Agentic Assistant**: Digunakan sebagai mitra diskusi (*pair programmer*), asisten perancangan sistem, serta analisis galat.
* **OpenCode**: Digunakan untuk penelusuran galat (*debugging*), analisis pesan *error*, dan perbaikan kendala pada kode program.

### 10.2. Ruang Lingkup Pemanfaatan AI
1. **Brainstorming & Arsitektur Domain:**
   * Diskusi pemodelan aturan bisnis khusus apotek (validasi `perlu_resep`, batas beli per item, dan penanganan status transaksi).
   * Asistensi formulasi konsep idempotensi transaksi menggunakan header `X-Kunci-Idempoten` dan UUID.
2. **Asistensi Koding & Pembuatan Boilerplate:**
   * Pembuatan struktur dasar skema migrasi basis data, seeder katalog obat awal, dan resource transformer pada Laravel.
   * Penyusunan template *model*, *service* HTTP client, serta *state management* antarmuka di Flutter.
3. **Debugging & Penanganan Galat:**
   * Bantuan analisis pesan galat HTTP (`409 Conflict`, `422 Unprocessable Content`, `401 Unauthorized`).
   * Pemeriksaan skenario simulasi penolakan sistem (5 variasi galat) agar sesuai standar penilaian UTS.
4. **Dokumentasi Teknis:**
   * Bantuan penyusunan dan perapian dokumen teknis, tabel endpoint REST API, serta representasi skema relasi ERD Notasi Peter Chen.

### 10.3. Tanggung Jawab & Integritas Akademik
* Pemanfaatan AI bersifat sebagai **alat bantu asistensi**, bukan pengganti pemahaman konseptual.
* Seluruh integrasi API pihak ketiga (Google Sign-In, Xendit Gateway, RajaOngkir), konfigurasi lingkungan, pengujian fungsional di emulator dan server lokal, serta kode final telah dipelajari, divalidasi, dan **dipertanggungjawabkan sepenuhnya oleh tim penyusun**.

