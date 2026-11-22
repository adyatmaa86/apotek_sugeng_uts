import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../models/keranjang_model.dart';
import '../models/kurir_model.dart';
import '../screens/pesanan_detail_screen.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';

/// GetX Controller untuk Checkout Mode UTS (Apotek Sugeng).
class CheckoutUtsController extends GetxController {
  final Rx<File?> fotoResep = Rx<File?>(null);
  final RxList<KurirModel> daftarKurir = <KurirModel>[].obs;
  final Rx<KurirModel?> kurirDipilih = Rx<KurirModel?>(null);
  final RxBool isMemuatKurir = false.obs;
  final Rx<String?> galatKurir = Rx<String?>(null);

  final RxString metodePembayaran = 'cod'.obs;
  final RxBool isSedangCheckout = false.obs;
  final Rx<InfoGalat?> galatCheckout = Rx<InfoGalat?>(null);

  @override
  void onInit() {
    super.onInit();
    muatKurir();
  }

  Future<void> pilihFotoResep(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      fotoResep.value = File(picked.path);
    }
  }

  void hapusFotoResep() {
    fotoResep.value = null;
  }

  int get ongkir => kurirDipilih.value?.tarif ?? 0;

  int hitungTotal(KeranjangDataModel keranjang) => keranjang.subtotal + ongkir;

  Future<void> muatKurir() async {
    isMemuatKurir.value = true;
    galatKurir.value = null;

    try {
      final kurir = await LayananApi.getKurir();
      daftarKurir.assignAll(kurir);
      if (kurir.isNotEmpty && kurirDipilih.value == null) {
        kurirDipilih.value = kurir.first;
      }
    } catch (e) {
      galatKurir.value = e is InfoGalat ? e.pesan : e.toString();
    } finally {
      isMemuatKurir.value = false;
    }
  }

  Future<void> prosesCheckout({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required String idempotencyKey,
    required String nama,
    required String telepon,
    required String alamat,
    required String nomorResep,
  }) async {
    if (!formKey.currentState!.validate()) return;

    if (kurirDipilih.value == null) {
      galatCheckout.value = InfoGalat(
        jenis: JenisGalat.lainnya,
        pesan: 'Pilih wilayah pengantaran kurir terlebih dahulu.',
      );
      return;
    }

    isSedangCheckout.value = true;
    galatCheckout.value = null;

    try {
      final alamatLengkap = '$alamat (Kontak/WA: $telepon)';

      final pesanan = await LayananApi.checkout(
        idempotencyKey: idempotencyKey,
        namaPenerima: nama.trim(),
        alamat: alamatLengkap,
        kurirId: kurirDipilih.value!.id,
        metodePembayaran: metodePembayaran.value,
        nomorResep: nomorResep.trim().isEmpty ? null : nomorResep.trim(),
        fotoResep: fotoResep.value,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan #${pesanan.nomorPesanan} berhasil dibuat!'),
          backgroundColor: const Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PesananDetailScreen(pesananId: pesanan.id),
        ),
      );
    } catch (e) {
      galatCheckout.value = e is InfoGalat
          ? e
          : InfoGalat(jenis: JenisGalat.lainnya, pesan: e.toString());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(galatCheckout.value!.pesan),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      isSedangCheckout.value = false;
    }
  }
}
