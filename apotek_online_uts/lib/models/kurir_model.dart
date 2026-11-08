class KurirModel {
  final int id;
  final String nama;
  final String wilayah;
  final int tarif;
  final String estimasi;

  KurirModel({
    required this.id,
    required this.nama,
    required this.wilayah,
    required this.tarif,
    required this.estimasi,
  });

  factory KurirModel.fromJson(Map<String, dynamic> json) {
    return KurirModel(
      id: json['id'] as int,
      nama: json['nama'] ?? '',
      wilayah: json['wilayah'] ?? '',
      tarif: json['tarif'] is int
          ? json['tarif']
          : int.tryParse(json['tarif'].toString()) ?? 0,
      estimasi: json['estimasi'] ?? '',
    );
  }
}
