enum KeadaanMuat { memuat, berhasil, kosong, galat }

enum JenisGalat {
  tidakAdaSambungan,
  batasWaktu,
  validasi,
  bentrokKeadaan,
  galatServer,
  lainnya,
}

class InfoGalat {
  final JenisGalat jenis;
  final String pesan;
  final Map<String, List<String>>? rincianValidasi;

  InfoGalat({required this.jenis, required this.pesan, this.rincianValidasi});

  @override
  String toString() => pesan;
}

class ProfilPengguna {
  final int id;
  final String nama;
  final String email;
  final String? fotoUrl;
  final bool isAdmin;

  ProfilPengguna({
    required this.id,
    required this.nama,
    required this.email,
    this.fotoUrl,
    this.isAdmin = false,
  });

  factory ProfilPengguna.fromJson(Map<String, dynamic> json) {
    return ProfilPengguna(
      id: json['id'] as int,
      nama: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fotoUrl: json['foto_url']?.toString(),
      isAdmin: json['is_admin'] == true,
    );
  }
}
