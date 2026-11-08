import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../utils/konfigurasi_auth.dart';

/// Layar masuk / daftar pembeli.
/// - Email + password: berfungsi penuh (Sanctum token).
/// - Tombol Google: alur sudah terhubung, tinggal isi Client ID di
///   [KonfigurasiAuth] dan `GOOGLE_CLIENT_ID` di .env server.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _konfirmasiController = TextEditingController();

  bool _sedangProses = false;
  String? _pesanGalat;

  @override
  void dispose() {
    _tab.dispose();
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  Future<void> _prosesEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sedangProses = true;
      _pesanGalat = null;
    });

    try {
      final daftar = _tab.index == 1;

      final sesi = daftar
          ? await LayananApi.registerAkun(
              nama: _namaController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
            )
          : await LayananApi.loginEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

      await SesiAuth.simpanSesi(
        sesi['token'] as String,
        sesi['user'] as Map<String, dynamic>,
      );
      LayananApi.setToken(sesi['token'] as String);

      // Keranjang guest otomatis digabung ke akun oleh server saat login.

      if (!mounted) return;
      await _tampilkanSukses(
        daftar ? 'Pendaftaran Berhasil' : 'Login Berhasil',
        'Selamat datang, ${SesiAuth.pengguna?.nama ?? 'Pengguna'}!',
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pesanGalat = e is InfoGalat ? e.pesan : e.toString();
      });
    } finally {
      if (mounted) setState(() => _sedangProses = false);
    }
  }

  /// Dialog alert sukses setelah login / daftar berhasil.
  Future<void> _tampilkanSukses(String judul, String pesan) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.teal, size: 48),
        title: Text(judul),
        content: Text(pesan),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: FilledButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _prosesGoogle() async {
    if (!KonfigurasiAuth.googleTerpasang) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Google Sign-In belum dikonfigurasi.\n'
          'Isi KonfigurasiAuth.googleWebClientId di '
          'lib/utils/konfigurasi_auth.dart dan GOOGLE_CLIENT_ID di .env server.',
        ),
        duration: Duration(seconds: 5),
      ));
      return;
    }

    setState(() {
      _sedangProses = true;
      _pesanGalat = null;
    });

    try {
      final google = GoogleSignIn.instance;
      await google.initialize(
        serverClientId: KonfigurasiAuth.googleWebClientId,
        clientId: KonfigurasiAuth.googleAndroidClientId.isEmpty
            ? null
            : KonfigurasiAuth.googleAndroidClientId,
      );

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
      await SesiAuth.simpanSesi(
        sesi['token'] as String,
        sesi['user'] as Map<String, dynamic>,
      );
      LayananApi.setToken(sesi['token'] as String);

      // Keranjang guest otomatis digabung ke akun oleh server saat login.

      if (!mounted) return;
      await _tampilkanSukses(
        'Login Berhasil',
        'Selamat datang, ${SesiAuth.pengguna?.nama ?? 'Pengguna'}!',
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on GoogleSignInException catch (e) {
      if (!mounted) return;
      if (e.code == GoogleSignInExceptionCode.canceled) {
        setState(() => _sedangProses = false);
        return;
      }
      setState(() => _pesanGalat = 'Google Sign-In gagal: ${e.description}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pesanGalat = e is InfoGalat ? e.pesan : e.toString();
      });
    } finally {
      if (mounted) setState(() => _sedangProses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akun Pembeli'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: const Text(
                  'Masuk agar riwayat pesanan dan keranjang Anda tersimpan '
                  'aman di akun sendiri. Tanpa login, aplikasi tetap bisa '
                  'dijelajahi (mode simulasi UTS).',
                  style: TextStyle(fontSize: 12, color: Colors.teal),
                ),
              ),
              const SizedBox(height: 20),

              TabBar(
                controller: _tab,
                labelColor: Colors.teal,
                indicatorColor: Colors.teal,
                onTap: (_) {
                  if (mounted) setState(() => _pesanGalat = null);
                },
                tabs: const [
                  Tab(text: 'Masuk'),
                  Tab(text: 'Daftar'),
                ],
              ),
              const SizedBox(height: 20),

              if (_tab.index == 1) ...[
                TextFormField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 14),
              ],

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                  if (!v.contains('@')) return 'Format email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) =>
                    (v == null || v.length < 8) ? 'Password minimal 8 karakter' : null,
              ),

              if (_tab.index == 1) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _konfirmasiController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Ulangi Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (v) =>
                      (v != _passwordController.text) ? 'Konfirmasi tidak cocok' : null,
                ),
              ],

              const SizedBox(height: 16),

              if (_pesanGalat != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _pesanGalat!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),

              FilledButton(
                onPressed: _sedangProses ? null : _prosesEmail,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _sedangProses
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _tab.index == 1 ? 'Daftar Sekarang' : 'Masuk',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'atau',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: _sedangProses ? null : _prosesGoogle,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  backgroundColor: Colors.white,
                ),
                icon: const _LogoGoogle(),
                label: const Text(
                  'Masuk dengan Google',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logo "G" sederhana (tanpa dependensi tambahan).
class _LogoGoogle extends StatelessWidget {
  const _LogoGoogle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFF34A853)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
