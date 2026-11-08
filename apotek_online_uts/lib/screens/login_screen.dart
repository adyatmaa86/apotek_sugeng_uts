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
  bool _sembunyikanPassword = true;
  bool _sembunyikanKonfirmasi = true;
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

  Future<void> _prosesGoogle() async {
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

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF0284C7), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Akun Pasien & Pembeli',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Apotek Sugeng
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDBEAFE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_pharmacy_rounded,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Masuk agar riwayat pesanan obat dan resep tersimpan aman di akun Anda. Tanpa login, Anda tetap dapat bertransaksi lewat mode simulasi UTS.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E3A8A),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tab Selector (Masuk / Daftar)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x10000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  labelColor: const Color(0xFF005B82),
                  unselectedLabelColor: const Color(0xFF64748B),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  onTap: (_) {
                    if (mounted) setState(() => _pesanGalat = null);
                  },
                  tabs: const [
                    Tab(text: 'Masuk'),
                    Tab(text: 'Daftar Baru'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form Fields Container
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_tab.index == 1) ...[
                      TextFormField(
                        controller: _namaController,
                        decoration: _buildInputDecoration(
                          label: 'Nama Lengkap',
                          prefixIcon: Icons.person_outline,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),
                    ],

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration(
                        label: 'Email',
                        prefixIcon: Icons.email_outlined,
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
                      obscureText: _sembunyikanPassword,
                      decoration: _buildInputDecoration(
                        label: 'Password',
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _sembunyikanPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                            color: const Color(0xFF64748B),
                          ),
                          onPressed: () => setState(
                            () => _sembunyikanPassword = !_sembunyikanPassword,
                          ),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 8) ? 'Password minimal 8 karakter' : null,
                    ),

                    if (_tab.index == 1) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _konfirmasiController,
                        obscureText: _sembunyikanKonfirmasi,
                        decoration: _buildInputDecoration(
                          label: 'Ulangi Password',
                          prefixIcon: Icons.lock_reset_outlined,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _sembunyikanKonfirmasi
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: const Color(0xFF64748B),
                            ),
                            onPressed: () => setState(
                              () => _sembunyikanKonfirmasi =
                                  !_sembunyikanKonfirmasi,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            (v != _passwordController.text) ? 'Konfirmasi tidak cocok' : null,
                      ),
                    ],

                    if (_pesanGalat != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xFFDC2626),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _pesanGalat!,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton(
                        onPressed: _sedangProses ? null : _prosesEmail,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF005B82),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: const [
                  Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'atau masuk dengan',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                ],
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _sedangProses ? null : _prosesGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const _LogoGoogle(),
                  label: const Text(
                    'Masuk dengan Google',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      fontSize: 13.5,
                    ),
                  ),
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
