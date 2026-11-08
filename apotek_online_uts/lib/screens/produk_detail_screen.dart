import 'package:flutter/material.dart';

import '../models/produk_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../utils/url_berkas.dart';
import '../widgets/widget_keadaan.dart';
import 'keranjang_screen.dart';

class ProdukDetailScreen extends StatefulWidget {
  final int produkId;

  const ProdukDetailScreen({super.key, required this.produkId});

  @override
  State<ProdukDetailScreen> createState() => _ProdukDetailScreenState();
}

class _ProdukDetailScreenState extends State<ProdukDetailScreen> {
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  InfoGalat? _galat;
  ProdukModel? _produk;

  int _jumlah = 1;
  bool _sedangMenambah = false;
  int _jumlahItemKeranjang = 0;

  @override
  void initState() {
    super.initState();
    _muatDetail();
    _muatJumlahKeranjang();
  }

  Future<void> _muatJumlahKeranjang() async {
    try {
      final keranjang = await LayananApi.getKeranjang();
      if (!mounted) return;
      setState(() {
        _jumlahItemKeranjang = keranjang.totalItem;
      });
    } catch (_) {}
  }

  Future<void> _muatDetail() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _galat = null;
    });

    try {
      final p = await LayananApi.getProdukDetail(widget.produkId);
      if (!mounted) return;

      setState(() {
        _produk = p;
        _keadaan = KeadaanMuat.berhasil;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _galat = e is InfoGalat
            ? e
            : InfoGalat(jenis: JenisGalat.lainnya, pesan: e.toString());
        _keadaan = KeadaanMuat.galat;
      });
    }
  }

  Future<void> _tambahKeKeranjang() async {
    if (_produk == null) return;

    setState(() => _sedangMenambah = true);

    try {
      await LayananApi.tambahKeranjang(_produk!.id, _jumlah);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$_jumlah ${_produk!.satuan} berhasil ditambahkan ke keranjang',
          ),
          backgroundColor: const Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const KeranjangScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      final pesan = e is InfoGalat ? e.pesan : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesan),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sedangMenambah = false);
    }
  }

  Widget _buildRowDetail(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isHighlight ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _produk;
    final isHabis = p == null || !p.tersedia || p.stok <= 0;
    final fotoUrl = p != null ? UrlBerkas.dari(p.fotoUrl) : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Detail Produk',
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
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF334155)),
                tooltip: 'Keranjang',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const KeranjangScreen(),
                    ),
                  ).then((_) => _muatJumlahKeranjang());
                },
              ),
              if (_jumlahItemKeranjang > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0284C7),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_jumlahItemKeranjang',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: WidgetKeadaan(
        keadaan: _keadaan,
        galat: _galat,
        onCobaLagi: _muatDetail,
        child: p == null
            ? const SizedBox()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gambar Produk
                    Container(
                      width: double.infinity,
                      height: 240,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (fotoUrl != null && fotoUrl.isNotEmpty)
                            Image.network(
                              fotoUrl,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, _, _) => Icon(
                                p.kategori == 'Obat'
                                    ? Icons.medication_liquid_outlined
                                    : Icons.medical_services_outlined,
                                size: 80,
                                color: const Color(0xFF0284C7),
                              ),
                            )
                          else
                            Icon(
                              p.kategori == 'Obat'
                                  ? Icons.medication_liquid_outlined
                                  : Icons.medical_services_outlined,
                              size: 80,
                              color: const Color(0xFF0284C7),
                            ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                p.kategori,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.verified,
                                    size: 13,
                                    color: Color(0xFF16A34A),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '100% Asli',
                                    style: TextStyle(
                                      color: Color(0xFF16A34A),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Banner jika butuh resep dokter
                    if (p.perluResep)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEE2E2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFDC2626),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Obat Keras — Perlu Resep Dokter',
                                    style: TextStyle(
                                      color: Color(0xFF991B1B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Wajib menyertakan nomor atau foto resep dokter saat checkout.',
                                    style: TextStyle(
                                      color: Color(0xFFB91C1C),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Nama Produk & Harga
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nama,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    formatRupiah(p.harga),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '/ ${p.satuan}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isHabis
                                      ? const Color(0xFFFEE2E2)
                                      : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isHabis ? 'Stok Habis' : 'Stok: ${p.stok}',
                                  style: TextStyle(
                                    color: isHabis
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF16A34A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Informasi Produk & Spesifikasi
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Produk & Medis',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildRowDetail('Satuan Kemasan', p.satuan),
                          const Divider(height: 12, color: Color(0xFFF1F5F9)),
                          _buildRowDetail('Stok Tersedia', '${p.stok} ${p.satuan}'),
                          const Divider(height: 12, color: Color(0xFFF1F5F9)),
                          _buildRowDetail(
                            'Batas Maks. Beli',
                            '${p.batasPerPembelian} item / transaksi',
                          ),
                          if (p.golongan != null && p.golongan!.isNotEmpty) ...[
                            const Divider(height: 12, color: Color(0xFFF1F5F9)),
                            _buildRowDetail('Golongan Obat', p.golongan!, isHighlight: true),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Deskripsi Produk
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deskripsi & Aturan Pakai',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.deskripsi ??
                                'Belum ada deskripsi dan aturan pakai khusus untuk produk ini. Konsultasikan dengan apoteker kami jika diperlukan panduan dosis.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF475569),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Jaminan Apotek Sugeng
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.verified_user_outlined,
                            color: Color(0xFF0284C7),
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Apotek Sugeng berlisensi SIPA & SIA. Semua produk farmasi dijamin keasliannya dan disimpan sesuai standar CDOB BPOM.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF334155),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: isHabis
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: const Text(
                'Produk saat ini sedang habis atau tidak tersedia untuk dibeli.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Stepper Kuantitas
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          color: const Color(0xFF334155),
                          onPressed: _jumlah > 1
                              ? () => setState(() => _jumlah--)
                              : null,
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 28),
                          alignment: Alignment.center,
                          child: Text(
                            '$_jumlah',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          color: const Color(0xFF334155),
                          onPressed:
                              _jumlah < p.stok && _jumlah < p.batasPerPembelian
                                  ? () => setState(() => _jumlah++)
                                  : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Tombol Tambah ke Keranjang
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _sedangMenambah ? null : _tambahKeKeranjang,
                        icon: _sedangMenambah
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.shopping_bag_outlined, size: 18),
                        label: Text(
                          _sedangMenambah
                              ? 'Menambahkan...'
                              : 'Tambah ke Keranjang',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF005B82),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
