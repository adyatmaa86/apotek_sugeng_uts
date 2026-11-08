import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/app_state.dart';

class WidgetKeadaan extends StatelessWidget {
  final KeadaanMuat keadaan;
  final Widget child;
  final VoidCallback? onCobaLagi;
  final InfoGalat? galat;
  final String pesanKosong;
  final IconData ikonKosong;
  final Color? warnaTombol;

  const WidgetKeadaan({
    super.key,
    required this.keadaan,
    required this.child,
    this.onCobaLagi,
    this.galat,
    this.pesanKosong = 'Belum ada data tersedia.',
    this.ikonKosong = Icons.inbox_outlined,
    this.warnaTombol,
  });

  @override
  Widget build(BuildContext context) {
    switch (keadaan) {
      case KeadaanMuat.memuat:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat data dari server...'),
            ],
          ),
        );

      case KeadaanMuat.kosong:
        return _buildScrollable(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(ikonKosong, size: 72, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                pesanKosong,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        );

      case KeadaanMuat.galat:
        return _buildScrollable(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                galat?.jenis == JenisGalat.tidakAdaSambungan
                    ? Icons.wifi_off_rounded
                    : galat?.jenis == JenisGalat.batasWaktu
                    ? Icons.timer_off_outlined
                    : Icons.error_outline_rounded,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                galat?.pesan ?? 'Terjadi kesalahan sistem.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              if (onCobaLagi != null)
                ElevatedButton.icon(
                  onPressed: onCobaLagi,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: warnaTombol ?? const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
        );

      case KeadaanMuat.berhasil:
        return child;
    }
  }

  Widget _buildScrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(padding: const EdgeInsets.all(24), child: child),
            ),
          ),
        );
      },
    );
  }
}

String formatRupiah(int nominal) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return formatter.format(nominal);
}
