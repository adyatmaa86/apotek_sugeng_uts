import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/beranda_controller.dart';
import '../controllers/keranjang_controller.dart';
import '../models/produk_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../utils/url_berkas.dart';
import '../widgets/beranda/beranda_alat_medis_list.dart';
import '../widgets/beranda/beranda_error_banner.dart';
import '../widgets/beranda/beranda_kategori_bar.dart';
import '../widgets/beranda/beranda_layanan_apoteker.dart';
import '../widgets/beranda/beranda_produk_terlaris.dart';
import '../widgets/beranda/beranda_promo_banner.dart';
import '../widgets/beranda/beranda_search_bar.dart';
import '../widgets/beranda/beranda_top_header.dart';
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

  void _bukaDetailProduk(ProdukModel produk) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProdukDetailScreen(produkId: produk.id),
      ),
    );
  }

  void _bukaKatalog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KatalogScreen(),
      ),
    );
  }

  Future<void> _bukaKeranjang() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KeranjangScreen(),
      ),
    );
    _muatJumlahKeranjang();
    _muatData();
  }

  Future<void> _bukaKelolaProduk() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KelolaProdukScreen(),
      ),
    );
    _muatData();
    _muatConfig();
  }

  Future<void> _bukaProfil() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilScreen(),
      ),
    );
  }

  Widget _buildTopHeaderWidget(String namaPengguna, String? fotoUrl) {
    return BerandaTopHeader(
      namaPengguna: namaPengguna,
      fotoUrl: fotoUrl,
      modeUtsAktif: _modeUtsAktif,
      jumlahItemKeranjang: _jumlahItemKeranjang,
      onTapModeUts: _bukaKelolaProduk,
      onTapKeranjang: _bukaKeranjang,
      onTapProfil: _bukaProfil,
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

      // KONDISI 1: Belum ada produk dan server gagal terhubung
      if (_daftarProduk.isEmpty && _keadaan == KeadaanMuat.galat) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Column(
              children: [
                _buildTopHeaderWidget(namaPengguna, fotoUrl),
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
                _buildTopHeaderWidget(namaPengguna, fotoUrl),
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
                  child: _buildTopHeaderWidget(namaPengguna, fotoUrl),
                ),

                // Banner Peringatan jika koneksi terputus saat sudah ada data
                if (_galat != null)
                  SliverToBoxAdapter(
                    child: BerandaErrorBanner(
                      pesan: _galat!.pesan,
                      onCobaLagi: () {
                        _muatData();
                        _muatJumlahKeranjang();
                      },
                    ),
                  ),

                // 2. Search & Filter Bar
                SliverToBoxAdapter(
                  child: BerandaSearchBar(
                    controller: _searchController,
                    onSubmitted: (_) => _muatData(),
                    onClear: () {
                      _searchController.clear();
                      _muatData();
                    },
                    onFilterTap: () => _muatData(),
                  ),
                ),

                // 3. Banner Promo / Gratis Ongkir
                SliverToBoxAdapter(
                  child: BerandaPromoBanner(onTapKatalog: _bukaKatalog),
                ),

                // 4. Layanan Apoteker / Resep Dokter Card
                SliverToBoxAdapter(
                  child: BerandaLayananApoteker(onTapInfo: _tampilkanInfoResep),
                ),

                // 5. Kategori Produk
                SliverToBoxAdapter(
                  child: BerandaKategoriBar(
                    kategoriList: _kategoriList,
                    kategoriDipilih: _kategoriDipilih,
                    onSelectKategori: (kat) => _c.gantiKategori(kat),
                    onLihatSemua: _bukaKatalog,
                  ),
                ),

                // 6. Produk Terlaris (Horizontal List)
                SliverToBoxAdapter(
                  child: BerandaProdukTerlaris(
                    daftarProduk: listTerlaris,
                    onTapProduk: _bukaDetailProduk,
                    onTambahKeranjang: _tambahItemKeranjang,
                  ),
                ),

                // 7. Rekomendasi Medis (Header)
                SliverToBoxAdapter(
                  child: BerandaAlatMedisList(
                    produkList: produkAlatKesehatan,
                    hasMore: _hasMore,
                    onTapProduk: _bukaDetailProduk,
                    onTambahKeranjang: _tambahItemKeranjang,
                  ),
                ),

                // 7b. Rekomendasi Medis (Vertical Sliver List)
                BerandaAlatMedisSliverList(
                  produkList: produkAlatKesehatan,
                  hasMore: _hasMore,
                  onTapProduk: _bukaDetailProduk,
                  onTambahKeranjang: _tambahItemKeranjang,
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
