import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../utils/konfigurasi_auth.dart';
import 'auth_controller.dart';

/// GetX Controller untuk mengelola keadaan Layar Masuk / Daftar.
class LoginController extends GetxController {
  final RxInt tabIndex = 0.obs;
  final RxBool sedangProses = false.obs;
  final RxBool sembunyikanPassword = true.obs;
  final RxBool sembunyikanKonfirmasi = true.obs;
  final Rx<String?> pesanGalat = Rx<String?>(null);

  void togglePassword() =>
      sembunyikanPassword.value = !sembunyikanPassword.value;
  void toggleKonfirmasi() =>
      sembunyikanKonfirmasi.value = !sembunyikanKonfirmasi.value;

  void gantiTab(int index) {
    tabIndex.value = index;
    pesanGalat.value = null;
  }

  Future<void> prosesEmail({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required String nama,
    required String email,
    required String password,
  }) async {
    if (!formKey.currentState!.validate()) return;
    sedangProses.value = true;
    pesanGalat.value = null;

    try {
      final daftar = tabIndex.value == 1;
      final sesi = daftar
          ? await LayananApi.registerAkun(
              nama: nama.trim(),
              email: email.trim(),
              password: password,
            )
          : await LayananApi.loginEmail(
              email: email.trim(),
              password: password,
            );

      await AuthController.to.simpanSesi(
        sesi['token'] as String,
        sesi['user'] as Map<String, dynamic>,
      );

      if (!context.mounted) return;
      await _tampilkanSukses(
        context,
        daftar ? 'Pendaftaran Berhasil' : 'Login Berhasil',
        'Selamat datang, ${AuthController.to.pengguna.value?.nama ?? 'Pengguna'}!',
      );
      if (!context.mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      pesanGalat.value = e is InfoGalat ? e.pesan : e.toString();
    } finally {
      sedangProses.value = false;
    }
  }

  Future<void> prosesGoogle(BuildContext context) async {
    if (!KonfigurasiAuth.googleTerpasang) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Google Sign-In belum dikonfigurasi.\n'
          'Isi KonfigurasiAuth.googleWebClientId di '
          'lib/utils/konfigurasi_auth.dart dan GOOGLE_CLIENT_ID di .env server.',
        ),
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    sedangProses.value = true;
    pesanGalat.value = null;

    try {
      final google = GoogleSignIn.instance;
      await google.initialize(
        serverClientId: KonfigurasiAuth.googleWebClientId,
        clientId: kIsWeb ? KonfigurasiAuth.googleWebClientId : null,
      );

      try {
        await google.signOut();
      } catch (_) {}

      final akun = await google.authenticate();
      final otentikasi = akun.authentication;
      final idToken = otentikasi.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw InfoGalat(
          jenis: JenisGalat.galatServer,
          pesan: 'Google tidak mengirim id_token. Periksa konfigurasi Client ID.',
        );
      }

      final sesi = await LayananApi.loginGoogle(idToken);
      await AuthController.to.simpanSesi(
        sesi['token'] as String,
        sesi['user'] as Map<String, dynamic>,
      );

      if (!context.mounted) return;
      await _tampilkanSukses(
        context,
        'Login Berhasil',
        'Selamat datang, ${AuthController.to.pengguna.value?.nama ?? 'Pengguna'}!',
      );
      if (!context.mounted) return;
      Navigator.pop(context, true);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        sedangProses.value = false;
        return;
      }
      pesanGalat.value = 'Google Sign-In gagal: ${e.description}';
    } catch (e) {
      pesanGalat.value = e is InfoGalat ? e.pesan : e.toString();
    } finally {
      sedangProses.value = false;
    }
  }

  Future<void> _tampilkanSukses(
    BuildContext context,
    String judul,
    String pesan,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 48),
        title: Text(judul, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(pesan),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
