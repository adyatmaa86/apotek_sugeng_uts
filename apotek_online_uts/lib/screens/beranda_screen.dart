import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/beranda_controller.dart';
import '../controllers/keranjang_controller.dart';
import '../models/produk_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../utils/url_berkas.dart';
import '../widgets/nav_bar_bawah.dart';
import '../widgets/widget_keadaan.dart';
import 'katalog_screen.dart';
import 'kelola_produk_screen.dart';
import 'keranjang_screen.dart';
import 'produk_detail_screen.dart';
import 'profil_screen.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  late final BerandaController _c;
  final ScrollController _scrollController = ScrollController();

  KeadaanMuat get _keadaan => _c.keadaan.value;
  InfoGalat? get _galat => _c.galat.value;
  List<ProdukModel> get _daftarProduk => _c.daftarProduk;
  String get _kategoriDipilih => _c.kategoriDipilih.value;
  List<String> get _kategoriList => _c.kategoriList;
  TextEditingController get _searchController => _c.searchController;
  bool get _hasMore => _c.hasMore.value;
  bool get _modeUtsAktif => _c.modeUtsAktif.value;
  int get _jumlahItemKeranjang => KeranjangController.to.totalItem;

  @override
  void initState() {
    super.initState();
    _c = Get.put(BerandaController());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      _c.muatLebih();
    }
  }

  Future<void> _muatData() => _c.muatData();
  Future<void> _muatConfig() => _c.muatConfig();
  Future<void> _muatJumlahKeranjang() =>
      KeranjangController.to.muatKeranjang(senyap: true);

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

  Future<void> _tambahItemKeranjang(ProdukModel produk) async {
    if (!produk.tersedia || produk.stok <= 0) return;

    try {
      await LayananApi.tambahKeranjang(produk.id, 1);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${produk.nama} ditambahkan ke keranjang'),
          backgroundColor: const Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 1),
        ),
      );
      _muatJumlahKeranjang();
    } catch (e) {
      if (!mounted) return;
      final pesan = e is InfoGalat ? e.pesan : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(pesan)),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Coba Lagi',
            textColor: Colors.white,
            onPressed: () => _tambahItemKeranjang(produk),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _tampilkanInfoResep() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.assignment_outlined, color: Color(0xFF0284C7)),
            SizedBox(width: 8),
            Text('Layanan Resep Dokter', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Untuk produk obat dengan tanda "Perlu Resep", sistem mewajibkan pengisian Nomor Resep Dokter yang sah saat Anda melakukan checkout pesanan.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'Hal ini sesuai dengan regulasi kefarmasian apotek untuk menjamin keamanan penggunaan obat keras bagi pasien.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
            ),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(String namaPengguna, String? fotoUrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          // Logo & Sapaan
          Image.asset(
            'assets/images/logo.png',
            width: 42,
            height: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Apotek Sugeng',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.verified,
                      size: 13,
                      color: const Color(0xFF0284C7),
                    ),
                  ],
                ),
                Text(
                  'Halo, $namaPengguna 👋',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Mode UTS Button (jika aktif & sedang login sebagai admin)
          if (_modeUtsAktif && AuthController.to.adminAktif)
            IconButton(
              icon: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF0284C7),
              ),
              tooltip: 'Kelola Produk (Mode UTS)',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const KelolaProdukScreen(),
                  ),
                );
                _muatData();
                _muatConfig();
              },
            ),

          // Keranjang Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const KeranjangScreen(),
                    ),
                  );
                  _muatJumlahKeranjang();
                  _muatData();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFF334155),
                      size: 20,
                    ),
                  ),
                ),
              ),
              if (_jumlahItemKeranjang > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0284C7),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 17,
                      minHeight: 17,
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
          const SizedBox(width: 8),

          // Profile Avatar
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilScreen(),
                ),
              );
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF0284C7),
              backgroundImage:
                  fotoUrl != null && fotoUrl.isNotEmpty
                      ? NetworkImage(fotoUrl)
                      : null,
              child: fotoUrl == null || fotoUrl.isEmpty
                  ? Text(
                      namaPengguna.isNotEmpty
                          ? namaPengguna.substring(0, 1).toUpperCase()
                          : 'T',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final namaPengguna = AuthController.to.pengguna.value?.nama ?? 'Tamu (Guest)';
      final fotoUrl = UrlBerkas.dari(AuthController.to.pengguna.value?.fotoUrl);
      final produkAlatKesehatan = _daftarProduk
          .where((p) => p.kategori == 'Alat Kesehatan')
          .toList();

      // KONDISI 1: Belum ada produk dan server gagal terhubung (Galat Sambungan / Timeout)
      if (_daftarProduk.isEmpty && _keadaan == KeadaanMuat.galat) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Column(
            children: [
              _buildTopHeader(namaPengguna, fotoUrl),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _muatData();
                    await _muatJumlahKeranjang();
                    await _muatConfig();
                  },
                  color: const Color(0xFF0284C7),
                  child: WidgetKeadaan(
                    keadaan: _keadaan,
                    galat: _galat,
                    onCobaLagi: () {
                      _muatData();
                      _muatJumlahKeranjang();
                      _muatConfig();
                    },
                    child: const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const NavBarBawah(currentIndex: 0),
      );
    }

    // KONDISI 2: Sedang memuat awal dan belum ada data
    if (_daftarProduk.isEmpty && _keadaan == KeadaanMuat.memuat) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopHeader(namaPengguna, fotoUrl),
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF0284C7)),
                      SizedBox(height: 16),
                      Text(
                        'Menghubungi server Apotek Sugeng...',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const NavBarBawah(currentIndex: 0),
      );
    }

    // KONDISI 3: Data ada (atau kosong hasil filter pencarian)
    final produkTerlaris = List<ProdukModel>.from(_daftarProduk)
      ..sort((a, b) => b.stok.compareTo(a.stok));
    final listTerlaris = produkTerlaris.take(6).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _muatData();
            await _muatJumlahKeranjang();
            await _muatConfig();
          },
          color: const Color(0xFF0284C7),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 1. Header / Top Bar
              SliverToBoxAdapter(
                child: _buildTopHeader(namaPengguna, fotoUrl),
              ),

              // Banner Peringatan jika koneksi terputus saat sudah ada data
              if (_galat != null)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _galat!.pesan,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _muatData();
                            _muatJumlahKeranjang();
                          },
                          child: const Text(
                            'Coba Lagi',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 2. Search & Filter Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x05000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Cari obat, vitamin, atau alat kesehatan...',
                              hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12.5,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xFF94A3B8),
                                size: 20,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        _muatData();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (_) {},
                            onSubmitted: (_) => _muatData(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0369A1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          tooltip: 'Filter',
                          onPressed: () => _muatData(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Banner Promo / Gratis Ongkir
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/banner.jpeg'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x330284C7),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            const Color(0xFF0284C7).withValues(alpha: 0.90),
                            const Color(0xFF0284C7).withValues(alpha: 0.65),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.58, 1.0],
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.discount_outlined,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Diskon s/d 40%',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Gratis Ongkir Obat &\nResep Medis',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 1),
                                        blurRadius: 3,
                                        color: Colors.black38,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Pengiriman kilat 1 jam sampai & dijamin aman oleh apoteker resmi.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    height: 1.3,
                                    fontWeight: FontWeight.w500,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 1),
                                        blurRadius: 2,
                                        color: Colors.black26,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const KatalogScreen(),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Lihat Katalog',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 13,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Expanded(
                            flex: 4,
                            child: SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Layanan Apoteker / Resep Dokter Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCCFBF1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF99F6E4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment_outlined,
                            color: Color(0xFF0F766E),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'LAYANAN APOTEKER',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal.shade800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade700,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'SIP Berlisensi',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: Colors.teal.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Punya Resep Dokter?',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const Text(
                                'Siapkan nomor resep saat checkout obat berlabel Perlu Resep.',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _tampilkanInfoResep,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Info',
                                  style: TextStyle(
                                    color: Colors.white,
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
                ),
              ),

              // 5. Kategori Produk
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kategori Produk',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const KatalogScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Kategori Chips
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 38,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _kategoriList.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final kat = _kategoriList[index];
                      final isSelected = kat == _kategoriDipilih;
                      return InkWell(
                        onTap: () {
                          _c.gantiKategori(kat);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0284C7)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0284C7)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                index == 0
                                    ? Icons.grid_view_rounded
                                    : index == 1
                                        ? Icons.medication_rounded
                                        : Icons.medical_services_rounded,
                                size: 14,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                kat,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF334155),
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 6. Produk Terlaris (Horizontal List)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Produk Terlaris',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Top Penjualan',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Horizontal Cards Produk Terlaris
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 236,
                  child: listTerlaris.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada produk tersedia',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: listTerlaris.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final produk = listTerlaris[index];
                            final foto = UrlBerkas.dari(produk.fotoUrl);
                            final isHabis = !produk.tersedia || produk.stok <= 0;

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProdukDetailScreen(produkId: produk.id),
                                  ),
                                );
                              },
                              child: Container(
                                width: 158,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x05000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image & Tag
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(15),
                                          ),
                                          child: SizedBox(
                                            height: 110,
                                            width: double.infinity,
                                            child: foto != null
                                                ? Image.network(
                                                    foto,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, _, _) =>
                                                        Container(
                                                      color:
                                                          const Color(0xFFF1F5F9),
                                                      child: const Icon(
                                                        Icons.medication_outlined,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  )
                                                : Container(
                                                    color: const Color(0xFFF1F5F9),
                                                    child: const Icon(
                                                      Icons.medication_outlined,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.92,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              produk.kategori,
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF334155),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (produk.perluResep)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 5,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade600,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Resep',
                                                style: TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isHabis
                                                ? 'Stok Habis'
                                                : 'Stok: ${produk.stok} ${produk.satuan}',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              color: isHabis
                                                  ? Colors.red
                                                  : const Color(0xFF64748B),
                                              fontWeight: isHabis
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            produk.nama,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                              height: 1.2,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _formatRupiah(produk.harga),
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: isHabis
                                                    ? null
                                                    : () => _tambahItemKeranjang(
                                                          produk,
                                                        ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Container(
                                                  width: 30,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    color: isHabis
                                                        ? const Color(0xFFE2E8F0)
                                                        : const Color(0xFF38BDF8),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    Icons.add,
                                                    color: isHabis
                                                        ? Colors.grey
                                                        : Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),

              // 7. Rekomendasi Medis (Vertical List)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Rekomendasi Alat Medis',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 13,
                            color: const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Teruji Klinis',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF0284C7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Daftar Produk Vertikal - hanya Alat Kesehatan
              if (produkAlatKesehatan.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'Tidak ada alat kesehatan tersedia.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == produkAlatKesehatan.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          );
                        }

                        final produk = produkAlatKesehatan[index];
                        final foto = UrlBerkas.dari(produk.fotoUrl);
                        final isHabis = !produk.tersedia || produk.stok <= 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x05000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProdukDetailScreen(produkId: produk.id),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 76,
                                      height: 76,
                                      color: const Color(0xFFF1F5F9),
                                      child: foto != null
                                          ? Image.network(
                                              foto,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  const Icon(
                                                Icons.medication_outlined,
                                                color: Colors.grey,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.medication_outlined,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Detail Produk
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Badges
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isHabis
                                                    ? const Color(0xFFFEE2E2)
                                                    : const Color(0xFFE0F2FE),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isHabis
                                                    ? 'STOK HABIS'
                                                    : '${produk.kategori} • Sisa: ${produk.stok}',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: isHabis
                                                      ? Colors.red.shade700
                                                      : const Color(0xFF0369A1),
                                                ),
                                              ),
                                            ),
                                            if (produk.perluResep) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 5,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Resep',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red.shade700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),

                                        // Nama
                                        Text(
                                          produk.nama,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),

                                        // Deskripsi
                                        Text(
                                          produk.deskripsi ??
                                              'Satuan: ${produk.satuan}',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: Color(0xFF64748B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),

                                        // Harga
                                        Text(
                                          _formatRupiah(produk.harga),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Tombol Plus (+) / Habis
                                  if (isHabis)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.block,
                                            size: 13,
                                            color: Color(0xFF94A3B8),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Habis',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF94A3B8),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    InkWell(
                                      onTap: () => _tambahItemKeranjang(produk),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF38BDF8),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: produkAlatKesehatan.length + (_hasMore ? 1 : 0),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),

      // 8. Bottom Navigation Bar
      bottomNavigationBar: const NavBarBawah(currentIndex: 0),
    );
    });
  }
}
