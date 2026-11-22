import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/produk_model.dart';
import '../screens/keranjang_screen.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';

/// GetX Controller untuk Detail Produk.
class ProdukDetailController extends GetxController {
  final Rx<KeadaanMuat> keadaan = KeadaanMuat.memuat.obs;
  final Rx<InfoGalat?> galat = Rx<InfoGalat?>(null);
  final Rx<ProdukModel?> produk = Rx<ProdukModel?>(null);
  final RxInt jumlah = 1.obs;
  final RxBool sedangMenambah = false.obs;

  void inisialisasi(int id, {ProdukModel? awal}) {
    if (awal != null) {
      produk.value = awal;
      keadaan.value = KeadaanMuat.berhasil;
    }
    muatDetail(id);
  }

  Future<void> muatDetail(int id) async {
    if (produk.value == null) {
      keadaan.value = KeadaanMuat.memuat;
      galat.value = null;
    }

    try {
      final p = await LayananApi.getProdukDetail(id);
      produk.value = p;
      keadaan.value = KeadaanMuat.berhasil;
    } catch (e) {
      if (produk.value == null) {
        galat.value = e is InfoGalat
            ? e
            : InfoGalat(jenis: JenisGalat.lainnya, pesan: e.toString());
        keadaan.value = KeadaanMuat.galat;
      }
    }
  }

  void tambahJumlah() {
    final p = produk.value;
    if (p == null) return;
    if (jumlah.value < p.stok && jumlah.value < p.batasPerPembelian) {
      jumlah.value++;
    }
  }

  void kurangJumlah() {
    if (jumlah.value > 1) {
      jumlah.value--;
    }
  }

  Future<void> tambahKeKeranjang(BuildContext context) async {
    final p = produk.value;
    if (p == null) return;

    sedangMenambah.value = true;

    try {
      await LayananApi.tambahKeranjang(p.id, jumlah.value);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${jumlah.value} ${p.satuan} berhasil ditambahkan ke keranjang',
          ),
          backgroundColor: const Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const KeranjangScreen()),
      );
    } catch (e) {
      if (!context.mounted) return;
      final pesan = e is InfoGalat ? e.pesan : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesan),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      sedangMenambah.value = false;
    }
  }
}
