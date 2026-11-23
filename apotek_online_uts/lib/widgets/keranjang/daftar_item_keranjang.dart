import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/keranjang_controller.dart';
import '../../models/keranjang_model.dart';
import 'kartu_item_keranjang.dart';

/// Daftar item keranjang yang ter-update secara reaktif dengan GetX.
class DaftarItemKeranjang extends StatelessWidget {
  final void Function(ItemKeranjangModel item, int delta) onUbahJumlah;
  final void Function(ItemKeranjangModel item) onHapus;

  const DaftarItemKeranjang({
    super.key,
    required this.onUbahJumlah,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = KeranjangController.to.items;
      return Column(
        children: items.map((item) {
          return KartuItemKeranjang(
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
