import 'package:get/get.dart';

import '../models/keranjang_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';

/// GetX Controller untuk mengelola keadaan keranjang belanja.
/// Terhubung secara reaktif dengan badge jumlah keranjang di seluruh aplikasi.
class KeranjangController extends GetxController {
  static KeranjangController get to => Get.find<KeranjangController>();

  final Rx<KeadaanMuat> keadaan = KeadaanMuat.memuat.obs;
  final Rx<InfoGalat?> galat = Rx<InfoGalat?>(null);
  final Rx<KeranjangDataModel?> keranjangData = Rx<KeranjangDataModel?>(null);

  bool get adaItem =>
      keranjangData.value != null && keranjangData.value!.items.isNotEmpty;
  int get totalItem => keranjangData.value?.totalItem ?? 0;
  num get subtotal => keranjangData.value?.subtotal ?? 0;
  List<ItemKeranjangModel> get items => keranjangData.value?.items ?? [];

  @override
  void onInit() {
    super.onInit();
    muatKeranjang();
  }

  Future<void> muatKeranjang({bool senyap = false}) async {
    if (!senyap) {
      keadaan.value = KeadaanMuat.memuat;
      galat.value = null;
    }

    try {
      final data = await LayananApi.getKeranjang();
      keranjangData.value = data;
      keadaan.value =
          data.items.isEmpty ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
    } catch (e) {
      galat.value = e is InfoGalat
          ? e
          : InfoGalat(
              jenis: JenisGalat.tidakAdaSambungan,
              pesan: e.toString(),
            );
      keadaan.value = KeadaanMuat.galat;
    }
  }

  Future<String?> tambahItem(int produkId, int jumlah) async {
    try {
      await LayananApi.tambahKeranjang(produkId, jumlah);
      await muatKeranjang(senyap: true);
      return null;
    } catch (e) {
      final err = e is InfoGalat
          ? e
          : InfoGalat(jenis: JenisGalat.lainnya, pesan: e.toString());
      return err.pesan;
    }
  }

  /// Ubah jumlah item secara reaktif.
  /// Memperbarui state item di memori seketika (optimistic update),
  /// sehingga hanya item terkait yang ter-update tanpa me-render ulang seluruh layar.
  Future<String?> ubahJumlah(ItemKeranjangModel item, int delta) async {
    final jumlahBaru = item.jumlah + delta;
    if (jumlahBaru <= 0) {
      return await hapusItem(item.id);
    }

    final currentData = keranjangData.value;
    if (currentData == null) return null;

    final index = currentData.items.indexWhere((it) => it.id == item.id);
    if (index == -1) return null;

    final hargaSatuan = item.produk?.harga ?? 0;
    final itemLama = currentData.items[index];

    // Optimistic update
    final itemBaru = ItemKeranjangModel(
      id: itemLama.id,
      pelangganId: itemLama.pelangganId,
      produkId: itemLama.produkId,
      jumlah: jumlahBaru,
      subtotalItem: (jumlahBaru * hargaSatuan).toInt(),
      produk: itemLama.produk,
    );

    final listBaru = List<ItemKeranjangModel>.from(currentData.items);
    listBaru[index] = itemBaru;
    final selisih = jumlahBaru - itemLama.jumlah;
    final subtotalBaru =
        (currentData.subtotal + (selisih * hargaSatuan)).toInt();
    final totalItemBaru = currentData.totalItem + selisih;

    keranjangData.value = KeranjangDataModel(
      items: listBaru,
      totalItem: totalItemBaru,
      subtotal: subtotalBaru,
    );

    try {
      await LayananApi.ubahJumlahKeranjang(item.id, jumlahBaru);
      return null;
    } catch (e) {
      // Revert bila server gagal
      keranjangData.value = currentData;
      final err = e is InfoGalat
          ? e
          : InfoGalat(jenis: JenisGalat.lainnya, pesan: e.toString());
      return err.pesan;
    }
  }

  Future<String?> hapusItem(int keranjangId) async {
    final currentData = keranjangData.value;
    if (currentData != null) {
      final itemTarget =
          currentData.items.firstWhereOrNull((it) => it.id == keranjangId);
      if (itemTarget != null) {
        final hargaSatuan = itemTarget.produk?.harga ?? 0;
        final listBaru =
            currentData.items.where((it) => it.id != keranjangId).toList();
        final subtotalBaru =
            (currentData.subtotal - (itemTarget.jumlah * hargaSatuan)).toInt();
        final totalItemBaru = currentData.totalItem - itemTarget.jumlah;

        keranjangData.value = KeranjangDataModel(
          items: listBaru,
          totalItem: totalItemBaru,
          subtotal: subtotalBaru,
        );
        if (listBaru.isEmpty) {
          keadaan.value = KeadaanMuat.kosong;
        }
      }
    }

    try {
      await LayananApi.hapusItemKeranjang(keranjangId);
      return null;
    } catch (e) {
      if (currentData != null) keranjangData.value = currentData;
      final err = e is InfoGalat
          ? e
          : InfoGalat(jenis: JenisGalat.lainnya, pesan: e.toString());
      return err.pesan;
    }
  }

  Future<String?> hapusSemua() async {
    final currentData = keranjangData.value;
    if (currentData == null || currentData.items.isEmpty) return null;

    keranjangData.value = KeranjangDataModel(
      items: [],
      totalItem: 0,
      subtotal: 0,
    );
    keadaan.value = KeadaanMuat.kosong;

    try {
      for (final item in currentData.items) {
        await LayananApi.hapusItemKeranjang(item.id);
      }
      return null;
    } catch (e) {
      keranjangData.value = currentData;
      keadaan.value = KeadaanMuat.berhasil;
      final err = e is InfoGalat
          ? e
          : InfoGalat(jenis: JenisGalat.lainnya, pesan: e.toString());
      return err.pesan;
    }
  }
}
