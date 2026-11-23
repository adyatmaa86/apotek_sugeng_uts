import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/keranjang_controller.dart';
import '../controllers/produk_detail_controller.dart';
import '../widgets/produk_detail/produk_bottom_bar.dart';
import '../widgets/produk_detail/produk_deskripsi_card.dart';
import '../widgets/produk_detail/produk_gambar_card.dart';
import '../widgets/produk_detail/produk_info_card.dart';
import '../widgets/produk_detail/produk_spesifikasi_card.dart';
import '../widgets/widget_keadaan.dart';
import 'keranjang_screen.dart';

class ProdukDetailScreen extends StatefulWidget {
  final int produkId;

  const ProdukDetailScreen({super.key, required this.produkId});

  @override
  State<ProdukDetailScreen> createState() => _ProdukDetailScreenState();
}

class _ProdukDetailScreenState extends State<ProdukDetailScreen> {
  late final ProdukDetailController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.put(ProdukDetailController(), tag: '${widget.produkId}');
    _c.inisialisasi(widget.produkId);
  }

  @override
  Widget build(BuildContext context) {
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
                  );
                },
              ),
              Obx(() {
                final totalItem = KeranjangController.to.totalItem;
                if (totalItem <= 0) return const SizedBox.shrink();
                return Positioned(
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
                      '$totalItem',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
      body: Obx(() {
        final p = _c.produk.value;
        return WidgetKeadaan(
          keadaan: _c.keadaan.value,
          galat: _c.galat.value,
          onCobaLagi: () => _c.muatDetail(widget.produkId),
          child: p == null
              ? const SizedBox()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProdukGambarCard(produk: p),
                      const SizedBox(height: 16),
                      ProdukInfoCard(produk: p),
                      const SizedBox(height: 14),
                      ProdukSpesifikasiCard(produk: p),
                      const SizedBox(height: 14),
                      ProdukDeskripsiCard(produk: p),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        );
      }),
      bottomNavigationBar: Obx(() {
        return ProdukBottomBar(
          produk: _c.produk.value,
          jumlah: _c.jumlah.value,
          sedangMenambah: _c.sedangMenambah.value,
          onKurang: _c.kurangJumlah,
          onTambah: _c.tambahJumlah,
          onTambahKeKeranjang: () => _c.tambahKeKeranjang(context),
        );
      }),
    );
  }
}
