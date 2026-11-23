import 'dart:io';

import 'package:dio/dio.dart';

import '../controllers/auth_controller.dart';
import '../utils/app_state.dart';

/// Singleton Dio — satu instance untuk seluruh aplikasi.
/// Token Sanctum di-inject otomatis via interceptor dari [AuthController].
class DioClient {
  DioClient._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.8:8000/api',
  );

  static const Duration _timeout = Duration(seconds: 15);

  static final Dio _dio = _buat();

  static Dio get instance => _dio;

  static Dio _buat() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        sendTimeout: _timeout,
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = AuthController.to.token.value;
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    return dio;
  }

  /// Ekstrak field `data` dari body respons API.
  static dynamic prosesData(Response response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      return body['data'];
    }
    return body;
  }

  /// Konversi exception apa pun → [InfoGalat].
  static InfoGalat tanganiGalat(dynamic e) {
    if (e is InfoGalat) return e;

    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return InfoGalat(
            jenis: JenisGalat.batasWaktu,
            pesan:
                'Server tidak membalas dalam batas waktu. Silakan coba beberapa saat lagi.',
          );
        case DioExceptionType.connectionError:
          return InfoGalat(
            jenis: JenisGalat.tidakAdaSambungan,
            pesan:
                'Sambungan ke server gagal. Periksa koneksi internet atau pastikan server aktif.',
          );
        case DioExceptionType.badResponse:
          return _dariStatusCode(e.response);
        default:
          final msg = e.message?.toLowerCase() ?? '';
          if (msg.contains('socketexception') ||
              msg.contains('connection refused') ||
              msg.contains('failed host lookup')) {
            return InfoGalat(
              jenis: JenisGalat.tidakAdaSambungan,
              pesan:
                  'Sambungan ke server gagal. Periksa koneksi internet atau pastikan server aktif.',
            );
          }
          return InfoGalat(
            jenis: JenisGalat.galatServer,
            pesan:
                'Terjadi gangguan pada layanan apotek. Silakan coba kembali nanti.',
          );
      }
    }

    if (e is SocketException) {
      return InfoGalat(
        jenis: JenisGalat.tidakAdaSambungan,
        pesan:
            'Sambungan ke server gagal. Periksa koneksi internet atau pastikan server aktif.',
      );
    }

    return InfoGalat(
      jenis: JenisGalat.galatServer,
      pesan: 'Terjadi gangguan pada layanan apotek. Silakan coba kembali nanti.',
    );
  }

  static InfoGalat _dariStatusCode(Response? response) {
    if (response == null) {
      return InfoGalat(
          jenis: JenisGalat.galatServer, pesan: 'Respons server kosong.');
    }

    final body = response.data;
    final message =
        (body is Map ? (body['message'] ?? 'Terjadi kesalahan') : 'Terjadi kesalahan')
            .toString();
    final statusCode = response.statusCode ?? 0;

    if (statusCode == 422) {
      final Map<String, List<String>> validationErrors = {};
      if (body is Map && body['errors'] is Map) {
        (body['errors'] as Map).forEach((key, val) {
          validationErrors[key.toString()] = val is List
              ? val.map((e) => e.toString()).toList()
              : [val.toString()];
        });
      }
      return InfoGalat(
        jenis: JenisGalat.validasi,
        pesan: message,
        rincianValidasi: validationErrors,
      );
    }

    if (statusCode == 409) {
      return InfoGalat(jenis: JenisGalat.bentrokKeadaan, pesan: message);
    }

    if (statusCode == 404) {
      return InfoGalat(
        jenis: JenisGalat.lainnya,
        pesan: message.isNotEmpty ? message : 'Data yang diminta tidak ditemukan.',
      );
    }

    if (statusCode >= 500) {
      return InfoGalat(
        jenis: JenisGalat.galatServer,
        pesan:
            'Layanan apotek sedang mengalami gangguan (Server $statusCode). Silakan coba lagi.',
      );
    }

    return InfoGalat(jenis: JenisGalat.lainnya, pesan: message);
  }
}
