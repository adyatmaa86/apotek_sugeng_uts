import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pesanan_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';

/// GetX Controller untuk Detail Pesanan Obat & Resep.
class PesananDetailController extends GetxController {
  final Rx<KeadaanMuat> keadaan = KeadaanMuat.memuat.obs;
  final Rx<InfoGalat?> galat = Rx<InfoGalat?>(null);
  final Rx<PesananModel?> pesanan = Rx<PesananModel?>(null);
  final RxBool sedangUbahStatus = false.obs;

  Future<void> muatDetailPesanan(int pesananId) async {
    keadaan.value = KeadaanMuat.memuat;
    galat.value = null;

    try {
      var p = await LayananApi.getPesananDetail(pesananId);
      pesanan.value = p;
      keadaan.value = KeadaanMuat.berhasil;

      // Pesanan Xendit yang masih menunggu pembayaran: sinkronkan status
      // invoice ke API Xendit (server-to-server) agar tidak selamanya PENDING.
      if (p.metodePembayaran == 'xendit' && p.status == 'menunggu_pembayaran') {
        try {
          final terbaru = await LayananApi.syncStatusXendit(p.id);
          pesanan.value = terbaru;
        } catch (_) {
          // Gagal sinkron tidak perlu menggagalkan halaman detail.
        }
      }
    } catch (e) {
      galat.value = e is InfoGalat
          ? e
          : InfoGalat(jenis: JenisGalat.lainnya, pesan: e.toString());
      keadaan.value = KeadaanMuat.galat;
    }
  }

  Future<void> bukaInvoiceXendit(BuildContext context) async {
    final url = pesanan.value?.xenditPaymentUrl;
    if (url == null || url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL invoice Xendit tidak valid.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final berhasil = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!berhasil && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice Xendit tidak dapat dibuka.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> ubahStatus(
    BuildContext context,
    String statusTarget,
    String pesanSukses,
  ) async {
    final p = pesanan.value;
    if (p == null) return;
    sedangUbahStatus.value = true;

    try {
      final hasil = await LayananApi.updateStatusPesanan(
        p.id,
        statusTarget,
      );
      pesanan.value = hasil;

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesanSukses),
          backgroundColor: const Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
        ),
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
      sedangUbahStatus.value = false;
    }
  }
}
