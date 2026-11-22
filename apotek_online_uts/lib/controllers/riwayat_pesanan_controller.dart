import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/pesanan_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';

/// GetX Controller untuk riwayat pesanan obat & resep.
class RiwayatPesananController extends GetxController {
  final Rx<KeadaanMuat> keadaan = KeadaanMuat.memuat.obs;
  final Rx<InfoGalat?> galat = Rx<InfoGalat?>(null);
  final RxList<PesananModel> semuaPesanan = <PesananModel>[].obs;

  final RxInt tabFilter = 0.obs; // 0: Semua, 1: Berlangsung, 2: Selesai
  final TextEditingController pencarianController = TextEditingController();
  final Rx<DateTimeRange?> rentangTanggal = Rx<DateTimeRange?>(null);

  @override
  void onInit() {
    super.onInit();
    muatRiwayat();
  }

  @override
  void onClose() {
    pencarianController.dispose();
    super.onClose();
  }

  Future<void> muatRiwayat() async {
    keadaan.value = KeadaanMuat.memuat;
    galat.value = null;

    try {
      final list = await LayananApi.getPesananList();
      semuaPesanan.assignAll(list);
      keadaan.value = list.isEmpty ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
    } catch (e) {
      galat.value = e is InfoGalat
          ? e
          : InfoGalat(jenis: JenisGalat.lainnya, pesan: e.toString());
      keadaan.value = KeadaanMuat.galat;
    }
  }

  static bool apakahPesananBerlangsung(String status) {
    final s = status.toLowerCase();
    return s == 'menunggu_pembayaran' ||
        s == 'menunggu_konfirmasi' ||
        s == 'diproses' ||
        s == 'dikirim' ||
        s == 'dibayar';
  }

  static bool apakahPesananSelesai(String status) {
    final s = status.toLowerCase();
    return s == 'selesai' || s == 'dibatalkan';
  }

  List<PesananModel> get daftarPesananTersaring {
    final keyword = pencarianController.text.trim().toLowerCase();
    final filter = tabFilter.value;
    final rentang = rentangTanggal.value;

    return semuaPesanan.where((p) {
      if (filter == 1 && !apakahPesananBerlangsung(p.status)) return false;
      if (filter == 2 && !apakahPesananSelesai(p.status)) return false;

      if (rentang != null) {
        final parsedDate = DateTime.tryParse(p.createdAt);
        if (parsedDate != null) {
          final start = DateTime(rentang.start.year, rentang.start.month, rentang.start.day);
          final end = DateTime(rentang.end.year, rentang.end.month, rentang.end.day, 23, 59, 59);
          if (parsedDate.isBefore(start) || parsedDate.isAfter(end)) return false;
        }
      }

      if (keyword.isNotEmpty) {
        final cocokNomor = p.nomorPesanan.toLowerCase().contains(keyword);
        final cocokPenerima = p.namaPenerima.toLowerCase().contains(keyword);
        final cocokProduk = p.details.any((d) => d.namaProduk.toLowerCase().contains(keyword));
        final cocokMetode = p.metodePembayaran.toLowerCase().contains(keyword);
        return cocokNomor || cocokPenerima || cocokProduk || cocokMetode;
      }

      return true;
    }).toList();
  }

  int get hitungBerlangsung =>
      semuaPesanan.where((p) => apakahPesananBerlangsung(p.status)).length;

  int get hitungSelesai =>
      semuaPesanan.where((p) => apakahPesananSelesai(p.status)).length;
}
