import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import 'auth_controller.dart';

/// GetX Controller untuk mengelola keadaan Profil Pengguna.
class ProfilController extends GetxController {
  final RxBool sedangKeluar = false.obs;
  final RxBool sedangSimpanFoto = false.obs;

  Future<void> keluar(BuildContext context) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Keluar Akun?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Keranjang akan dikosongkan setelah Anda keluar dari akun.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (yakin != true || !context.mounted) return;
    sedangKeluar.value = true;

    try {
      await LayananApi.logoutAkun();
      await AuthController.to.keluar();
    } finally {
      sedangKeluar.value = false;
    }

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 48),
        title: const Text(
          'Berhasil Keluar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Anda telah keluar dari akun Apotek Sugeng.'),
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

    if (!context.mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> editFotoProfil(BuildContext context) async {
    final sumber = await showDialog<ImageSource>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Ubah Foto Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Pilih sumber foto profil baru:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, ImageSource.camera),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Kamera'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0284C7),
              side: const BorderSide(color: Color(0xFFBAE6FD)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, ImageSource.gallery),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Galeri'),
          ),
        ],
      ),
    );

    if (sumber == null || !context.mounted) return;

    try {
      final foto = await ImagePicker().pickImage(
        source: sumber,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (foto == null || !context.mounted) return;

      sedangSimpanFoto.value = true;
      final pengguna = await LayananApi.perbaruiProfilAkun(foto.path);
      await AuthController.to.perbaruiProfil(pengguna);
      sedangSimpanFoto.value = false;

      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 48),
          title: const Text(
            'Profil Tersimpan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Foto profil berhasil diperbarui.'),
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
    } catch (e) {
      sedangSimpanFoto.value = false;
      if (!context.mounted) return;
      final pesan = e is InfoGalat ? e.pesan : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesan),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
