import 'package:flutter/material.dart';

import '../models/pesanan_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../utils/url_berkas.dart';
import '../widgets/widget_keadaan.dart';
import 'beranda_screen.dart';
import 'katalog_screen.dart';
import 'keranjang_screen.dart';
import 'pesanan_detail_screen.dart';
import 'profil_screen.dart';

class RiwayatPesananScreen extends StatefulWidget {
  const RiwayatPesananScreen({super.key});

  @override
  State<RiwayatPesananScreen> createState() => _RiwayatPesananScreenState();
}

class _RiwayatPesananScreenState extends State<RiwayatPesananScreen> {
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  InfoGalat? _galat;
  List<PesananModel> _semuaPesanan = [];

  // Filter & Search states
  int _tabFilter = 0; // 0: Semua, 1: Berlangsung, 2: Selesai
  final TextEditingController _pencarianController = TextEditingController();
  DateTimeRange? _rentangTanggal;
  int _jumlahItemKeranjang = 0;
  int _navIndex = 3; // Index Riwayat

  @override
  void initState() {
    super.initState();
    _muatRiwayat();
    _muatJumlahKeranjang();
  }

  @override
  void dispose() {
    _pencarianController.dispose();
    super.dispose();
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

  Future<void> _muatRiwayat() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _galat = null;
    });

    try {
      final list = await LayananApi.getPesananList();
      if (!mounted) return;

      setState(() {
        _semuaPesanan = list;
        _keadaan = list.isEmpty ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
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

  bool _apakahPesananBerlangsung(String status) {
    final s = status.toLowerCase();
    return s == 'menunggu_pembayaran' ||
        s == 'menunggu_konfirmasi' ||
        s == 'diproses' ||
        s == 'dikirim' ||
        s == 'dibayar';
  }

  bool _apakahPesananSelesai(String status) {
    final s = status.toLowerCase();
    return s == 'selesai' || s == 'dibatalkan';
  }

  List<PesananModel> get _daftarPesananTersaring {
    final keyword = _pencarianController.text.trim().toLowerCase();

    return _semuaPesanan.where((p) {
      // 1. Filter Tab
      if (_tabFilter == 1 && !_apakahPesananBerlangsung(p.status)) {
        return false;
      }
      if (_tabFilter == 2 && !_apakahPesananSelesai(p.status)) {
        return false;
      }

      // 2. Filter Tanggal
      if (_rentangTanggal != null) {
        final parsedDate = DateTime.tryParse(p.createdAt);
        if (parsedDate != null) {
          final start = DateTime(
            _rentangTanggal!.start.year,
            _rentangTanggal!.start.month,
            _rentangTanggal!.start.day,
          );
          final end = DateTime(
            _rentangTanggal!.end.year,
            _rentangTanggal!.end.month,
            _rentangTanggal!.end.day,
            23,
            59,
            59,
          );
          if (parsedDate.isBefore(start) || parsedDate.isAfter(end)) {
            return false;
          }
        }
      }

      // 3. Filter Search
      if (keyword.isNotEmpty) {
        final cocokNomor = p.nomorPesanan.toLowerCase().contains(keyword);
        final cocokPenerima = p.namaPenerima.toLowerCase().contains(keyword);
        final cocokProduk = p.details.any(
          (d) => d.namaProduk.toLowerCase().contains(keyword),
        );
        final cocokMetode = p.metodePembayaran.toLowerCase().contains(keyword);
        return cocokNomor || cocokPenerima || cocokProduk || cocokMetode;
      }

      return true;
    }).toList();
  }

  int get _hitungBerlangsung =>
      _semuaPesanan.where((p) => _apakahPesananBerlangsung(p.status)).length;

  int get _hitungSelesai =>
      _semuaPesanan.where((p) => _apakahPesananSelesai(p.status)).length;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return const Color(0xFF16A34A);
      case 'dibayar':
      case 'diproses':
        return const Color(0xFF0284C7);
      case 'dikirim':
        return const Color(0xFF4F46E5);
      case 'menunggu_pembayaran':
      case 'menunggu_konfirmasi':
        return const Color(0xFFD97706);
      case 'dibatalkan':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return const Color(0xFFDCFCE7);
      case 'dibayar':
      case 'diproses':
        return const Color(0xFFE0F2FE);
      case 'dikirim':
        return const Color(0xFFEEF2FF);
      case 'menunggu_pembayaran':
      case 'menunggu_konfirmasi':
        return const Color(0xFFFEF3C7);
      case 'dibatalkan':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  String _formatStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu_pembayaran':
        return 'MENUNGGU';
      case 'menunggu_konfirmasi':
        return 'KONFIRMASI';
      case 'diproses':
        return 'DIPROSES';
      case 'dikirim':
        return 'DIKIRIM';
      case 'dibayar':
        return 'DIBAYAR';
      case 'selesai':
        return 'SELESAI';
      case 'dibatalkan':
        return 'DIBATALKAN';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  IconData _getMetodeIcon(String metode) {
    final m = metode.toLowerCase();
    if (m.contains('xendit')) {
      return Icons.qr_code_2_rounded;
    } else if (m.contains('cod')) {
      return Icons.local_shipping_outlined;
    } else {
      return Icons.account_balance_outlined;
    }
  }

  String _formatMetodeLabel(String metode) {
    final m = metode.toLowerCase();
    if (m.contains('xendit')) {
      return 'Xendit Gateway';
    } else if (m.contains('cod')) {
      return 'Cash on Delivery (COD)';
    } else if (m.contains('transfer')) {
      return 'Transfer Manual';
    }
    return metode.toUpperCase();
  }

  String _formatWaktu(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const bulan = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      final jam = dt.hour.toString().padLeft(2, '0');
      final menit = dt.minute.toString().padLeft(2, '0');
      return '${dt.day.toString().padLeft(2, '0')} ${bulan[dt.month - 1]} ${dt.year}, $jam:$menit WIB';
    } catch (_) {
      return raw;
    }
  }

  void _tampilkanDialogResep(PesananModel pesanan) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Color(0xFF0284C7),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Resep Dokter Terverifikasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nomor Resep Dokter:',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pesanan.nomorResep ?? '-',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      const Divider(height: 20, color: Color(0xFFE2E8F0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pasien / Penerima:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            pesanan.namaPenerima,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status Validasi Farmasi:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Disetujui Apoteker',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _tampilkanBantuanApoteker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: Color(0xFF0284C7),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Layanan Konsultasi Farmasi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Apotek Sugeng — Apoteker Berlisensi SIPA',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ada kendala dengan pesanan obat Anda, instruksi resep dokter, atau aturan minum? Tim apoteker kami siap membantu:',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFDCFCE7),
                    child: Icon(Icons.chat_rounded, color: Color(0xFF16A34A)),
                  ),
                  title: const Text(
                    'Chat WhatsApp Apoteker',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text('0812-3456-7890 (Aktif 24 Jam)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menghubungkan ke WhatsApp Apoteker...'),
                        backgroundColor: Color(0xFF0284C7),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(Icons.phone_in_talk_rounded, color: Color(0xFF0284C7)),
                  ),
                  title: const Text(
                    'Telepon Unit Farmasi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text('(0274) 555-8890 (Ext. Farmasi)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Memanggil Hotline Apotek Sugeng...'),
                        backgroundColor: Color(0xFF0284C7),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onBottomNavTapped(int index) async {
    if (index == 3) {
      setState(() => _navIndex = 3);
      return;
    }

    if (index == 0) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BerandaScreen()),
      );
    } else if (index == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const KatalogScreen()),
      );
    } else if (index == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const KeranjangScreen()),
      );
    } else if (index == 4) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilScreen()),
      );
    }

    if (mounted) {
      setState(() => _navIndex = 3);
      _muatJumlahKeranjang();
    }
  }

  Widget _buildTopHeader() {
    final namaPengguna = SesiAuth.pengguna?.nama ?? 'Tamu (Guest)';
    final fotoUrl = UrlBerkas.dari(SesiAuth.pengguna?.fotoUrl);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Apotek Sugeng',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Riwayat Pesanan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF334155),
                  size: 24,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tidak ada pemberitahuan baru'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilScreen(),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFF0284C7),
                  backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
                  child: fotoUrl == null
                      ? Text(
                          namaPengguna.isNotEmpty
                              ? namaPengguna.substring(0, 1).toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(
            index: 0,
            label: 'Semua (${_semuaPesanan.length})',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            index: 1,
            label: 'Berlangsung ($_hitungBerlangsung)',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            index: 2,
            label: 'Selesai ($_hitungSelesai)',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required int index, required String label}) {
    final terpilih = _tabFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tabFilter = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: terpilih ? const Color(0xFF005B82) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: terpilih
                  ? const Color(0xFF005B82)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: terpilih ? FontWeight.bold : FontWeight.w500,
              color: terpilih ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _pencarianController,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(fontSize: 13),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Cari nomor nota atau pesanan...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  suffixIcon: _pencarianController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          onPressed: () {
                            _pencarianController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final hasil = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                initialDateRange: _rentangTanggal,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF0284C7),
                        onPrimary: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (hasil != null) {
                setState(() => _rentangTanggal = hasil);
              }
            },
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: _rentangTanggal != null
                    ? const Color(0xFFE0F2FE)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _rentangTanggal != null
                      ? const Color(0xFF0284C7)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: _rentangTanggal != null
                    ? const Color(0xFF0284C7)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
          if (_rentangTanggal != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.clear, size: 18, color: Colors.red),
              onPressed: () {
                setState(() => _rentangTanggal = null);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKartuPesanan(PesananModel pesanan) {
    final statusWarna = _getStatusColor(pesanan.status);
    final statusBg = _getStatusBgColor(pesanan.status);
    final statusLabel = _formatStatusLabel(pesanan.status);
    final adaResep = pesanan.nomorResep != null &&
        pesanan.nomorResep!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris 1: Ikon, Nomor Pesanan, Metode, dan Status Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getMetodeIcon(pesanan.metodePembayaran),
                    color: const Color(0xFF0284C7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pesanan.nomorPesanan,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            _getMetodeIcon(pesanan.metodePembayaran),
                            size: 13,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatMetodeLabel(pesanan.metodePembayaran),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusWarna,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusWarna,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Baris 2: Rincian Produk & Waktu Transaksi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pesanan.details.length} Produk Farmasi',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formatRupiah(pesanan.total),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Waktu Transaksi',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatWaktu(pesanan.createdAt),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Catatan kurir jika pesanan dikirim
            if (pesanan.status.toLowerCase() == 'dikirim') ...[
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(
                    Icons.motorcycle_outlined,
                    size: 15,
                    color: Color(0xFF0284C7),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Menunggu penjemputan kurir farmasi',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF0284C7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Baris 3: Tombol Aksi (Lihat Resep, Detail, Beli Lagi / Lacak Kurir)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (adaResep) ...[
                  OutlinedButton.icon(
                    onPressed: () => _tampilkanDialogResep(pesanan),
                    icon: const Icon(Icons.description_outlined, size: 15),
                    label: const Text(
                      'Lihat Resep',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0284C7),
                      side: const BorderSide(color: Color(0xFFBAE6FD)),
                      backgroundColor: const Color(0xFFF0F9FF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PesananDetailScreen(pesananId: pesanan.id),
                      ),
                    );
                    if (!mounted) return;
                    _muatRiwayat();
                  },
                  icon: const Icon(Icons.receipt_outlined, size: 15),
                  label: const Text(
                    'Detail',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    backgroundColor: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (pesanan.status.toLowerCase() == 'dikirim' &&
                        pesanan.kurir != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Kurir: ${pesanan.kurir?.nama ?? "Ekspedisi"} (${pesanan.kurir?.wilayah ?? "Siap Kirim"})',
                          ),
                          backgroundColor: const Color(0xFF0284C7),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      // Buka kembali detail pesanan untuk melihat / beli ulang
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PesananDetailScreen(pesananId: pesanan.id),
                        ),
                      );
                      if (!mounted) return;
                      _muatRiwayat();
                    }
                  },
                  icon: Icon(
                    pesanan.status.toLowerCase() == 'dikirim' &&
                            pesanan.kurir != null
                        ? Icons.location_on_outlined
                        : Icons.replay_outlined,
                    size: 15,
                  ),
                  label: Text(
                    pesanan.status.toLowerCase() == 'dikirim' &&
                            pesanan.kurir != null
                        ? 'Lacak Kurir'
                        : 'Beli Lagi',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005B82),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpBanner() {
    return InkWell(
      onTap: _tampilkanBantuanApoteker,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDBEAFE)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: const BoxDecoration(
                color: Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Color(0xFF0284C7),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Butuh bantuan pesanan obat?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Apoteker kami siap memandu konsultasi resep & dosis setiap hari.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Color(0xFF0284C7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
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
      child: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: _onBottomNavTapped,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE0F2FE),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.home, color: Color(0xFF0284C7)),
            label: 'Beranda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.grid_view, color: Color(0xFF0284C7)),
            label: 'Katalog',
          ),
          NavigationDestination(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  color: Color(0xFF64748B),
                ),
                if (_jumlahItemKeranjang > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0284C7),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
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
            selectedIcon: const Icon(
              Icons.shopping_bag,
              color: Color(0xFF0284C7),
            ),
            label: 'Keranjang',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.receipt_long, color: Color(0xFF0284C7)),
            label: 'Riwayat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.person, color: Color(0xFF0284C7)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _daftarPesananTersaring;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(),
            _buildFilterTabs(),
            _buildSearchBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _muatRiwayat();
                  await _muatJumlahKeranjang();
                },
                color: const Color(0xFF0284C7),
                child: WidgetKeadaan(
                  keadaan: _keadaan,
                  galat: _galat,
                  pesanKosong: _pencarianController.text.isNotEmpty ||
                          _tabFilter != 0 ||
                          _rentangTanggal != null
                      ? 'Tidak ada pesanan yang sesuai dengan filter atau kata kunci.'
                      : 'Anda belum memiliki riwayat pesanan obat.',
                  onCobaLagi: () {
                    _muatRiwayat();
                    _muatJumlahKeranjang();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: list.length + 1,
                    itemBuilder: (context, index) {
                      if (index == list.length) {
                        return _buildHelpBanner();
                      }
                      final p = list[index];
                      return _buildKartuPesanan(p);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}
