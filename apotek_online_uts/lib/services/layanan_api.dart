// ignore_for_file: use_null_aware_elements

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;

import '../controllers/keranjang_controller.dart';
import '../models/keranjang_model.dart';
import '../models/kurir_model.dart';
import '../models/pesanan_model.dart';
import '../models/produk_model.dart';
import '../utils/app_state.dart';
import 'dio_client.dart';

/// Layanan API apotek — semua request melalui [DioClient].
/// Semua metode tetap static agar tidak perlu mengubah cara pemanggilan di screen.
class LayananApi {
  static final Dio _dio = DioClient.instance;

  static String get baseUrl => DioClient.baseUrl;

  // ==================== AUTENTIKASI ====================

  static Future<Map<String, dynamic>> registerAkun({
    required String nama,
    required String email,
    required String password,
  }) async {
    return _kirimAuth('/auth/register', body: {
      'name': nama,
      'email': email,
      'password': password,
      'password_confirmation': password,
    });
  }

  static Future<Map<String, dynamic>> loginEmail({
    required String email,
    required String password,
  }) async {
    return _kirimAuth('/auth/login', body: {
      'email': email,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> loginGoogle(String idToken) async {
    return _kirimAuth('/auth/google', body: {'id_token': idToken});
  }

  static Future<void> logoutAkun() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // Logout lokal tetap dilakukan walau server gagal dijangkau.
    }
  }

  static Future<Map<String, dynamic>> perbaruiProfilAkun(
    String jalurFoto,
  ) async {
    try {
      final formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(jalurFoto, filename: 'foto.jpg'),
      });
      final res = await _dio.post('/auth/profil', data: formData);
      final data = DioClient.prosesData(res);
      if (data is! Map<String, dynamic>) {
        throw InfoGalat(
          jenis: JenisGalat.galatServer,
          pesan: 'Respons profil tidak sesuai',
        );
      }
      return data;
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  static Future<Map<String, dynamic>> _kirimAuth(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final res = await _dio.post(path, data: body);
      final data = DioClient.prosesData(res);
      if (data is! Map<String, dynamic> || data['token'] == null) {
        throw InfoGalat(
          jenis: JenisGalat.galatServer,
          pesan: 'Respons autentikasi tidak sesuai',
        );
      }
      return data;
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  // ==================== PRODUK ====================

  static Future<List<ProdukModel>> getProduk({
    String? kategori,
    String? cari,
    int page = 1,
    int perPage = 8,
  }) async {
    try {
      final res = await _dio.get('/produk', queryParameters: {
        if (kategori != null && kategori != 'Semua') 'kategori': kategori,
        if (cari != null && cari.trim().isNotEmpty) 'cari': cari.trim(),
        'page': page,
        'per_page': perPage,
      });
      final data = DioClient.prosesData(res) as List? ?? [];
      return data
          .map((e) => ProdukModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  static Future<ProdukModel> getProdukDetail(int id) async {
    try {
      final res = await _dio.get('/produk/$id');
      return ProdukModel.fromJson(DioClient.prosesData(res));
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  static Future<ProdukModel> tambahProduk(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/produk', data: body);
      return ProdukModel.fromJson(DioClient.prosesData(res));
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  static Future<ProdukModel> updateProduk(
    int id,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.put('/produk/$id', data: body);
      return ProdukModel.fromJson(DioClient.prosesData(res));
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  static Future<void> hapusProduk(int id) async {
    try {
      await _dio.delete('/produk/$id');
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  // ==================== KERANJANG ====================

  static Future<KeranjangDataModel> getKeranjang() async {
    try {
      final res = await _dio.get('/keranjang');
      return KeranjangDataModel.fromJson(DioClient.prosesData(res));
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  static Future<void> tambahKeranjang(int produkId, int jumlah) async {
    try {
      await _dio.post('/keranjang',
          data: {'produk_id': produkId, 'jumlah': jumlah});
      if (Get.isRegistered<KeranjangController>()) {
        await KeranjangController.to.muatKeranjang(senyap: true);
      }
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  static Future<void> ubahJumlahKeranjang(
      int keranjangId, int jumlah) async {
    try {
      await _dio.put('/keranjang/$keranjangId', data: {'jumlah': jumlah});
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  static Future<void> hapusItemKeranjang(int keranjangId) async {
    try {
      await _dio.delete('/keranjang/$keranjangId');
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  // ==================== KURIR ====================

  static Future<List<KurirModel>> getKurir() async {
    try {
      final res = await _dio.get('/kurir');
      final data = DioClient.prosesData(res) as List? ?? [];
      return data
          .map((e) => KurirModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  // ==================== PESANAN ====================

  static Future<PesananModel> checkout({
    required String idempotencyKey,
    required String namaPenerima,
    required String alamat,
    int? kurirId,
    required String metodePembayaran,
    String? nomorResep,
    File? fotoResep,
    String? rajaongkirDestination,
    String? rajaongkirService,
    String? rajaongkirCourier,
  }) async {
    try {
      final fields = <String, dynamic>{
        'nama_penerima': namaPenerima,
        'alamat': alamat,
        'metode_pembayaran': metodePembayaran,
        if (kurirId != null) 'kurir_id': kurirId.toString(),
        if (nomorResep != null && nomorResep.trim().isNotEmpty)
          'nomor_resep': nomorResep.trim(),
        if (rajaongkirDestination != null)
          'rajaongkir_destination': rajaongkirDestination,
        if (rajaongkirService != null) 'rajaongkir_service': rajaongkirService,
        if (rajaongkirCourier != null) 'rajaongkir_courier': rajaongkirCourier,
        if (fotoResep != null)
          'foto_resep': await MultipartFile.fromFile(
            fotoResep.path,
            filename: 'resep.jpg',
          ),
      };

      final res = await _dio.post(
        '/checkout',
        data: FormData.fromMap(fields),
        options: Options(headers: {'X-Kunci-Idempoten': idempotencyKey}),
      );
      return PesananModel.fromJson(DioClient.prosesData(res));
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  static Future<List<PesananModel>> getPesananList() async {
    try {
      final res = await _dio.get('/pesanan');
      final data = DioClient.prosesData(res) as List? ?? [];
      return data
          .map((e) => PesananModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  static Future<PesananModel> getPesananDetail(int id) async {
    try {
      final res = await _dio.get('/pesanan/$id');
      return PesananModel.fromJson(DioClient.prosesData(res));
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  static Future<PesananModel> syncStatusXendit(int pesananId) async {
    try {
      final res = await _dio.get('/pesanan/$pesananId/xendit/status');
      return PesananModel.fromJson(DioClient.prosesData(res));
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  static Future<PesananModel> updateStatusPesanan(
    int id,
    String statusBaru,
  ) async {
    try {
      final res = await _dio.patch(
        '/pesanan/$id/status',
        data: {'status': statusBaru},
      );
      return PesananModel.fromJson(DioClient.prosesData(res));
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  // ==================== RAJAONGKIR ====================

  static Future<List<Map<String, dynamic>>> getRajaongkirProvinces() async {
    try {
      final res = await _dio.get('/rajaongkir/provinsi');
      final data = DioClient.prosesData(res) as List? ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getRajaongkirCitiesByProvince(
    String provinsiId,
  ) async {
    try {
      final res = await _dio.get('/rajaongkir/kota-by-provinsi/$provinsiId');
      final data = DioClient.prosesData(res) as List? ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getRajaongkirDistrictsByCity(
    String kotaId,
  ) async {
    try {
      final res = await _dio.get('/rajaongkir/kecamatan/$kotaId');
      final data = DioClient.prosesData(res) as List? ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getRajaongkirVillagesByDistrict(
    String kecamatanId,
  ) async {
    try {
      final res = await _dio.get('/rajaongkir/desa/$kecamatanId');
      final data = DioClient.prosesData(res) as List? ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getRajaongkirCities() async {
    try {
      final res = await _dio.get('/rajaongkir/kota');
      final data = DioClient.prosesData(res) as List? ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  static Future<Map<String, dynamic>> getAppConfig() async {
    try {
      final res = await _dio.get('/config');
      return Map<String, dynamic>.from(DioClient.prosesData(res) as Map);
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }

  static Future<List<Map<String, dynamic>>> checkRajaongkirCost({
    required String destinationCityId,
    int weight = 1000,
    String courier = 'jne',
  }) async {
    try {
      final res = await _dio.post('/rajaongkir/ongkir', data: {
        'destination': destinationCityId,
        'weight': weight,
        'courier': courier,
      });
      final data = DioClient.prosesData(res) as List? ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw DioClient.tanganiGalat(e);
    }
  }
}
