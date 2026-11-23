import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/keranjang_controller.dart';
import '../models/keranjang_model.dart';
import '../widgets/keranjang/catatan_apoteker_card.dart';
import '../widgets/keranjang/daftar_item_keranjang.dart';
import '../widgets/keranjang/keranjang_checkout_bar.dart';
import '../widgets/keranjang/rincian_pembayaran_card.dart';
import '../widgets/keranjang/unit_farmasi_header.dart';
import '../widgets/nav_bar_bawah.dart';
import '../widgets/widget_keadaan.dart';
import 'checkout_screen.dart';
import 'checkout_uts_screen.dart';
import 'profil_screen.dart';

/// Layar Keranjang Belanja Apotek Sugeng.
/// Menggunakan GetX reaktif — hanya widget yang terdampak (mis. counter item terkait
/// dan rincian total) yang diperbarui tanpa me-render ulang seluruh layar.
class KeranjangScreen extends StatefulWidget {
  const KeranjangScreen({super.key});

  /// Kompatibilitas mundur untuk pemanggil `KeranjangScreen.formatRupiah()`.
  static String formatRupiah(num angka) => formatRupiah(angka);

  @override
  State<KeranjangScreen> createState() => _KeranjangScreenState();
}

class _KeranjangScreenState extends State<KeranjangScreen> {
  @override
  void initState() {
    super.initState();
    KeranjangController.to.muatKeranjang();
  }

  Future<void> _ubahJumlah(
      BuildContext context, ItemKeranjangModel item, int delta) async {
    final pesanGalat = await KeranjangController.to.ubahJumlah(item, delta);
    if (pesanGalat != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesanGalat),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _hapusItem(BuildContext context, ItemKeranjangModel item) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Hapus Item?'),
        content: Text('Hapus ${item.produk?.nama ?? "produk"} dari keranjang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !context.mounted) return;

    final pesanGalat = await KeranjangController.to.hapusItem(item.id);
    if (pesanGalat != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesanGalat),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _hapusSemua(BuildContext context) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Kosongkan Keranjang?'),
        content: const Text('Semua item di keranjang belanja akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !context.mounted) return;

    final pesanGalat = await KeranjangController.to.hapusSemua();
    if (pesanGalat != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesanGalat),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<WidgetBuilder?> _pilihModeCheckout(
    BuildContext context,
    KeranjangDataModel data,
  ) {
    return showDialog<WidgetBuilder>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shopping_bag_outlined, color: Color(0xFF0284C7)),
            SizedBox(width: 8),
            Text('Pilih Mode Checkout', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Mode Simulasi (UTS):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              'Menggunakan kurir internal apotek & pembayaran COD / Transfer Manual.',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
            SizedBox(height: 10),
            Text(
              '2. Mode Lengkap (Oyi):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              'Menggunakan integrasi ongkir RajaOngkir JNE & Payment Gateway Xendit.',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(
              dialogContext,
              (context) => CheckoutUtsScreen(keranjangData: data),
            ),
            icon: const Icon(Icons.school, size: 16),
            label: const Text('Mode UTS'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(
              dialogContext,
              (context) => CheckoutScreen(keranjangData: data),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
            ),
            icon: const Icon(Icons.rocket_launch, size: 16),
            label: const Text('Mode Oyi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = KeranjangController.to;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Keranjang Belanja',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0F172A),
              ),
            ),
            Obx(() {
              final totalItem = ctrl.totalItem;
              if (totalItem <= 0) return const SizedBox.shrink();
              return Text(
                '$totalItem Barang terpilih',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.normal,
                ),
              );
            }),
          ],
        ),
        actions: [
          Obx(() {
            if (!ctrl.adaItem) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () => _hapusSemua(context),
                child: const Text(
                  'Hapus Semua',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        final keadaan = ctrl.keadaan.value;
        final galat = ctrl.galat.value;
        final adaItem = ctrl.adaItem;

        return WidgetKeadaan(
          keadaan: keadaan,
          galat: galat,
          pesanKosong:
              'Keranjang belanja Anda masih kosong.\nSilakan pilih produk obat atau alkes di beranda.',
          ikonKosong: Icons.remove_shopping_cart_outlined,
          warnaTombol: const Color(0xFF0284C7),
          onCobaLagi: () => ctrl.muatKeranjang(),
          child: !adaItem
              ? const SizedBox.shrink()
              : RefreshIndicator(
                  onRefresh: () => ctrl.muatKeranjang(),
                  color: const Color(0xFF0284C7),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      const UnitFarmasiHeader(),
                      const SizedBox(height: 10),
                      DaftarItemKeranjang(
                        onUbahJumlah: (item, delta) =>
                            _ubahJumlah(context, item, delta),
                        onHapus: (item) => _hapusItem(context, item),
                      ),
                      const SizedBox(height: 8),
                      const CatatanApotekerCard(),
                      const SizedBox(height: 14),
                      const RincianPembayaranCard(),
                    ],
                  ),
                ),
        );
      }),
      bottomNavigationBar: Obx(() {
        final adaItem = ctrl.adaItem;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (adaItem)
              KeranjangCheckoutBar(
                onCheckout: () async {
                  if (!AuthController.to.sedangLogin) {
                    final yakin = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        icon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF0284C7),
                          size: 44,
                        ),
                        title: const Text('Masuk Terlebih Dahulu'),
                        content: const Text(
                          'Anda perlu masuk ke akun untuk melanjutkan proses checkout pesanan.',
                          style: TextStyle(fontSize: 13),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                            ),
                            child: const Text('Masuk Sekarang'),
                          ),
                        ],
                      ),
                    );
                    if (yakin != true || !context.mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfilScreen(),
                      ),
                    );
                    if (!context.mounted || !AuthController.to.sedangLogin) {
                      return;
                    }
                    await ctrl.muatKeranjang();
                    if (!context.mounted) return;
                  }

                  final dataKeranjang = ctrl.keranjangData.value;
                  if (dataKeranjang == null || !context.mounted) return;
                  final tujuan =
                      await _pilihModeCheckout(context, dataKeranjang);
                  if (tujuan == null || !context.mounted) return;

                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: tujuan),
                  );
                  if (context.mounted) {
                    ctrl.muatKeranjang();
                  }
                },
              ),
            const NavBarBawah(currentIndex: 2),
          ],
        );
      }),
    );
  }
}
