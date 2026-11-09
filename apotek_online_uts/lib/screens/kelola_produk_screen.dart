import 'package:flutter/material.dart';

import '../models/produk_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../utils/url_berkas.dart';
import '../widgets/widget_keadaan.dart';
import 'form_produk_screen.dart';

class KelolaProdukScreen extends StatefulWidget {
  const KelolaProdukScreen({super.key});

  @override
  State<KelolaProdukScreen> createState() => _KelolaProdukScreenState();
}

class _KelolaProdukScreenState extends State<KelolaProdukScreen> {
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  InfoGalat? _galat;
  List<ProdukModel> _daftarProduk = [];

  String _kategoriDipilih = 'Semua';
  final List<String> _kategoriList = ['Semua', 'Obat', 'Alat Kesehatan'];
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  int _halamanSekarang = 1;
  bool _hasMore = true;
  bool _sedangMuatLebih = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _muatProduk();
  }

  @override
  void dispose() {
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

  /// Memuat daftar produk langsung dari server dengan parameter ?kategori=, ?cari=, ?page=1
  Future<void> _muatProduk() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _galat = null;
      _halamanSekarang = 1;
      _hasMore = true;
      _sedangMuatLebih = false;
    });

    try {
      final list = await LayananApi.getProduk(
        kategori: _kategoriDipilih,
        cari: _searchController.text.trim(),
        page: 1,
        perPage: 8,
      );
      if (!mounted) return;

      setState(() {
        _daftarProduk = list;
        _hasMore = list.length >= 8;
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

  /// Memuat halaman berikutnya saat scroll mendekati ujung bawah (Infinite Scroll)
  Future<void> _muatLebih() async {
    if (_sedangMuatLebih || !_hasMore || _keadaan == KeadaanMuat.memuat) return;

    setState(() => _sedangMuatLebih = true);

    try {
      final nextPage = _halamanSekarang + 1;
      final itemsBaru = await LayananApi.getProduk(
        kategori: _kategoriDipilih,
        cari: _searchController.text.trim(),
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
    return Scaffold(
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
          // 1. Kotak Pencarian (Mengirim parameter ?cari= ke server)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Cari produk obat atau alkes...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0284C7)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _muatProduk();
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        onPressed: _muatProduk,
                      ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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
                  borderSide: const BorderSide(color: Color(0xFF0284C7)),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
              onSubmitted: (_) => _muatProduk(),
            ),
          ),

          // 2. Penyaring Kategori (Mengirim parameter ?kategori= ke server)
          Container(
            height: 48,
            color: Colors.white,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _kategoriDipilih = kat);
                      _muatProduk();
                    }
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),

          // 3. Daftar Produk (Dibangun dengan ListView.builder)
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
                    final bool isStokKosong = p.stok <= 0;
                    final bool isTidakTersedia = !p.tersedia;
                    final bool isDisabled = isStokKosong || isTidakTersedia;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isDisabled
                              ? Colors.red.shade200
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Foto / Icon Produk
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isDisabled
                                        ? Colors.grey.shade200
                                        : const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: () {
                                    final fotoUrl = UrlBerkas.dari(p.fotoUrl);
                                    return fotoUrl != null && fotoUrl.isNotEmpty
                                        ? Image.network(
                                            fotoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => Icon(
                                              p.kategori == 'Obat'
                                                  ? Icons.medication_liquid_outlined
                                                  : Icons.medical_services_outlined,
                                              color: isDisabled
                                                  ? Colors.grey
                                                  : const Color(0xFF0284C7),
                                              size: 28,
                                            ),
                                          )
                                        : Icon(
                                            p.kategori == 'Obat'
                                                ? Icons.medication_liquid_outlined
                                                : Icons.medical_services_outlined,
                                            color: isDisabled
                                                ? Colors.grey
                                                : const Color(0xFF0284C7),
                                            size: 28,
                                          );
                                  }(),
                                ),
                                const SizedBox(width: 12),

                                // Detail Nama & Harga
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.nama,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isDisabled
                                              ? Colors.grey.shade700
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${formatRupiah(p.harga)} / ${p.satuan}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isDisabled
                                              ? Colors.grey
                                              : const Color(0xFF0284C7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Tombol Aksi Ubah & Hapus
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Ubah Produk',
                                      onPressed: () => _bukaFormProduk(p),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Hapus Produk',
                                      onPressed: () =>
                                          _konfirmasiHapusProduk(p),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Penanda Status Jelas (Stok Nol / Tidak Tersedia / Resep)
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (isStokKosong)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.red.shade400,
                                      ),
                                    ),
                                    child: const Text(
                                      '⛔ Stok Habis (0)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.green.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      'Stok: ${p.stok}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade900,
                                      ),
                                    ),
                                  ),

                                if (isTidakTersedia)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.orange.shade400,
                                      ),
                                    ),
                                    child: const Text(
                                      '⚠️ Tidak Tersedia',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  ),

                                if (p.perluResep)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.blue.shade300,
                                      ),
                                    ),
                                    child: const Text(
                                      'Wajib Resep Dokter',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Max Beli: ${p.batasPerPembelian}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
