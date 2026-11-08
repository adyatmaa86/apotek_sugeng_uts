/// Konfigurasi Google Sign-In.
///
/// CARA MENGISI (dari Google Cloud Console → APIs & Services → Credentials):
/// 1. Buat OAuth 2.0 Client ID **tipe "Web application"**
///    → salin ke [googleWebClientId] di bawah.
/// 2. Buat OAuth 2.0 Client ID **tipe "Android"**
///    (isi package name `com.example.apotek_online_uts` + SHA-1 debug:
///    jalankan `cd android && ./gradlew signingReport`)
///    → salin ke [googleAndroidClientId].
/// 3. Di server Laravel, isi `.env`:
///    `GOOGLE_CLIENT_ID=` (nilai yang sama dengan googleWebClientId)
///    lalu `php artisan config:clear`.
///
/// Selama masih kosong, tombol Google tetap tampil tetapi menampilkan
/// petunjuk; login email/password sudah berfungsi penuh tanpa ini.
class KonfigurasiAuth {
  /// OAuth 2.0 Client ID tipe "Web application" (dipakai untuk id_token).
  static const String googleWebClientId = '496845928699-4m6m2k6pp2a6dp13k5mpe9fqn4t8a6oe.apps.googleusercontent.com';

  /// OAuth 2.0 Client ID tipe "Android" (opsional jika sudah ada
  /// google-services.json; isi salah satu saja).
  static const String googleAndroidClientId = '496845928699-3bh7emropl2k37pf23fo8pb7bu4hvjpk.apps.googleusercontent.com';

  static bool get googleTerpasang => googleWebClientId.isNotEmpty;
}
