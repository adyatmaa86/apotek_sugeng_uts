import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/produk_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';

/// GetX Controller untuk pengelolaan produk (Mode UTS).
class KelolaProdukController extends GetxController {
  final Rx<KeadaanMuat> keadaan = KeadaanMuat.memuat.obs;
  final Rx<InfoGalat?> galat = Rx<InfoGalat?>(null);
  final RxList<ProdukModel> daftarProduk = <ProdukModel>[].obs;

  final RxString kategoriDipilih = 'Semua'.obs;
  final List<String> kategoriList = const ['Semua', 'Obat', 'Alat Kesehatan'];
  final TextEditingController searchController = TextEditingController();

  final RxInt halamanSekarang = 1.obs;
  final RxBool hasMore = true.obs;
  final RxBool sedangMuatLebih = false.obs;

  @override
  void onInit() {
    super.onInit();
    muatProduk();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> muatProduk() async {
    keadaan.value = KeadaanMuat.memuat;
    galat.value = null;
    halamanSekarang.value = 1;
    hasMore.value = true;
    sedangMuatLebih.value = false;

    try {
      final list = await LayananApi.getProduk(
        kategori: kategoriDipilih.value,
        cari: searchController.text.trim(),
        page: 1,
        perPage: 8,
      );

      daftarProduk.assignAll(list);
      hasMore.value = list.length >= 8;
      keadaan.value = list.isEmpty ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
    } catch (e) {
      galat.value = e is InfoGalat
          ? e
          : InfoGalat(jenis: JenisGalat.lainnya, pesan: e.toString());
      keadaan.value = KeadaanMuat.galat;
    }
  }

  Future<void> muatLebih() async {
    if (sedangMuatLebih.value || !hasMore.value || keadaan.value == KeadaanMuat.memuat) {
      return;
    }

    sedangMuatLebih.value = true;

    try {
      final nextPage = halamanSekarang.value + 1;
      final itemsBaru = await LayananApi.getProduk(
        kategori: kategoriDipilih.value,
        cari: searchController.text.trim(),
        page: nextPage,
        perPage: 8,
      );

      sedangMuatLebih.value = false;
      if (itemsBaru.isEmpty) {
        hasMore.value = false;
      } else {
        halamanSekarang.value = nextPage;
        daftarProduk.addAll(itemsBaru);
        if (itemsBaru.length < 8) {
          hasMore.value = false;
        }
      }
    } catch (e) {
      debugPrint('Gagal muat lebih produk di KelolaProdukController: $e');
      sedangMuatLebih.value = false;
    }
  }

  void gantiKategori(String kat) {
    if (kategoriDipilih.value == kat) return;
    kategoriDipilih.value = kat;
    muatProduk();
  }

  Future<bool> hapusProduk(int id) async {
    try {
      await LayananApi.hapusProduk(id);
      daftarProduk.removeWhere((p) => p.id == id);
      return true;
    } catch (e) {
      debugPrint('Gagal menghapus produk: $e');
      return false;
    }
  }
}
