import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/katalog_controller.dart';
import '../controllers/keranjang_controller.dart';
import '../models/produk_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../utils/url_berkas.dart';
import '../widgets/katalog/katalog_filter_header.dart';
import '../widgets/katalog/katalog_grid_sliver.dart';
import '../widgets/katalog/katalog_top_app_bar.dart';
import '../widgets/nav_bar_bawah.dart';
import '../widgets/widget_keadaan.dart';
import 'kelola_produk_screen.dart';
import 'keranjang_screen.dart';
import 'produk_detail_screen.dart';
import 'profil_screen.dart';
import 'riwayat_pesanan_screen.dart';

class KatalogScreen extends StatefulWidget {
  const KatalogScreen({super.key});

  @override
  State<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends State<KatalogScreen> {
  late final KatalogController _c;
  final ScrollController _scrollController = ScrollController();

  KeadaanMuat get _keadaan => _c.keadaan.value;
  InfoGalat? get _galat => _c.galat.value;
  List<ProdukModel> get _daftarProduk => _c.daftarProduk;
  String get _kategoriDipilih => _c.kategoriDipilih.value;
  List<String> get _kategoriList => _c.kategoriList;
  TextEditingController get _searchController => _c.searchController;
  int get _jumlahItemKeranjang => KeranjangController.to.totalItem;
  bool get _modeUtsAktif => _c.modeUtsAktif.value;
  bool get _sedangMuatLebih => _c.sedangMuatLebih.value;

  @override
  void initState() {
    super.initState();
    _c = Get.put(KatalogController());
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
        _scrollController.position.maxScrollExtent - 200) {
      _c.muatLebih();
    }
  }

  Future<void> _muatData() => _c.muatData();
  Future<void> _muatJumlahKeranjang() =>
      KeranjangController.to.muatKeranjang(senyap: true);
  Future<void> _muatConfig() => _c.muatConfig();

  Future<void> _tambahItemKeranjang(ProdukModel produk) async {
    try {
      await LayananApi.tambahKeranjang(produk.id, 1);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${produk.nama} ditambahkan ke keranjang'),
          backgroundColor: const Color(0xFF0284C7),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _muatJumlahKeranjang();
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
    }
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

  void _bukaRiwayat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RiwayatPesananScreen(),
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
    _muatData();
    _muatJumlahKeranjang();
  }

  Future<void> _bukaProfil() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilScreen(),
      ),
    );
  }

  Future<void> _bukaDetailProduk(ProdukModel produk) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProdukDetailScreen(produkId: produk.id),
      ),
    );
    if (!mounted) return;
    _muatData();
    _muatJumlahKeranjang();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fotoUrl = UrlBerkas.dari(AuthController.to.pengguna.value?.fotoUrl);
      final namaPengguna =
          AuthController.to.pengguna.value?.nama ?? 'Tamu (Guest)';

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              KatalogTopAppBar(
                namaPengguna: namaPengguna,
                fotoUrl: fotoUrl,
                modeUtsAktif: _modeUtsAktif,
                jumlahItemKeranjang: _jumlahItemKeranjang,
                onTapModeUts: _bukaKelolaProduk,
                onTapRiwayat: _bukaRiwayat,
                onTapKeranjang: _bukaKeranjang,
                onTapProfil: _bukaProfil,
              ),
              KatalogFilterHeader(
                searchController: _searchController,
                kategoriList: _kategoriList,
                kategoriDipilih: _kategoriDipilih,
                onSearchSubmitted: (_) => _muatData(),
                onSearchClear: () {
                  _searchController.clear();
                  _muatData();
                },
                onKategoriSelected: (kat) => _c.gantiKategori(kat),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _muatData,
                  color: const Color(0xFF0284C7),
                  child: WidgetKeadaan(
                    keadaan: _keadaan,
                    galat: _galat,
                    pesanKosong: 'Tidak ada produk yang cocok dengan pencarian.',
                    onCobaLagi: _muatData,
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        KatalogGridSliver(
                          daftarProduk: _daftarProduk,
                          sedangMuatLebih: _sedangMuatLebih,
                          onTapProduk: _bukaDetailProduk,
                          onTambahKeranjang: _tambahItemKeranjang,
                        ),
                        if (_sedangMuatLebih)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 16),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const NavBarBawah(currentIndex: 1),
      );
    });
  }
}
