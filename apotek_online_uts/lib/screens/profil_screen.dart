import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../utils/url_berkas.dart';
import 'login_screen.dart';

/// Halaman akun: profil saat login, ajakan masuk saat belum login.
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  bool _sedangKeluar = false;
  bool _sedangSimpanFoto = false;

  Future<void> _keluar() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar Akun?'),
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (yakin != true || !mounted) return;
    setState(() => _sedangKeluar = true);

    await LayananApi.logoutAkun();
    await SesiAuth.keluar();
    LayananApi.setToken(null);

    if (!mounted) return;
    setState(() => _sedangKeluar = false);

    // Alert konfirmasi berhasil logout sebelum kembali ke katalog.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.teal, size: 48),
        title: const Text('Berhasil Keluar'),
        content: const Text('Anda telah keluar dari akun.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: FilledButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _masuk() async {
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    if (berhasil == true && mounted) {
      // Kembalikan true ke halaman sebelumnya (katalog) agar keranjang di-reload
      Navigator.pop(context, true);
    }
  }

  /// Dialog pilihan sumber foto (kamera / galeri), lalu unggah ke server.
  Future<void> _editFotoProfil() async {
    final sumber = await showDialog<ImageSource>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah Foto Profil'),
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
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, ImageSource.gallery),
            style: FilledButton.styleFrom(backgroundColor: Colors.teal),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Galeri'),
          ),
        ],
      ),
    );

    if (sumber == null || !mounted) return;

    try {
      final foto = await ImagePicker().pickImage(
        source: sumber,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (foto == null || !mounted) return;

      setState(() => _sedangSimpanFoto = true);

      final pengguna = await LayananApi.perbaruiProfilAkun(foto.path);
      await SesiAuth.perbaruiProfil(pengguna);

      if (!mounted) return;
      setState(() => _sedangSimpanFoto = false);

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.teal, size: 48),
          title: const Text('Profil Tersimpan'),
          content: const Text('Foto profil berhasil diperbarui.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: FilledButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sedangSimpanFoto = false);
      final pesan = e is InfoGalat ? e.pesan : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesan), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pengguna = SesiAuth.pengguna;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Akun Saya'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: pengguna == null
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.account_circle_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Anda belum masuk',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masuk untuk menyimpan riwayat pesanan dan keranjang '
                    'di akun Anda sendiri.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _masuk,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.login),
                    label: const Text('Masuk / Daftar'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Stack(
                    children: [
                      () {
                        final fotoUrl = UrlBerkas.dari(pengguna.fotoUrl);
                        return CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.teal,
                          backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                              ? NetworkImage(fotoUrl)
                              : null,
                          child: fotoUrl == null || fotoUrl.isEmpty
                              ? Text(
                                  pengguna.nama.isNotEmpty
                                      ? pengguna.nama[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        );
                      }(),
                      if (_sedangSimpanFoto)
                        const Positioned.fill(
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.black38,
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  pengguna.nama,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  pengguna.email,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.verified_user_outlined,
                        color: Colors.teal),
                    title: const Text('Sesi aktif'),
                    subtitle: const Text(
                      'Keranjang & pesanan terikat ke akun ini di server.',
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Tombol edit profil di atas tombol keluar.
                FilledButton.icon(
                  onPressed: _sedangSimpanFoto || _sedangKeluar
                      ? null
                      : _editFotoProfil,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profil'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _sedangKeluar ? null : _keluar,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _sedangKeluar
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout),
                  label: const Text('Keluar dari Akun'),
                ),
              ],
            ),
    );
  }
}
