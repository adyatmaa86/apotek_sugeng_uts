import 'produk_model.dart';

class ItemKeranjangModel {
  final int id;
  final String pelangganId;
  final int produkId;
  final int jumlah;
  final int subtotalItem;
  final ProdukModel? produk;

  ItemKeranjangModel({
    required this.id,
    required this.pelangganId,
    required this.produkId,
    required this.jumlah,
    required this.subtotalItem,
    this.produk,
  });

  factory ItemKeranjangModel.fromJson(Map<String, dynamic> json) {
    return ItemKeranjangModel(
      id: json['id'] as int,
      pelangganId: json['pelanggan_id'] ?? '',
      produkId: json['produk_id'] as int,
      jumlah: json['jumlah'] is int
          ? json['jumlah']
          : int.tryParse(json['jumlah'].toString()) ?? 1,
      subtotalItem: json['subtotal_item'] is int
          ? json['subtotal_item']
          : int.tryParse(json['subtotal_item'].toString()) ?? 0,
      produk: json['produk'] != null
          ? ProdukModel.fromJson(json['produk'])
          : null,
    );
  }
}

class KeranjangDataModel {
  final List<ItemKeranjangModel> items;
  final int totalItem;
  final int subtotal;

  KeranjangDataModel({
    required this.items,
    required this.totalItem,
    required this.subtotal,
  });

  factory KeranjangDataModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    List<ItemKeranjangModel> parsedItems = rawItems
        .map(
          (item) => ItemKeranjangModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    return KeranjangDataModel(
      items: parsedItems,
      totalItem: json['total_item'] is int
          ? json['total_item']
          : parsedItems.length,
      subtotal: json['subtotal'] is int
          ? json['subtotal']
          : int.tryParse(json['subtotal'].toString()) ?? 0,
    );
  }
}
