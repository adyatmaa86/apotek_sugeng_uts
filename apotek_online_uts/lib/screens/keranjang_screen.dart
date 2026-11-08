import 'package:flutter/material.dart';

import '../models/keranjang_model.dart';
import '../screens/profil_screen.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../utils/url_berkas.dart';
import '../widgets/widget_keadaan.dart';
import 'checkout_uts_screen.dart';
import 'checkout_screen.dart';

class KeranjangScreen extends StatefulWidget {
  const KeranjangScreen({super.key});

  @override
  State<KeranjangScreen> createState() => _KeranjangScreenState();
}

class _KeranjangScreenState extends State<KeranjangScreen> {
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  InfoGalat? _galat;
  KeranjangDataModel? _keranjangData;

  @override
  void initState() {
    super.initState();
    _muatKeranjang();
    // Saat sesi berubah (login/logout), reload keranjang otomatis.
    SesiAuth.onBerubah = () {
      if (!mounted) return;
      _muatKeranjang();
    };
  }

  @override
  void dispose() {
    SesiAuth.onBerubah = null;
    super.dispose();
  }

  Future<void> _muatKeranjang() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _galat = null;
    });

    try {
      final data = await LayananApi.getKeranjang();
      if (!mounted) return;

      setState(() {
        _keranjangData = data;
        _keadaan = data.items.isEmpty
            ? KeadaanMuat.kosong
            : KeadaanMuat.berhasil;
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

  Future<void> _ubahJumlah(ItemKeranjangModel item, int delta) async {
    final jumlahBaru = item.jumlah + delta;
    if (jumlahBaru <= 0) return;

    try {
      await LayananApi.ubahJumlahKeranjang(item.id, jumlahBaru);
      if (!mounted) return;
      _muatKeranjang();
    } catch (e) {
      if (!mounted) return;
      final pesan = e is InfoGalat ? e.pesan : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesan), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _hapusItem(ItemKeranjangModel item) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Item'),
        content: Text('Hapus ${item.produk?.nama ?? "produk"} dari keranjang?'),
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
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (konfirmasi == true) {
      try {
        await LayananApi.hapusItemKeranjang(item.id);
        if (!mounted) return;
        _muatKeranjang();
      } catch (e) {
        if (!mounted) return;
        final pesan = e is InfoGalat ? e.pesan : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pesan), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Dialog pilihan mode checkout sebelum pindah halaman.
  /// Mode Simulasi (UTS): kurir internal + pembayaran COD/transfer manual.
  /// Mode Oyi: checkout lengkap dengan RajaOngkir JNE dan Xendit.
  Future<WidgetBuilder?> _pilihModeCheckout() {
    return showDialog<WidgetBuilder>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pilih Mode Checkout'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mode Simulasi (UTS) memakai kurir internal toko dan pembayaran '
              'COD / transfer manual.\n\n'
              'Mode Oyi memakai RajaOngkir JNE dan Xendit.',
              style: TextStyle(fontSize: 13),
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
              (context) => CheckoutUtsScreen(keranjangData: _keranjangData!),
            ),
            icon: const Icon(Icons.school, size: 18),
            label: const Text('Mode Simulasi (UTS)'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(
              dialogContext,
              (context) => CheckoutScreen(keranjangData: _keranjangData!),
            ),
            icon: const Icon(Icons.rocket_launch, size: 18),
            label: const Text('Mode Oyi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Belanja'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: WidgetKeadaan(
        keadaan: _keadaan,
        galat: _galat,
        pesanKosong: 'Keranjang belanja Anda masih kosong.\nSilakan pilih obat atau alkes di katalog.',
        ikonKosong: Icons.remove_shopping_cart_outlined,
        onCobaLagi: _muatKeranjang,
        child: _keranjangData == null
            ? const SizedBox()
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _keranjangData!.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _keranjangData!.items[index];
                  final produk = item.produk;

                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: () {
                                final fotoUrl = UrlBerkas.dari(produk?.fotoUrl);
                                return fotoUrl != null && fotoUrl.isNotEmpty
                                ? Image.network(
                                    fotoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Icon(
                                      produk?.kategori == 'Obat'
                                          ? Icons.medication_liquid_outlined
                                          : Icons.medical_services_outlined,
                                      color: Colors.teal,
                                    ),
                                  )
                                : Icon(
                                    produk?.kategori == 'Obat'
                                        ? Icons.medication_liquid_outlined
                                        : Icons.medical_services_outlined,
                                    color: Colors.teal,
                                  );
                              }(),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  produk?.nama ?? 'Item #${item.produkId}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatRupiah(produk?.harga ?? 0),
                                  style: TextStyle(
                                    color: Colors.teal.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (produk?.perluResep == true)
                                  const Text(
                                    '*Perlu Resep Dokter',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.teal,
                                ),
                                onPressed: () => _ubahJumlah(item, -1),
                              ),
                              Text(
                                '${item.jumlah}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.teal,
                                ),
                                onPressed: () => _ubahJumlah(item, 1),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => _hapusItem(item),
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
      bottomNavigationBar:
          _keranjangData == null || _keranjangData!.items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Subtotal Server:',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                        Text(
                          formatRupiah(_keranjangData!.subtotal),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      // Wajib login sebelum checkout
                      if (!SesiAuth.sedangLogin) {
                        final yakin = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            icon: const Icon(
                              Icons.lock_outline,
                              color: Colors.teal,
                              size: 48,
                            ),
                            title: const Text('Belum Masuk'),
                            content: const Text(
                              'Anda harus masuk ke akun terlebih dahulu untuk melakukan checkout.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                ),
                                child: const Text('Masuk Sekarang'),
                              ),
                            ],
                          ),
                        );
                        if (yakin != true) return;
                        if (!mounted) return;
                        final nav = Navigator.of(this.context);
                        await nav.push(
                          MaterialPageRoute(
                            builder: (context) => const ProfilScreen(),
                          ),
                        );
                        // Setelah kembali dari login, cek lagi apakah sudah login
                        if (!mounted) return;
                        if (!SesiAuth.sedangLogin) return;
                        // Reload keranjang dengan token baru
                        await _muatKeranjang();
                        if (!mounted) return;
                      }

                      final halamanTujuan = await _pilihModeCheckout();
                      if (halamanTujuan == null) return;
                      if (!mounted) return;

                      await Navigator.push(
                        this.context,
                        MaterialPageRoute(builder: halamanTujuan),
                      );
                      if (!mounted) return;
                      _muatKeranjang();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Checkout',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
