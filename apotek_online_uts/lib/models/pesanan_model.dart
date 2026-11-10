import 'kurir_model.dart';

class PesananDetailModel {
  final int id;
  final int pesananId;
  final int produkId;
  final String namaProduk;
  final int hargaSaatBeli;
  final int jumlah;
  final int subtotal;
  final bool perluResep;

  PesananDetailModel({
    required this.id,
    required this.pesananId,
    required this.produkId,
    required this.namaProduk,
    required this.hargaSaatBeli,
    required this.jumlah,
    required this.subtotal,
    required this.perluResep,
  });

  factory PesananDetailModel.fromJson(Map<String, dynamic> json) {
    return PesananDetailModel(
      id: json['id'] as int,
      pesananId: json['pesanan_id'] is int
          ? json['pesanan_id']
          : int.tryParse(json['pesanan_id'].toString()) ?? 0,
      produkId: json['produk_id'] is int
          ? json['produk_id']
          : int.tryParse(json['produk_id'].toString()) ?? 0,
      namaProduk: json['nama_produk'] ?? '',
      hargaSaatBeli: json['harga_saat_beli'] is int
          ? json['harga_saat_beli']
          : int.tryParse(json['harga_saat_beli'].toString()) ?? 0,
      jumlah: json['jumlah'] is int
          ? json['jumlah']
          : int.tryParse(json['jumlah'].toString()) ?? 0,
      subtotal: json['subtotal'] is int
          ? json['subtotal']
          : int.tryParse(json['subtotal'].toString()) ?? 0,
      perluResep: json['perlu_resep'] == true || json['perlu_resep'] == 1,
    );
  }
}

class PesananModel {
  final int id;
  final String nomorPesanan;
  final String pelangganId;
  final String namaPenerima;
  final String alamat;
  final int? kurirId;
  final int ongkosKirim;
  final int subtotal;
  final int total;
  final String metodePembayaran;
  final String status;
  final String? nomorResep;
  final String? fotoResep;
  final String? rajaongkirService;
  final String? xenditInvoiceId;
  final String? xenditPaymentUrl;
  final String? xenditStatus;
  final String createdAt;
  final KurirModel? kurir;
  final List<PesananDetailModel> details;

  PesananModel({
    required this.id,
    required this.nomorPesanan,
    required this.pelangganId,
    required this.namaPenerima,
    required this.alamat,
    this.kurirId,
    required this.ongkosKirim,
    required this.subtotal,
    required this.total,
    required this.metodePembayaran,
    required this.status,
    this.nomorResep,
    this.fotoResep,
    this.rajaongkirService,
    this.xenditInvoiceId,
    this.xenditPaymentUrl,
    this.xenditStatus,
    required this.createdAt,
    this.kurir,
    required this.details,
  });

  factory PesananModel.fromJson(Map<String, dynamic> json) {
    var rawDetails = json['details'] as List? ?? [];
    List<PesananDetailModel> parsedDetails = rawDetails
        .map((e) => PesananDetailModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return PesananModel(
      id: json['id'] as int,
      nomorPesanan: json['nomor_pesanan'] ?? '',
      pelangganId: json['pelanggan_id'] ?? '',
      namaPenerima: json['nama_penerima'] ?? '',
      alamat: json['alamat'] ?? '',
      kurirId: json['kurir_id'] as int?,
      ongkosKirim: json['ongkos_kirim'] is int
          ? json['ongkos_kirim']
          : int.tryParse(json['ongkos_kirim'].toString()) ?? 0,
      subtotal: json['subtotal'] is int
          ? json['subtotal']
          : int.tryParse(json['subtotal'].toString()) ?? 0,
      total: json['total'] is int
          ? json['total']
          : int.tryParse(json['total'].toString()) ?? 0,
      metodePembayaran: json['metode_pembayaran'] ?? 'cod',
      status: json['status'] ?? 'menunggu_pembayaran',
      nomorResep: json['nomor_resep'],
      fotoResep: json['foto_resep'],
      rajaongkirService: json['rajaongkir_service'],
      xenditInvoiceId: json['xendit_invoice_id'],
      xenditPaymentUrl: json['xendit_payment_url'],
      xenditStatus: json['xendit_status'],
      createdAt: json['created_at'] ?? '',
      kurir: json['kurir'] != null ? KurirModel.fromJson(json['kurir']) : null,
      details: parsedDetails,
    );
  }
}
