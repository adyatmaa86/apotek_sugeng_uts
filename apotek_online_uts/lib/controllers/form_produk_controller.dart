import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/produk_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';

/// GetX Controller untuk Formulir Tambah / Ubah Produk (Mode UTS).
class FormProdukController extends GetxController {
  final ProdukModel? produkAwal;
  FormProdukController({this.produkAwal});

  late final RxString kategori;
  late final RxBool perluResep;
  late final RxBool tersedia;
  final RxBool sedangMenyimpan = false.obs;

  @override
  void onInit() {
    super.onInit();
    kategori = (produkAwal?.kategori ?? 'Obat').obs;
    perluResep = (produkAwal?.perluResep ?? false).obs;
    tersedia = (produkAwal?.tersedia ?? true).obs;
  }

  Future<bool> simpan({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required String nama,
    required String harga,
    required String stok,
    required String batas,
    required String satuan,
    required String deskripsi,
  }) async {
    if (!formKey.currentState!.validate()) return false;

    sedangMenyimpan.value = true;

    final body = {
      'nama': nama.trim(),
      'harga': int.tryParse(harga.trim()) ?? 0,
      'kategori': kategori.value,
      'stok': int.tryParse(stok.trim()) ?? 0,
      'batas_per_pembelian': int.tryParse(batas.trim()) ?? 1,
      'satuan': satuan.trim(),
      'deskripsi': deskripsi.trim(),
      'perlu_resep': perluResep.value,
      'tersedia': tersedia.value,
    };

    try {
      if (produkAwal != null) {
        await LayananApi.updateProduk(produkAwal!.id, body);
      } else {
        await LayananApi.tambahProduk(body);
      }
      return true;
    } catch (e) {
      final pesan = e is InfoGalat ? e.pesan : e.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pesan),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } finally {
      sedangMenyimpan.value = false;
    }
  }
}
