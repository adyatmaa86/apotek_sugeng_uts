import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/katalog_controller.dart';
import '../controllers/keranjang_controller.dart';
import '../models/produk_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../utils/url_berkas.dart';
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

  Widget _buildTopAppBar() {
    final fotoUrl = UrlBerkas.dari(AuthController.to.pengguna.value?.fotoUrl);
    final namaPengguna = AuthController.to.pengguna.value?.nama ?? 'Tamu (Guest)';

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
              if (_modeUtsAktif && AuthController.to.adminAktif)
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
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF0284C7),
                  backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
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
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                      ),
                      onChanged: (_) {},
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
                              _c.gantiKategori(kat);
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
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.68,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final produk = _daftarProduk[index];
                              final isHabis =
                                  !produk.tersedia || produk.stok <= 0;
                              final fotoUrl = UrlBerkas.dari(produk.fotoUrl);

                              return Container(
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
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProdukDetailScreen(
                                        produkId: produk.id,
                                      ),
                                    ),
                                  );
                                  if (!mounted) return;
                                  _muatData();
                                  _muatJumlahKeranjang();
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Gambar Produk + Badge Resep / Kategori
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(15),
                                          ),
                                          child: Container(
                                            height: 120,
                                            width: double.infinity,
                                            color: isHabis
                                                ? const Color(0xFFF1F5F9)
                                                : const Color(0xFFE0F2FE),
                                            child: fotoUrl != null &&
                                                    fotoUrl.isNotEmpty
                                                ? Image.network(
                                                    fotoUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, _, _) => Icon(
                                                      produk.kategori == 'Obat'
                                                          ? Icons
                                                              .medication_liquid_outlined
                                                          : Icons
                                                              .medical_services_outlined,
                                                      size: 40,
                                                      color: isHabis
                                                          ? const Color(
                                                              0xFF94A3B8,
                                                            )
                                                          : const Color(
                                                              0xFF0284C7,
                                                            ),
                                                    ),
                                                  )
                                                : Icon(
                                                    produk.kategori == 'Obat'
                                                        ? Icons
                                                            .medication_liquid_outlined
                                                        : Icons
                                                            .medical_services_outlined,
                                                    size: 40,
                                                    color: isHabis
                                                        ? const Color(
                                                            0xFF94A3B8,
                                                          )
                                                        : const Color(
                                                            0xFF0284C7,
                                                          ),
                                                  ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.92),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
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

                                    // Detail Informasi Produk
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
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                              height: 1.2,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    Text(
                                                      formatRupiah(produk.harga),
                                                      style: const TextStyle(
                                                        fontSize: 12.5,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xFF0284C7),
                                                      ),
                                                    ),
                                                    Text(
                                                      '/${produk.satuan}',
                                                      style: const TextStyle(
                                                        fontSize: 9.5,
                                                        color:
                                                            Color(0xFF94A3B8),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              InkWell(
                                                onTap: isHabis
                                                    ? null
                                                    : () async {
                                                        try {
                                                          await LayananApi
                                                              .tambahKeranjang(
                                                            produk.id,
                                                            1,
                                                          );
                                                          if (!context.mounted) {
                                                            return;
                                                          }
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                '${produk.nama} ditambahkan ke keranjang',
                                                              ),
                                                              backgroundColor:
                                                                  const Color(
                                                                0xFF0284C7,
                                                              ),
                                                              duration:
                                                                  const Duration(
                                                                seconds: 1,
                                                              ),
                                                              behavior:
                                                                  SnackBarBehavior
                                                                      .floating,
                                                              ),
                                                          );
                                                          _muatJumlahKeranjang();
                                                        } catch (e) {
                                                          if (!context.mounted) {
                                                            return;
                                                          }
                                                          final pesan = e
                                                                  is InfoGalat
                                                              ? e.pesan
                                                              : e.toString();
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                pesan,
                                                              ),
                                                              backgroundColor:
                                                                  Colors.red,
                                                                behavior:
                                                                  SnackBarBehavior
                                                                      .floating,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: isHabis
                                                        ? const Color(
                                                            0xFFF1F5F9,
                                                          )
                                                        : const Color(
                                                            0xFF0284C7,
                                                          ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      8,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.add,
                                                      color: isHabis
                                                          ? const Color(
                                                              0xFF94A3B8,
                                                            )
                                                          : Colors.white,
                                                      size: 18,
                                                    ),
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
                          childCount: _daftarProduk.length,
                        ),
                      ),
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
    ));
  }
}
