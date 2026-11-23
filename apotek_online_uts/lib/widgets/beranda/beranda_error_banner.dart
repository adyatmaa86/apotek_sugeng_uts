import 'package:flutter/material.dart';

/// Banner peringatan kesalahan koneksi / pemuatan data di bagian atas konten.
class BerandaErrorBanner extends StatelessWidget {
  final String pesan;
  final VoidCallback onCobaLagi;

  const BerandaErrorBanner({
    super.key,
    required this.pesan,
    required this.onCobaLagi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: Colors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pesan,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.red,
              ),
            ),
          ),
          TextButton(
            onPressed: onCobaLagi,
            child: const Text(
              'Coba Lagi',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
