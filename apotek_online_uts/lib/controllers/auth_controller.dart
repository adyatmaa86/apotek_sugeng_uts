import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_state.dart';

/// GetX controller pengganti [SesiAuth].
/// Didaftarkan sekali di main.dart dengan Get.put(AuthController()).
class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  static const String _kunciToken = 'auth_token';
  static const String _kunciPengguna = 'auth_pengguna';

  final RxString token = ''.obs;
  final Rx<ProfilPengguna?> pengguna = Rx<ProfilPengguna?>(null);

  bool get sedangLogin => token.value.isNotEmpty;

  /// True bila sesi aktif adalah akun admin (dipakai untuk gerbang
  /// Kelola Produk Mode UTS — server juga menolak non-admin).
  bool get adminAktif =>
      sedangLogin && (pengguna.value?.isAdmin ?? false);

  /// Item keranjang guest (sebelum login) yang perlu di-merge ke akun.
  List<Map<String, int>> keranjangGuestTertunda = [];

  /// Muat sesi tersimpan saat aplikasi pertama dijalankan.
  Future<void> muat() async {
    final prefs = await SharedPreferences.getInstance();
    token.value = prefs.getString(_kunciToken) ?? '';
    final jsonPengguna = prefs.getString(_kunciPengguna);
    if (jsonPengguna != null) {
      try {
        pengguna.value = ProfilPengguna.fromJson(
          jsonDecode(jsonPengguna) as Map<String, dynamic>,
        );
      } catch (_) {
        pengguna.value = null;
      }
    }
  }

  Future<void> simpanSesi(
    String tkn,
    Map<String, dynamic> dataPengguna,
  ) async {
    token.value = tkn;
    pengguna.value = ProfilPengguna.fromJson(dataPengguna);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kunciToken, tkn);
    await prefs.setString(_kunciPengguna, jsonEncode(dataPengguna));
  }

  /// Perbarui data profil (mis. setelah edit foto) tanpa mengganti token.
  Future<void> perbaruiProfil(Map<String, dynamic> dataPengguna) async {
    pengguna.value = ProfilPengguna.fromJson(dataPengguna);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kunciPengguna, jsonEncode(dataPengguna));
  }

  Future<void> keluar() async {
    token.value = '';
    pengguna.value = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kunciToken);
    await prefs.remove(_kunciPengguna);
  }
}
