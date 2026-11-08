import 'package:flutter/material.dart';

import '../models/pesanan_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../widgets/widget_keadaan.dart';
import 'pesanan_detail_screen.dart';

class RiwayatPesananScreen extends StatefulWidget {
  const RiwayatPesananScreen({super.key});

  @override
  State<RiwayatPesananScreen> createState() => _RiwayatPesananScreenState();
}

class _RiwayatPesananScreenState extends State<RiwayatPesananScreen> {
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  InfoGalat? _galat;
  List<PesananModel> _daftarPesanan = [];

  @override
  void initState() {
    super.initState();
    _muatRiwayat();
  }

  Future<void> _muatRiwayat() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _galat = null;
    });

    try {
      final list = await LayananApi.getPesananList();
      if (!mounted) return;

      setState(() {
        _daftarPesanan = list;
        _keadaan = list.isEmpty ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _galat = e is InfoGalat
            ? e
            : InfoGalat(jenis: JenisGalat.lainnya, pesan: e.toString());
        _keadaan = KeadaanMuat.galat;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'menunggu_pembayaran':
        return Colors.orange;
      case 'menunggu_konfirmasi':
        return Colors.amber.shade800;
      case 'dibayar':
      case 'diproses':
        return Colors.blue;
      case 'dikirim':
        return Colors.indigo;
      case 'selesai':
        return Colors.green;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _muatRiwayat,
        child: WidgetKeadaan(
          keadaan: _keadaan,
          galat: _galat,
          pesanKosong: 'Anda belum memiliki riwayat pesanan obat.',
          onCobaLagi: _muatRiwayat,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: _daftarPesanan.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final p = _daftarPesanan[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PesananDetailScreen(pesananId: p.id),
                      ),
                    );
                    if (!mounted) return;
                    _muatRiwayat();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                p.nomorPesanan,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(p.status)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p.status.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(p.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${p.details.length} Produk • Total: ${formatRupiah(p.total)}',
                          style: TextStyle(
                            color: Colors.teal.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Metode: ${p.metodePembayaran.toUpperCase()} • ${p.createdAt}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
