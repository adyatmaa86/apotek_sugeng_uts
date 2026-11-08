import 'package:flutter/material.dart';

import '../models/produk_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../utils/url_berkas.dart';
import '../widgets/widget_keadaan.dart';
import 'beranda_screen.dart';
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
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  InfoGalat? _galat;
  List<ProdukModel> _daftarProduk = [];

  String _kategoriDipilih = 'Semua';
  final List<String> _kategoriList = ['Semua', 'Obat', 'Alat Kesehatan'];
  final TextEditingController _searchController = TextEditingController();

  int _jumlahItemKeranjang = 0;
  bool _modeUtsAktif = false;
  int _navIndex = 1; // Index 1: Kategori/Katalog

  final ScrollController _scrollController = ScrollController();
  int _halamanSekarang = 1;
  bool _hasMore = true;
  bool _sedangMuatLebih = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _muatData();
    _muatJumlahKeranjang();
    _muatConfig();
    SesiAuth.tambahListener(_onSesiBerubah);
  }

  void _onSesiBerubah() {
    if (!mounted) return;
    setState(() {});
    _muatJumlahKeranjang();
    _muatConfig();
  }

  @override
  void dispose() {
    SesiAuth.hapusListener(_onSesiBerubah);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _muatLebih();
    }
  }

  Future<void> _muatData() async {
    _muatConfig();
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _galat = null;
      _halamanSekarang = 1;
      _hasMore = true;
      _sedangMuatLebih = false;
    });

    try {
      final produk = await LayananApi.getProduk(
        kategori: _kategoriDipilih,
        cari: _searchController.text,
        page: 1,
        perPage: 8,
      );
      if (!mounted) return;

      setState(() {
        _daftarProduk = produk;
        _hasMore = produk.length >= 8;
        _keadaan = produk.isEmpty ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
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

  Future<void> _muatLebih() async {
    if (_sedangMuatLebih || !_hasMore || _keadaan == KeadaanMuat.memuat) return;

    setState(() => _sedangMuatLebih = true);

    try {
      final nextPage = _halamanSekarang + 1;
      final itemsBaru = await LayananApi.getProduk(
        kategori: _kategoriDipilih,
        cari: _searchController.text,
        page: nextPage,
        perPage: 8,
      );
      if (!mounted) return;

      setState(() {
        _sedangMuatLebih = false;
        if (itemsBaru.isEmpty) {
          _hasMore = false;
        } else {
          _halamanSekarang = nextPage;
          _daftarProduk.addAll(itemsBaru);
          if (itemsBaru.length < 8) {
            _hasMore = false;
          }
        }
      });
    } catch (_) {
      if (mounted) setState(() => _sedangMuatLebih = false);
    }
  }

  Future<void> _muatJumlahKeranjang() async {
    try {
      final keranjang = await LayananApi.getKeranjang();
      if (mounted) {
        setState(() {
          _jumlahItemKeranjang = keranjang.totalItem;
        });
      }
    } catch (_) {}
  }

  Future<void> _muatConfig() async {
    try {
      final config = await LayananApi.getAppConfig();
      if (mounted) {
        setState(() {
          _modeUtsAktif = config['mode_uts'] == true;
        });
      }
    } catch (_) {}
  }

  void _onBottomNavTapped(int index) async {
    if (index == 1) {
      setState(() => _navIndex = 1);
      return;
    }

    if (index == 0) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BerandaScreen()),
      );
    } else if (index == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const KeranjangScreen()),
      );
    } else if (index == 3) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RiwayatPesananScreen()),
      );
    } else if (index == 4) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilScreen()),
      );
    }

    if (mounted) {
      setState(() => _navIndex = 1);
      _muatJumlahKeranjang();
      _muatData();
    }
  }

  Widget _buildTopAppBar() {
    final fotoUrl = UrlBerkas.dari(SesiAuth.pengguna?.fotoUrl);
    final namaPengguna = SesiAuth.pengguna?.nama ?? 'Pelanggan';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                'Katalog Produk',
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
              if (_modeUtsAktif)
                IconButton(
                  icon: const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF0284C7),
                    size: 22,
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
              IconButton(
                icon: const Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFF334155),
                  size: 22,
                ),
                tooltip: 'Riwayat Pesanan',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RiwayatPesananScreen(),
                    ),
                  );
                },
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFF334155),
                      size: 22,
                    ),
                    tooltip: 'Keranjang Belanja',
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const KeranjangScreen(),
                        ),
                      );
                      _muatData();
                      _muatJumlahKeranjang();
                    },
                  ),
                  if (_jumlahItemKeranjang > 0)
                    Positioned(
                      top: 4,
                      right: 4,
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
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilScreen(),
                    ),
                  );
                  if (!mounted) return;
                  setState(() {});
                  _muatJumlahKeranjang();
                },
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFF0284C7),
                  backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                      ? NetworkImage(fotoUrl)
                      : null,
                  child: fotoUrl == null || fotoUrl.isEmpty
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(),

            // Bagian Pencarian & Kategori
            Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari obat, vitamin, atau alkes...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Color(0xFF64748B),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _muatData();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _muatData(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _kategoriList.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final kat = _kategoriList[index];
                        final isSelected = kat == _kategoriDipilih;
                        return ChoiceChip(
                          label: Text(kat),
                          selected: isSelected,
                          selectedColor: const Color(0xFF005B82),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF005B82)
                                : const Color(0xFFE2E8F0),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF475569),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _kategoriDipilih = kat;
                              });
                              _muatData();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
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
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _daftarProduk.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _daftarProduk.length) {
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

                      final produk = _daftarProduk[index];
                      final isHabis = !produk.tersedia || produk.stok <= 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProdukDetailScreen(produkId: produk.id),
                              ),
                            );
                            if (!mounted) return;
                            _muatData();
                            _muatJumlahKeranjang();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: isHabis
                                        ? const Color(0xFFF1F5F9)
                                        : const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: () {
                                    final fotoUrl =
                                        UrlBerkas.dari(produk.fotoUrl);
                                    return fotoUrl != null &&
                                            fotoUrl.isNotEmpty
                                        ? Image.network(
                                            fotoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => Icon(
                                              produk.kategori == 'Obat'
                                                  ? Icons.medication_liquid_outlined
                                                  : Icons.medical_services_outlined,
                                              size: 38,
                                              color: isHabis
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF0284C7),
                                            ),
                                          )
                                        : Icon(
                                            produk.kategori == 'Obat'
                                                ? Icons.medication_liquid_outlined
                                                : Icons.medical_services_outlined,
                                            size: 38,
                                            color: isHabis
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF0284C7),
                                          );
                                  }(),
                                ),
                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        produk.nama,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isHabis
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            formatRupiah(produk.harga),
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.bold,
                                              color: isHabis
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF0284C7),
                                            ),
                                          ),
                                          Text(
                                            ' / ${produk.satuan}',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          if (produk.perluResep)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEE2E2),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Perlu Resep',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  color: Color(0xFFDC2626),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isHabis
                                                  ? const Color(0xFFF1F5F9)
                                                  : const Color(0xFFE0F2FE),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isHabis
                                                  ? 'Stok Habis'
                                                  : 'Stok: ${produk.stok}',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: isHabis
                                                    ? const Color(0xFF64748B)
                                                    : const Color(0xFF0284C7),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (produk.golongan != null)
                                            Text(
                                              produk.golongan!,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF94A3B8),
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: isHabis
                                          ? const Color(0xFFF1F5F9)
                                          : const Color(0xFF0284C7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.add_shopping_cart,
                                      size: 18,
                                      color: isHabis
                                          ? const Color(0xFF94A3B8)
                                          : Colors.white,
                                    ),
                                  ),
                                  onPressed: isHabis
                                      ? null
                                      : () async {
                                          try {
                                            await LayananApi.tambahKeranjang(
                                              produk.id,
                                              1,
                                            );
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${produk.nama} ditambahkan ke keranjang',
                                                ),
                                                backgroundColor:
                                                    const Color(0xFF0284C7),
                                                duration: const Duration(
                                                  seconds: 1,
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                            _muatJumlahKeranjang();
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            final pesan = e is InfoGalat
                                                ? e.pesan
                                                : e.toString();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(pesan),
                                                backgroundColor: Colors.red,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
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
