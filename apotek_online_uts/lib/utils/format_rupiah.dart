/// Utilitas pemformatan mata uang Rupiah.
String formatRupiah(num angka) {
  final s = angka.toStringAsFixed(0);
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(s[i]);
  }
  return 'Rp ${buffer.toString()}';
}
