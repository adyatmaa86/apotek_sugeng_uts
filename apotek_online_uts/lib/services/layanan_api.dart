import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/keranjang_model.dart';
import '../models/kurir_model.dart';
import '../models/pesanan_model.dart';
import '../models/produk_model.dart';
import '../utils/app_state.dart';

class LayananApi {
  static String get baseUrl {
    const dariEnvironment = String.fromEnvironment('API_BASE_URL');
    if (dariEnvironment.isNotEmpty) {
      return dariEnvironment;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.1.6:8000/api';
    }

    return 'http://192.168.1.6:8000/api';
  }

  static const Duration timeoutDuration = Duration(seconds: 10);

  /// Token Sanctum sesi login pembeli (null = mode UTS tanpa login).
  static String? _authToken;

  static void setToken(String? token) {
    _authToken = (token != null && token.isNotEmpty) ? token : null;
  }

  /// Header standar + Bearer token bila sedang login.
  static Map<String, String> _headersAuth([Map<String, String>? dasar]) {
    final h = <String, String>{'Accept': 'application/json', ...?dasar};
    final token = _authToken;
    if (token != null) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ==================== AUTENTIKASI (Sanctum) ====================

  /// POST /auth/register -> {token, user}
  static Future<Map<String, dynamic>> registerAkun({
    required String nama,
    required String email,
    required String password,
  }) async {
    return _kirimAuth(
      Uri.parse('$baseUrl/auth/register'),
      body: {
        'name': nama,
        'email': email,
        'password': password,
        'password_confirmation': password,
      },
    );
  }

  /// POST /auth/login -> {token, user}
  static Future<Map<String, dynamic>> loginEmail({
    required String email,
    required String password,
  }) async {
    return _kirimAuth(
      Uri.parse('$baseUrl/auth/login'),
      body: {'email': email, 'password': password},
    );
  }

  /// POST /auth/google -> {token, user}
  static Future<Map<String, dynamic>> loginGoogle(String idToken) async {
    return _kirimAuth(
      Uri.parse('$baseUrl/auth/google'),
      body: {'id_token': idToken},
    );
  }

  /// POST /auth/logout — cabut token di server.
  static Future<void> logoutAkun() async {
    try {
      await http
          .post(
            Uri.parse('$baseUrl/auth/logout'),
            headers: _headersAuth(),
          )
          .timeout(timeoutDuration);
    } catch (_) {
      // Logout lokal tetap dilakukan walau server gagal dijangkau.
    }
  }

  /// POST /auth/profil — unggah foto profil (multipart/form-data).
  /// Mengembalikan data user terbaru dari server.
  static Future<Map<String, dynamic>> perbaruiProfilAkun(
    String jalurFoto,
  ) async {
    try {
      final permintaan = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/profil'),
      )
        ..headers.addAll(_headersAuth())
        ..files.add(
          await http.MultipartFile.fromPath('foto', jalurFoto),
        );

      final respons = await permintaan.send().timeout(timeoutDuration);
      final body = await respons.stream.bytesToString();
      final data = _prosesResponse(http.Response(
        body,
        respons.statusCode,
        headers: respons.headers,
        request: permintaan,
      ));

      if (data is! Map<String, dynamic>) {
        throw InfoGalat(
          jenis: JenisGalat.galatServer,
          pesan: 'Respons profil tidak sesuai',
        );
      }
      return data;
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  /// Kirim request auth, validasi, dan kembalikan data {token, user}.
  static Future<Map<String, dynamic>> _kirimAuth(
    Uri uri, {
    required Map<String, String> body,
  }) async {
    try {
      final res = await http
          .post(
            uri,
            headers: _headersAuth({'Content-Type': 'application/json'}),
            body: jsonEncode(body),
          )
          .timeout(timeoutDuration);
      final data = _prosesResponse(res);
      if (data is! Map<String, dynamic> || data['token'] == null) {
        throw InfoGalat(
          jenis: JenisGalat.galatServer,
          pesan: 'Respons autentikasi tidak sesuai',
        );
      }
      return data;
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static InfoGalat _tanganiGalat(dynamic e) {
    final teksGalat = e.toString().toLowerCase();

    if (e is http.ClientException ||
        teksGalat.contains('socketexception') ||
        teksGalat.contains('connection refused') ||
        teksGalat.contains('failed host lookup')) {
      return InfoGalat(
        jenis: JenisGalat.tidakAdaSambungan,
        pesan: 'Sambungan ke server gagal. Periksa koneksi internet atau pastikan server aktif.',
      );
    } else if (e is TimeoutException) {
      return InfoGalat(
        jenis: JenisGalat.batasWaktu,
        pesan: 'Server tidak membalas dalam batas waktu. Silakan coba beberapa saat lagi.',
      );
    } else if (e is InfoGalat) {
      return e;
    } else {
      return InfoGalat(
        jenis: JenisGalat.galatServer,
        pesan:
            'Terjadi gangguan pada layanan apotek. Silakan coba kembali nanti.',
      );
    }
  }

  static dynamic _prosesResponse(http.Response response) {
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw InfoGalat(
        jenis: JenisGalat.galatServer,
        pesan: 'Terjadi kesalahan sistem di server. Silakan coba lagi.',
      );
    }

    final statusCode = response.statusCode;
    final message = body?['message'] ?? 'Terjadi kesalahan';

    if (statusCode >= 200 && statusCode < 300) {
      return body?['data'];
    }

    if (statusCode == 422) {
      Map<String, List<String>> validationErrors = {};
      if (body?['errors'] != null && body?['errors'] is Map) {
        (body?['errors'] as Map).forEach((key, val) {
          if (val is List) {
            validationErrors[key.toString()] = val
                .map((e) => e.toString())
                .toList();
          } else {
            validationErrors[key.toString()] = [val.toString()];
          }
        });
      }
      throw InfoGalat(
        jenis: JenisGalat.validasi,
        pesan: message,
        rincianValidasi: validationErrors,
      );
    }

    if (statusCode == 409) {
      throw InfoGalat(jenis: JenisGalat.bentrokKeadaan, pesan: message);
    }

    if (statusCode == 404) {
      throw InfoGalat(
        jenis: JenisGalat.lainnya,
        pesan: message.isNotEmpty
            ? message
            : 'Data yang diminta tidak ditemukan.',
      );
    }

    if (statusCode >= 500) {
      throw InfoGalat(
        jenis: JenisGalat.galatServer,
        pesan: 'Layanan apotek sedang mengalami gangguan (Server 500). Silakan coba lagi.',
      );
    }

    throw InfoGalat(jenis: JenisGalat.lainnya, pesan: message);
  }

  static Future<List<ProdukModel>> getProduk({
    String? kategori,
    String? cari,
    int page = 1,
    int perPage = 8,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/produk').replace(
        queryParameters: {
          if (kategori != null && kategori != 'Semua') 'kategori': kategori,
          if (cari != null && cari.trim().isNotEmpty) 'cari': cari.trim(),
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );

      final res = await http.get(uri).timeout(timeoutDuration);
      final data = _prosesResponse(res) as List? ?? [];
      return data
          .map((e) => ProdukModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static Future<ProdukModel> getProdukDetail(int id) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/produk/$id'))
          .timeout(timeoutDuration);
      final data = _prosesResponse(res);
      return ProdukModel.fromJson(data);
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static Future<ProdukModel> tambahProduk(Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/produk'),
            headers: _headersAuth({'Content-Type': 'application/json'}),
            body: jsonEncode(body),
          )
          .timeout(timeoutDuration);
      final data = _prosesResponse(res);
      return ProdukModel.fromJson(data);
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static Future<ProdukModel> updateProduk(
    int id,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/produk/$id'),
            headers: _headersAuth({'Content-Type': 'application/json'}),
            body: jsonEncode(body),
          )
          .timeout(timeoutDuration);
      final data = _prosesResponse(res);
      return ProdukModel.fromJson(data);
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static Future<void> hapusProduk(int id) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$baseUrl/produk/$id'),
            headers: _headersAuth(),
          )
          .timeout(timeoutDuration);
      _prosesResponse(res);
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static Future<KeranjangDataModel> getKeranjang() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/keranjang'),
            headers: _headersAuth(),
          )
          .timeout(timeoutDuration);
      final data = _prosesResponse(res);
      return KeranjangDataModel.fromJson(data);
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static Future<void> tambahKeranjang(int produkId, int jumlah) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/keranjang'),
            headers: _headersAuth({'Content-Type': 'application/json'}),
            body: jsonEncode({'produk_id': produkId, 'jumlah': jumlah}),
          )
          .timeout(timeoutDuration);
      _prosesResponse(res);
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static Future<void> ubahJumlahKeranjang(int keranjangId, int jumlah) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/keranjang/$keranjangId'),
            headers: _headersAuth({'Content-Type': 'application/json'}),
            body: jsonEncode({'jumlah': jumlah}),
          )
          .timeout(timeoutDuration);
      _prosesResponse(res);
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static Future<void> hapusItemKeranjang(int keranjangId) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$baseUrl/keranjang/$keranjangId'),
            headers: _headersAuth(),
          )
          .timeout(timeoutDuration);
      _prosesResponse(res);
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static Future<List<KurirModel>> getKurir() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/kurir'),
            headers: _headersAuth(),
          )
          .timeout(timeoutDuration);
      final data = _prosesResponse(res) as List? ?? [];
      return data
          .map((e) => KurirModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static Future<PesananModel> checkout({
    required String idempotencyKey,
    required String namaPenerima,
    required String alamat,
    int? kurirId,
    required String metodePembayaran,
    String? nomorResep,
    String? rajaongkirDestination,
    String? rajaongkirService,
    String? rajaongkirCourier,
  }) async {
    try {
      final body = {
        'nama_penerima': namaPenerima,
        'alamat': alamat,
        'metode_pembayaran': metodePembayaran,
        'kurir_id': ?kurirId,
        if (nomorResep != null && nomorResep.trim().isNotEmpty)
          'nomor_resep': nomorResep.trim(),
        'rajaongkir_destination': ?rajaongkirDestination,
        'rajaongkir_service': ?rajaongkirService,
        'rajaongkir_courier': ?rajaongkirCourier,
      };

      final res = await http
          .post(
            Uri.parse('$baseUrl/checkout'),
            headers: _headersAuth({
              'Content-Type': 'application/json',
              'X-Kunci-Idempoten': idempotencyKey,
            }),
            body: jsonEncode(body),
          )
          .timeout(timeoutDuration);

      final data = _prosesResponse(res);
      return PesananModel.fromJson(data);
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static Future<List<PesananModel>> getPesananList() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/pesanan'),
            headers: _headersAuth(),
          )
          .timeout(timeoutDuration);
      final data = _prosesResponse(res) as List? ?? [];
      return data
          .map((e) => PesananModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static Future<PesananModel> getPesananDetail(int id) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/pesanan/$id'),
            headers: _headersAuth(),
          )
          .timeout(timeoutDuration);
      final data = _prosesResponse(res);
      return PesananModel.fromJson(data);
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  /// Minta backend menanyakan status invoice Xendit langsung ke API Xendit
  /// (server-to-server) dan memperbarui status pesanan bila sudah dibayar.
  static Future<PesananModel> syncStatusXendit(int pesananId) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/pesanan/$pesananId/xendit/status'),
            headers: _headersAuth(),
          )
          .timeout(timeoutDuration);
      final data = _prosesResponse(res);
      return PesananModel.fromJson(data);
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static Future<PesananModel> updateStatusPesanan(
    int id,
    String statusBaru,
  ) async {
    try {
      final res = await http
          .patch(
            Uri.parse('$baseUrl/pesanan/$id/status'),
            headers: _headersAuth({'Content-Type': 'application/json'}),
            body: jsonEncode({'status': statusBaru}),
          )
          .timeout(timeoutDuration);
      final data = _prosesResponse(res);
      return PesananModel.fromJson(data);
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getRajaongkirProvinces() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/rajaongkir/provinsi'),
            headers: _headersAuth(),
          )
          .timeout(timeoutDuration);
      final data = _prosesResponse(res) as List? ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getRajaongkirCitiesByProvince(
    String provinsiId,
  ) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/rajaongkir/kota-by-provinsi/$provinsiId'),
            headers: _headersAuth(),
          )
          .timeout(timeoutDuration);
      final data = _prosesResponse(res) as List? ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getRajaongkirDistrictsByCity(
    String kotaId,
  ) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/rajaongkir/kecamatan/$kotaId'),
            headers: _headersAuth(),
          )
          .timeout(timeoutDuration);
      final data = _prosesResponse(res) as List? ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getRajaongkirVillagesByDistrict(
    String kecamatanId,
  ) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/rajaongkir/desa/$kecamatanId'),
            headers: _headersAuth(),
          )
          .timeout(timeoutDuration);
      final data = _prosesResponse(res) as List? ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getRajaongkirCities() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/rajaongkir/kota'),
            headers: _headersAuth(),
          )
          .timeout(timeoutDuration);
      final data = _prosesResponse(res) as List? ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  /// Ambil konfigurasi publik dari Laravel (termasuk Google Maps API Key)
  static Future<Map<String, dynamic>> getAppConfig() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/config'),
            headers: _headersAuth(),
          )
          .timeout(timeoutDuration);
      final data = _prosesResponse(res);
      return Map<String, dynamic>.from(data as Map);
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }

  static Future<List<Map<String, dynamic>>> checkRajaongkirCost({
    required String destinationCityId,
    int weight = 1000,
    String courier = 'jne',
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/rajaongkir/ongkir'),
            headers: _headersAuth({'Content-Type': 'application/json'}),
            body: jsonEncode({
              'destination': destinationCityId,
              'weight': weight,
              'courier': courier,
            }),
          )
          .timeout(timeoutDuration);
      final data = _prosesResponse(res) as List? ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw _tanganiGalat(e);
    }
  }
}
