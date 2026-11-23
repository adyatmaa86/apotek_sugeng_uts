import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/produk_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';

/// GetX Controller untuk halaman Beranda.
class BerandaController extends GetxController {
  final Rx<KeadaanMuat> keadaan = KeadaanMuat.memuat.obs;
  final Rx<InfoGalat?> galat = Rx<InfoGalat?>(null);
  final RxList<ProdukModel> daftarProduk = <ProdukModel>[].obs;

  final RxString kategoriDipilih = 'Semua'.obs;
  final List<String> kategoriList = const ['Semua', 'Obat', 'Alat Kesehatan'];
  final TextEditingController searchController = TextEditingController();

  final RxInt halamanSekarang = 1.obs;
  final RxBool hasMore = true.obs;
  final RxBool sedangMuatLebih = false.obs;
  final RxBool modeUtsAktif = false.obs;

  @override
  void onInit() {
    super.onInit();
    muatData();
    muatConfig();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> muatConfig() async {
    try {
      final config = await LayananApi.getAppConfig();
      modeUtsAktif.value = config['mode_uts'] == true;
    } catch (e) {
      debugPrint('Gagal memuat app config di BerandaController: $e');
    }
  }

  Future<void> muatData() async {
    keadaan.value = KeadaanMuat.memuat;
    galat.value = null;
    halamanSekarang.value = 1;
    hasMore.value = true;
    sedangMuatLebih.value = false;

    try {
      final produk = await LayananApi.getProduk(
        kategori: kategoriDipilih.value,
        cari: searchController.text.trim(),
        page: 1,
        perPage: 10,
      );

      daftarProduk.assignAll(produk);
      hasMore.value = produk.length >= 10;
      keadaan.value = produk.isEmpty ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
    } catch (e) {
      galat.value = e is InfoGalat
          ? e
          : InfoGalat(jenis: JenisGalat.tidakAdaSambungan, pesan: e.toString());
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
        perPage: 10,
      );

      sedangMuatLebih.value = false;
      if (itemsBaru.isEmpty) {
        hasMore.value = false;
      } else {
        halamanSekarang.value = nextPage;
        daftarProduk.addAll(itemsBaru);
        if (itemsBaru.length < 10) {
          hasMore.value = false;
        }
      }
    } catch (e) {
      debugPrint('Gagal muat lebih produk di BerandaController: $e');
      sedangMuatLebih.value = false;
    }
  }

  void gantiKategori(String kategori) {
    if (kategoriDipilih.value == kategori) return;
    kategoriDipilih.value = kategori;
    muatData();
  }
}
