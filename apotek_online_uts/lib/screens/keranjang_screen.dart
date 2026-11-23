import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/keranjang_controller.dart';
import '../models/keranjang_model.dart';
import '../utils/url_berkas.dart';
import '../widgets/nav_bar_bawah.dart';
import '../widgets/widget_keadaan.dart';
import 'checkout_screen.dart';
import 'checkout_uts_screen.dart';
import 'profil_screen.dart';

/// Layar Keranjang Belanja Apotek Sugeng.
/// Menggunakan GetX reaktif — hanya widget yang terdampak (mis. counter item terkait
/// dan rincian total) yang diperbarui tanpa me-render ulang seluruh layar atau banner catatan resep.
class KeranjangScreen extends StatefulWidget {
  const KeranjangScreen({super.key});

  static String formatRupiah(num angka) {
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
                      // 1. Unit Farmasi Header (Const — tidak pernah dirender ulang)
                      const _UnitFarmasiHeader(),
                      const SizedBox(height: 10),

                      // 2. Daftar Item Keranjang (Reaktif)
                      _DaftarItemKeranjang(
                        onUbahJumlah: (item, delta) =>
                            _ubahJumlah(context, item, delta),
                        onHapus: (item) => _hapusItem(context, item),
                      ),
                      const SizedBox(height: 8),

                      // 3. Catatan untuk Apoteker Card (Const — tidak pernah dirender ulang saat counter diubah)
                      const _CatatanApotekerCard(),
                      const SizedBox(height: 14),

                      // 4. Rincian Pembayaran Card (Hanya angka total yang reaktif)
                      const _RincianPembayaranCard(),
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
              _CheckoutBar(
                onCheckout: () async {
                  // 1. Wajib login sebelum checkout
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

                  // 2. Dialog Mode Checkout
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

/// Header Unit Farmasi statis (const — zero re-render).
class _UnitFarmasiHeader extends StatelessWidget {
  const _UnitFarmasiHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.storefront_outlined,
          size: 18,
          color: Color(0xFF0284C7),
        ),
        const SizedBox(width: 6),
        const Text(
          'Apotek Sugeng – Unit Farmasi',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Siap Dikirim',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}

/// List Item Keranjang Reaktif.
class _DaftarItemKeranjang extends StatelessWidget {
  final void Function(ItemKeranjangModel item, int delta) onUbahJumlah;
  final void Function(ItemKeranjangModel item) onHapus;

  const _DaftarItemKeranjang({
    required this.onUbahJumlah,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = KeranjangController.to.items;
      return Column(
        children: items.map((item) {
          return _KartuItemKeranjang(
            key: ValueKey(item.id),
            item: item,
            onUbahJumlah: onUbahJumlah,
            onHapus: onHapus,
          );
        }).toList(),
      );
    });
  }
}

/// Kartu Item Keranjang individual.
class _KartuItemKeranjang extends StatelessWidget {
  final ItemKeranjangModel item;
  final void Function(ItemKeranjangModel item, int delta) onUbahJumlah;
  final void Function(ItemKeranjangModel item) onHapus;

  const _KartuItemKeranjang({
    super.key,
    required this.item,
    required this.onUbahJumlah,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final produk = item.produk;
    final fotoUrl = UrlBerkas.dari(produk?.fotoUrl);
    final hargaItem = produk?.harga ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Produk
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 64,
                  height: 64,
                  color: const Color(0xFFF1F5F9),
                  child: fotoUrl != null && fotoUrl.isNotEmpty
                      ? Image.network(
                          fotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
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

              // Detail & Harga
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produk?.nama ?? 'Produk #${item.produkId}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        produk?.kategori ?? 'Obat',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Harga Satuan',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      KeranjangScreen.formatRupiah(hargaItem),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Stepper Counter Jumlah & Tombol Hapus
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => onUbahJumlah(item, -1),
                          child: const SizedBox(
                            width: 28,
                            height: 32,
                            child: Center(
                              child: Icon(
                                Icons.remove,
                                size: 15,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 26,
                          child: Text(
                            '${item.jumlah}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => onUbahJumlah(item, 1),
                          child: Container(
                            width: 26,
                            height: 26,
                            margin: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onHapus(item),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Indikator Stok & Label Resep
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 13,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(width: 4),
              Text(
                'Stok tersedia: ${produk?.stok ?? "-"} ${produk?.satuan ?? "pcs"}',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (produk?.perluResep == true) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Wajib Resep',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Catatan Resep Dokter untuk Apoteker (Statis, const constructor — zero re-renders).
class _CatatanApotekerCard extends StatelessWidget {
  const _CatatanApotekerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.edit_note_rounded,
            color: Color(0xFF0284C7),
            size: 22,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan Resep untuk Apoteker',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Nomor resep dokter dapat diisikan pada tahap checkout.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rincian Pembayaran Card (Hanya angka subtotal yang reaktif).
class _RincianPembayaranCard extends StatelessWidget {
  const _RincianPembayaranCard();

  @override
  Widget build(BuildContext context) {
    final ctrl = KeranjangController.to;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Pembayaran',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final totalItem = ctrl.totalItem;
            final subtotal = ctrl.subtotal;

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Harga ($totalItem barang)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      KeranjangScreen.formatRupiah(subtotal),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Biaya Penanganan Medis',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      'Gratis',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Perkiraan Ongkir',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      'Dihitung saat Checkout',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: Color(0xFFE2E8F0), height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Estimasi Total',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      KeranjangScreen.formatRupiah(subtotal),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// Bar Checkout di bagian bawah layar.
class _CheckoutBar extends StatelessWidget {
  final VoidCallback onCheckout;

  const _CheckoutBar({required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final ctrl = KeranjangController.to;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subtotal Tagihan',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Obx(
                    () => Text(
                      KeranjangScreen.formatRupiah(ctrl.subtotal),
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: onCheckout,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0369A1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Checkout Pesanan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
