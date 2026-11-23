import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/kelola_produk_controller.dart';
import '../models/produk_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../widgets/kelola_produk/kelola_produk_card.dart';
import '../widgets/kelola_produk/kelola_produk_kategori_tabs.dart';
import '../widgets/kelola_produk/kelola_produk_search_bar.dart';
import '../widgets/widget_keadaan.dart';
import 'form_produk_screen.dart';

class KelolaProdukScreen extends StatefulWidget {
  const KelolaProdukScreen({super.key});

  @override
  State<KelolaProdukScreen> createState() => _KelolaProdukScreenState();
}

class _KelolaProdukScreenState extends State<KelolaProdukScreen> {
  late final KelolaProdukController _c;
  final ScrollController _scrollController = ScrollController();

  KeadaanMuat get _keadaan => _c.keadaan.value;
  InfoGalat? get _galat => _c.galat.value;
  List<ProdukModel> get _daftarProduk => _c.daftarProduk;
  String get _kategoriDipilih => _c.kategoriDipilih.value;
  List<String> get _kategoriList => _c.kategoriList;
  TextEditingController get _searchController => _c.searchController;
  bool get _hasMore => _c.hasMore.value;

  @override
  void initState() {
    super.initState();
    _c = Get.put(KelolaProdukController());
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

  Future<void> _muatProduk() => _c.muatProduk();

  /// Menuju formulir produk (Tambah atau Ubah); kembali dengan hasil berhasil atau batal
  Future<void> _bukaFormProduk([ProdukModel? produk]) async {
    final hasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FormProdukScreen(produk: produk),
      ),
    );

    if (!mounted) return;

    // Jika formulir selesai dan berhasil disimpan, refresh daftar produk
    if (hasil == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            produk != null
                ? 'Produk "${produk.nama}" berhasil diperbarui!'
                : 'Produk baru berhasil ditambahkan!',
          ),
          backgroundColor: const Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _muatProduk();
    }
  }

  /// Konfirmasi hapus produk lewat dialog sebelum permintaan DELETE dikirim ke server
  Future<void> _konfirmasiHapusProduk(ProdukModel produk) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Hapus Produk', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${produk.nama}" dari katalog obat apotek?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (konfirmasi == true) {
      try {
        await LayananApi.hapusProduk(produk.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produk "${produk.nama}" berhasil dihapus!'),
            backgroundColor: const Color(0xFF0284C7),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _muatProduk();
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
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Kelola Produk (Mode UTS)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF005B82),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaFormProduk(),
        backgroundColor: const Color(0xFF005B82),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
      body: Column(
        children: [
          // 1. Kotak Pencarian
          KelolaProdukSearchBar(
            controller: _searchController,
            onSubmitted: _muatProduk,
          ),

          // 2. Penyaring Kategori
          KelolaProdukKategoriTabs(
            kategoriList: _kategoriList,
            kategoriDipilih: _kategoriDipilih,
            onSelected: (kat) => _c.gantiKategori(kat),
          ),
          const Divider(height: 1),

          // 3. Daftar Produk
          Expanded(
            child: RefreshIndicator(
              onRefresh: _muatProduk,
              child: WidgetKeadaan(
                keadaan: _keadaan,
                galat: _galat,
                pesanKosong:
                    'Tidak ada produk ditemukan untuk kriteria pencarian ini.',
                onCobaLagi: _muatProduk,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
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

                    final p = _daftarProduk[index];
                    return KelolaProdukCard(
                      produk: p,
                      onEdit: () => _bukaFormProduk(p),
                      onDelete: () => _konfirmasiHapusProduk(p),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
