import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum KeadaanMuat { memuat, berhasil, kosong, galat }

enum JenisGalat {
  tidakAdaSambungan,
  batasWaktu,
  validasi,
  bentrokKeadaan,
  galatServer,
  lainnya,
}

class InfoGalat {
  final JenisGalat jenis;
  final String pesan;
  final Map<String, List<String>>? rincianValidasi;

  InfoGalat({required this.jenis, required this.pesan, this.rincianValidasi});

  @override
  String toString() => pesan;
}

class ProfilPengguna {
  final int id;
  final String nama;
  final String email;
  final String? fotoUrl;

  ProfilPengguna({
    required this.id,
    required this.nama,
    required this.email,
    this.fotoUrl,
  });

  factory ProfilPengguna.fromJson(Map<String, dynamic> json) {
    return ProfilPengguna(
      id: json['id'] as int,
      nama: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fotoUrl: json['foto_url']?.toString(),
    );
  }
}

/// Sesi login pembeli: token Sanctum + profil tersimpan di perangkat.
/// Tanpa login, aplikasi memakai pelanggan_id tetap UTS (mode simulasi).
class SesiAuth {
  static const String _kunciToken = 'auth_token';
  static const String _kunciPengguna = 'auth_pengguna';

  static String? _token;
  static ProfilPengguna? _pengguna;

  /// Item keranjang guest (sebelum login) yang perlu di-merge ke akun.
  /// Berisi list Map {produk_id, jumlah}.
  static List<Map<String, int>> keranjangGuestTertunda = [];

  /// Dipanggil setiap sesi berubah (login/logout) agar UI bisa membangun ulang.
  static void Function()? onBerubah;
  static final List<void Function()> _listeners = [];

  static void tambahListener(void Function() listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  static void hapusListener(void Function() listener) {
    _listeners.remove(listener);
  }

  static void _beritahuPerubahan() {
    onBerubah?.call();
    for (final l in List<void Function()>.from(_listeners)) {
      try {
        l();
      } catch (_) {}
    }
  }

  static String? get token => _token;
  static ProfilPengguna? get pengguna => _pengguna;
  static bool get sedangLogin => _token != null && _token!.isNotEmpty;

  /// Muat sesi tersimpan saat aplikasi pertama dijalankan.
  static Future<void> muat() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kunciToken);
    final jsonPengguna = prefs.getString(_kunciPengguna);

    if (jsonPengguna != null) {
      try {
        _pengguna = ProfilPengguna.fromJson(
          jsonDecode(jsonPengguna) as Map<String, dynamic>,
        );
      } catch (_) {
        _pengguna = null;
      }
    }
  }

  static Future<void> simpanSesi(
    String token,
    Map<String, dynamic> pengguna,
  ) async {
    _token = token;
    _pengguna = ProfilPengguna.fromJson(pengguna);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kunciToken, token);
    await prefs.setString(_kunciPengguna, jsonEncode(pengguna));

    _beritahuPerubahan();
  }

  /// Perbarui data profil (mis. setelah edit foto) tanpa mengganti token.
  static Future<void> perbaruiProfil(Map<String, dynamic> pengguna) async {
    _pengguna = ProfilPengguna.fromJson(pengguna);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kunciPengguna, jsonEncode(pengguna));

    _beritahuPerubahan();
  }

  static Future<void> keluar() async {
    _token = null;
    _pengguna = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kunciToken);
    await prefs.remove(_kunciPengguna);

    _beritahuPerubahan();
  }
}
