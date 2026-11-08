import 'package:flutter/material.dart';

import '../models/produk_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../utils/url_berkas.dart';
import '../widgets/widget_keadaan.dart';
import 'keranjang_screen.dart';
import 'kelola_produk_screen.dart';
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
    // Pantau perubahan sesi (login/logout) agar AppBar & keranjang langsung update.
    SesiAuth.onBerubah = () {
      if (!mounted) return;
      setState(() {});
      _muatJumlahKeranjang();
      _muatConfig();
    };
  }

  @override
  void dispose() {
    SesiAuth.onBerubah = null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Apotek Sugeng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (_modeUtsAktif)
            IconButton(
              icon: const Icon(Icons.inventory_2_outlined),
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
            icon: const Icon(Icons.receipt_long),
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
                icon: const Icon(Icons.shopping_cart),
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
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$_jumlahItemKeranjang',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Tombol akun di paling kanan, tepat setelah ikon keranjang.
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Akun Saya',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilScreen(),
                  ),
                );
                if (!mounted) return;
                // Sesi bisa saja berubah (login/keluar) -> muat ulang keranjang
                // agar terhubung ke identitas yang benar (token baru/lama).
                setState(() {});
                _muatJumlahKeranjang();
              },
              icon: () {
                final fotoUrl = UrlBerkas.dari(SesiAuth.pengguna?.fotoUrl);
                return CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                  backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                      ? NetworkImage(fotoUrl)
                      : null,
                  child: fotoUrl == null || fotoUrl.isEmpty
                      ? const Icon(Icons.account_circle, size: 30)
                      : null,
                );
              }(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.teal.shade50,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari obat, vitamin, atau alkes...',
                    prefixIcon: const Icon(Icons.search, color: Colors.teal),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _muatData();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _muatData(),
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
                        selectedColor: Colors.teal,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.teal.shade800,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
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
              child: WidgetKeadaan(
                keadaan: _keadaan,
                galat: _galat,
                pesanKosong: 'Tidak ada produk yang cocok dengan pencarian.',
                onCobaLagi: _muatData,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
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
                              color: Colors.teal,
                            ),
                          ),
                        ),
                      );
                    }

                    final produk = _daftarProduk[index];
                    final isHabis = !produk.tersedia || produk.stok <= 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
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
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: isHabis
                                      ? Colors.grey.shade200
                                      : Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: () {
                                  final fotoUrl = UrlBerkas.dari(produk.fotoUrl);
                                  return fotoUrl != null && fotoUrl.isNotEmpty
                                    ? Image.network(
                                        fotoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Icon(
                                          produk.kategori == 'Obat'
                                              ? Icons.medication_liquid_outlined
                                              : Icons.medical_services_outlined,
                                          size: 38,
                                          color: isHabis
                                              ? Colors.grey
                                              : Colors.teal,
                                        ),
                                      )
                                    : Icon(
                                        produk.kategori == 'Obat'
                                            ? Icons.medication_liquid_outlined
                                            : Icons.medical_services_outlined,
                                        size: 38,
                                        color: isHabis
                                            ? Colors.grey
                                            : Colors.teal,
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isHabis
                                            ? Colors.grey
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          formatRupiah(produk.harga),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: isHabis
                                                ? Colors.grey
                                                : Colors.teal.shade700,
                                          ),
                                        ),
                                        Text(
                                          ' / ${produk.satuan}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
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
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Perlu Resep',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.red,
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
                                                ? Colors.grey.shade300
                                                : Colors.teal.shade50,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            isHabis
                                                ? 'Stok Habis'
                                                : 'Stok: ${produk.stok}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isHabis
                                                  ? Colors.black54
                                                  : Colors.teal.shade900,
                                            ),
                                          ),
                                        ),
                                        if (produk.golongan != null)
                                          Text(
                                            produk.golongan!,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black45,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              IconButton(
                                icon: Icon(
                                  Icons.add_shopping_cart,
                                  color: isHabis ? Colors.grey : Colors.teal,
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
                                              backgroundColor: Colors.teal,
                                              duration: const Duration(
                                                seconds: 1,
                                              ),
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
    );
  }
}
