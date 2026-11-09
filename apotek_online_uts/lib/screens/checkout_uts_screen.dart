import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/keranjang_model.dart';
import '../models/kurir_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../utils/url_berkas.dart';
import 'pesanan_detail_screen.dart';
import 'profil_screen.dart';

class CheckoutUtsScreen extends StatefulWidget {
  final KeranjangDataModel keranjangData;

  const CheckoutUtsScreen({super.key, required this.keranjangData});

  @override
  State<CheckoutUtsScreen> createState() => _CheckoutUtsScreenState();
}

class _CheckoutUtsScreenState extends State<CheckoutUtsScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaController = TextEditingController(
    text: SesiAuth.pengguna?.nama.isNotEmpty == true
        ? SesiAuth.pengguna!.nama
        : 'Ceo Adyatma86',
  );
  final TextEditingController _teleponController = TextEditingController(
    text: '0812-3456-7890',
  );
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _resepController = TextEditingController();

  late final String _idempotencyKey;

  List<KurirModel> _daftarKurir = [];
  KurirModel? _kurirDipilih;
  bool _isMemuatKurir = false;
  String? _galatKurir;

  String _metodePembayaran = 'cod';

  bool _isSedangCheckout = false;
  InfoGalat? _galatCheckout;

  @override
  void initState() {
    super.initState();
    _idempotencyKey = const Uuid().v4();
    _muatKurir();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _alamatController.dispose();
    _resepController.dispose();
    super.dispose();
  }

  bool get _apakahAdaResep =>
      widget.keranjangData.items.any((item) => item.produk?.perluResep == true);

  int get _ongkir => _kurirDipilih?.tarif ?? 0;

  int get _totalEstimasi => widget.keranjangData.subtotal + _ongkir;

  Future<void> _muatKurir() async {
    setState(() {
      _isMemuatKurir = true;
      _galatKurir = null;
    });

    try {
      final kurir = await LayananApi.getKurir();
      if (!mounted) return;
      setState(() {
        _daftarKurir = kurir;
        if (kurir.isNotEmpty && _kurirDipilih == null) {
          _kurirDipilih = kurir.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galatKurir = e is InfoGalat ? e.pesan : e.toString();
      });
    } finally {
      if (mounted) setState(() => _isMemuatKurir = false);
    }
  }

  Future<void> _prosesCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    if (_kurirDipilih == null) {
      setState(
        () => _galatCheckout = InfoGalat(
          jenis: JenisGalat.lainnya,
          pesan: 'Pilih wilayah pengantaran kurir terlebih dahulu.',
        ),
      );
      return;
    }

    setState(() {
      _isSedangCheckout = true;
      _galatCheckout = null;
    });

    try {
      // Alamat digabung dengan nomor telepon kontak penerima
      final alamatLengkap =
          '${_alamatController.text.trim()} (Kontak/WA: ${_teleponController.text.trim()})';

      final pesanan = await LayananApi.checkout(
        idempotencyKey: _idempotencyKey,
        namaPenerima: _namaController.text.trim(),
        alamat: alamatLengkap,
        kurirId: _kurirDipilih!.id,
        metodePembayaran: _metodePembayaran,
        nomorResep: _resepController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan #${pesanan.nomorPesanan} berhasil dibuat!'),
          backgroundColor: const Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PesananDetailScreen(pesananId: pesanan.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galatCheckout = e is InfoGalat
            ? e
            : InfoGalat(jenis: JenisGalat.lainnya, pesan: e.toString());
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_galatCheckout!.pesan),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSedangCheckout = false);
    }
  }

  String _formatRupiah(num angka) {
    final s = angka.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(s[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final fotoUrl = UrlBerkas.dari(SesiAuth.pengguna?.fotoUrl);
    final namaPengguna = SesiAuth.pengguna?.nama ?? 'Tamu (Guest)';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              'Checkout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: const Text(
                'Mode UTS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0284C7),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilScreen()),
                );
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF0284C7),
                backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                    ? NetworkImage(fotoUrl)
                    : null,
                child: fotoUrl == null || fotoUrl.isEmpty
                    ? Text(
                        namaPengguna.isNotEmpty
                            ? namaPengguna.substring(0, 1).toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stepper / Status Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0284C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Langkah 1 dari 2',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            'Penerima & Pengiriman',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            color: Color(0xFF16A34A),
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Farmasi Resmi',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Banner Pesan Galat (jika ada)
              if (_galatCheckout != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _galatCheckout!.pesan,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 1. INFORMASI PENERIMA
              _buildCardSection(
                icon: Icons.person_outline,
                title: '1. Informasi Penerima',
                subtitle: 'Pastikan kontak pasien/penerima aktif',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nama Lengkap Penerima *',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _namaController,
                      style: const TextStyle(fontSize: 13),
                      decoration: _buildInputDecoration(
                        hint: 'Nama penerima',
                        prefixIcon: Icons.person_outline,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nomor WhatsApp / Telepon *',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _teleponController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 13),
                      decoration: _buildInputDecoration(
                        hint: '0812-3456-7890',
                        prefixIcon: Icons.phone_outlined,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nomor telepon wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Kurir farmasi akan menghubungi nomor ini saat pengantaran',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nomor Resep Dokter',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                        Text(
                          _apakahAdaResep
                              ? '* Wajib untuk obat keras'
                              : '(Opsional)',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: _apakahAdaResep
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _resepController,
                      style: const TextStyle(fontSize: 13),
                      decoration: _buildInputDecoration(
                        hint: 'Contoh: RSP-YK-2024-8849',
                        prefixIcon: Icons.receipt_long_outlined,
                      ),
                      validator: (v) {
                        if (_apakahAdaResep &&
                            (v == null || v.trim().isEmpty)) {
                          return 'Keranjang memuat obat keras, nomor resep dokter wajib diisi';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. ALAMAT & KURIR TOKO
              _buildCardSection(
                icon: Icons.location_on_outlined,
                title: '2. Alamat & Wilayah Pengiriman',
                subtitle: 'Tentukan lokasi pengantaran obat oleh kurir apotek',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail Alamat & Patokan Rumah *',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _alamatController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: _buildInputDecoration(
                        hint:
                            'Nama jalan, nomor rumah, RT/RW, kelurahan, dan patokan rumah...',
                        prefixIcon: Icons.home_outlined,
                      ),
                      validator: (v) => (v == null || v.trim().length < 8)
                          ? 'Alamat pengantaran minimal 8 karakter'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Pilih Zona Wilayah Antar Apotek *',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isMemuatKurir)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      )
                    else if (_galatKurir != null)
                      GestureDetector(
                        onTap: _muatKurir,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Text(
                            '$_galatKurir\nKetuk untuk memuat ulang kurir.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      )
                    else
                      ..._daftarKurir.map((kurir) {
                        final dipilih = _kurirDipilih?.id == kurir.id;
                        return InkWell(
                          onTap: () => setState(() => _kurirDipilih = kurir),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: dipilih
                                  ? const Color(0xFFF0F9FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: dipilih
                                    ? const Color(0xFF0284C7)
                                    : const Color(0xFFE2E8F0),
                                width: dipilih ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  dipilih
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: dipilih
                                      ? const Color(0xFF0284C7)
                                      : const Color(0xFF94A3B8),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        kurir.nama,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        '${kurir.wilayah} • Estimasi: ${kurir.estimasi}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatRupiah(kurir.tarif),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. METODE PEMBAYARAN
              _buildCardSection(
                icon: Icons.payment_outlined,
                title: '3. Metode Pembayaran',
                subtitle: 'Simulasi transaksi apotek tanpa pihak ketiga',
                content: Column(
                  children: [
                    _buildPaymentOption(
                      value: 'cod',
                      title: 'Bayar Tunai di Tempat (COD)',
                      subtitle:
                          'Pembayaran tunai diserahkan langsung ke kurir apotek saat obat tiba.',
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentOption(
                      value: 'transfer_manual',
                      title: 'Transfer Bank Manual',
                      subtitle:
                          'Transfer langsung ke rekening Bank Apotek Sugeng.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. RINGKASAN PESANAN
              _buildCardSection(
                icon: Icons.receipt_long_outlined,
                title: '4. Ringkasan Pesanan',
                subtitle:
                    '${widget.keranjangData.totalItem} Produk Farmasi Siap Dikirim',
                content: Column(
                  children: [
                    // Box Preview Item
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: widget.keranjangData.items.map((it) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.medication_outlined,
                                  color: Color(0xFF0284C7),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${it.produk?.nama ?? "Obat"} (${it.jumlah} ${it.produk?.satuan ?? "pcs"})',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF334155),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _formatRupiah(
                                    (it.produk?.harga ?? 0) * it.jumlah,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Baris Biaya
                    _buildRowBiaya(
                      'Subtotal Pesanan',
                      _formatRupiah(widget.keranjangData.subtotal),
                    ),
                    const SizedBox(height: 6),
                    _buildRowBiaya(
                      'Biaya Kirim Internal',
                      _formatRupiah(_ongkir),
                    ),
                    const SizedBox(height: 6),
                    _buildRowBiaya(
                      'Biaya Layanan & Kemasan',
                      'Gratis',
                      isGreen: true,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Color(0xFFE2E8F0)),
                    ),
                    _buildRowBiaya(
                      'Total Tagihan',
                      _formatRupiah(_totalEstimasi),
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Checkout Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Tagihan',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatRupiah(_totalEstimasi),
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: _isSedangCheckout ? null : _prosesCheckout,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0369A1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSedangCheckout
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Pesan Sekarang',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF0284C7), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
  }) {
    final dipilih = _metodePembayaran == value;
    return InkWell(
      onTap: () => setState(() => _metodePembayaran = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dipilih ? const Color(0xFFF0F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dipilih ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            width: dipilih ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                dipilih ? Icons.radio_button_checked : Icons.radio_button_off,
                color:
                    dipilih ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowBiaya(
    String label,
    String value, {
    bool isBold = false,
    bool isGreen = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 13 : 11.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isGreen
                ? const Color(0xFF16A34A)
                : isBold
                    ? const Color(0xFF0284C7)
                    : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 18),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
      ),
    );
  }
}
