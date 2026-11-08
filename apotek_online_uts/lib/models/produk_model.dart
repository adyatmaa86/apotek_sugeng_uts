class ProdukModel {
  final int id;
  final String nama;
  final int harga;
  final String kategori;
  final int stok;
  final bool tersedia;
  final String? deskripsi;

  final bool perluResep;
  final int batasPerPembelian;
  final String satuan;
  final String? golongan;
  final String? fotoUrl;

  ProdukModel({
    required this.id,
    required this.nama,
    required this.harga,
    required this.kategori,
    required this.stok,
    required this.tersedia,
    this.deskripsi,
    required this.perluResep,
    required this.batasPerPembelian,
    required this.satuan,
    this.golongan,
    this.fotoUrl,
  });

  factory ProdukModel.fromJson(Map<String, dynamic> json) {
    return ProdukModel(
      id: json['id'] as int,
      nama: json['nama'] ?? '',
      harga: json['harga'] is int
          ? json['harga']
          : int.tryParse(json['harga'].toString()) ?? 0,
      kategori: json['kategori'] ?? '',
      stok: json['stok'] is int
          ? json['stok']
          : int.tryParse(json['stok'].toString()) ?? 0,
      tersedia: json['tersedia'] == true || json['tersedia'] == 1,
      deskripsi: json['deskripsi'],
      perluResep: json['perlu_resep'] == true || json['perlu_resep'] == 1,
      batasPerPembelian: json['batas_per_pembelian'] is int
          ? json['batas_per_pembelian']
          : int.tryParse(json['batas_per_pembelian'].toString()) ?? 10,
      satuan: json['satuan'] ?? 'Pcs',
      golongan: json['golongan'],
      fotoUrl: json['foto_url'] ?? json['foto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'harga': harga,
      'kategori': kategori,
      'stok': stok,
      'tersedia': tersedia,
      'deskripsi': deskripsi,
      'perlu_resep': perluResep,
      'batas_per_pembelian': batasPerPembelian,
      'satuan': satuan,
      'golongan': golongan,
    };
  }
}
