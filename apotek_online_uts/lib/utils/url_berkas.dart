import '../services/layanan_api.dart';

class UrlBerkas {
  static String? _dasarKustom;
  static String get dasar => _dasarKustom ?? LayananApi.baseUrl;
  static set dasar(String nilai) => _dasarKustom = nilai;

  static const Set<String> _loopback = {
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
    '0.0.0.0',
  };

  static String? dari(Object? mentah) {
    if (mentah == null) return null;
    final nilai = mentah.toString().trim();
    if (nilai.isEmpty || nilai == 'null') return null;

    final api = Uri.parse(dasar);
    final origin = Uri(
      scheme: api.scheme,
      host: api.host,
      port: api.hasPort ? api.port : null,
    );

    if (nilai.startsWith('http://') || nilai.startsWith('https://')) {
      final asal = Uri.tryParse(nilai);
      if (asal == null) return nilai;

      final apakahHostLokal = _loopback.contains(asal.host) ||
          asal.host.startsWith('192.168.') ||
          asal.host.startsWith('10.0.');

      if (!apakahHostLokal && asal.host != origin.host) {
        return nilai;
      }

      return asal
          .replace(
            scheme: origin.scheme,
            host: origin.host,
            port: origin.hasPort ? origin.port : null,
          )
          .toString();
    }

    var path = nilai.startsWith('/') ? nilai.substring(1) : nilai;
    if (!path.startsWith('storage/')) {
      path = 'storage/$path';
    }
    return origin.replace(path: '/$path').toString();
  }
}
