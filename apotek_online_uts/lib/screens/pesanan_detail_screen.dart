import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pesanan_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../widgets/widget_keadaan.dart';
import 'katalog_screen.dart';

class PesananDetailScreen extends StatefulWidget {
  final int pesananId;

  const PesananDetailScreen({super.key, required this.pesananId});

  @override
  State<PesananDetailScreen> createState() => _PesananDetailScreenState();
}

class _PesananDetailScreenState extends State<PesananDetailScreen> {
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  InfoGalat? _galat;
  PesananModel? _pesanan;
  bool _sedangUbahStatus = false;

  @override
  void initState() {
    super.initState();
    _muatDetailPesanan();
  }

  Future<void> _muatDetailPesanan() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _galat = null;
    });

    try {
      var p = await LayananApi.getPesananDetail(widget.pesananId);
      if (!mounted) return;

      setState(() {
        _pesanan = p;
        _keadaan = KeadaanMuat.berhasil;
      });

      // Pesanan Xendit yang masih menunggu pembayaran: sinkronkan status
      // invoice ke API Xendit (server-to-server) agar tidak selamanya PENDING.
      if (p.metodePembayaran == 'xendit' && p.status == 'menunggu_pembayaran') {
        try {
          final terbaru = await LayananApi.syncStatusXendit(p.id);
          if (!mounted) return;
          setState(() => _pesanan = terbaru);
          p = terbaru;
        } catch (_) {
          // Gagal sinkron tidak perlu menggagalkan halaman detail.
        }
      }
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

  Future<void> _bukaInvoiceXendit() async {
    final url = _pesanan?.xenditPaymentUrl;
    if (url == null || url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL invoice Xendit tidak valid.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final berhasil = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!berhasil && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice Xendit tidak dapat dibuka.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _ubahStatus(String statusTarget, String pesanSukses) async {
    if (_pesanan == null) return;
    setState(() => _sedangUbahStatus = true);

    try {
      final hasil = await LayananApi.updateStatusPesanan(
        _pesanan!.id,
        statusTarget,
      );
      if (!mounted) return;

      setState(() {
        _pesanan = hasil;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesanSukses), backgroundColor: Colors.teal),
      );
    } catch (e) {
      if (!mounted) return;
      final pesan = e is InfoGalat ? e.pesan : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesan), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _sedangUbahStatus = false);
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

  String _formatStatusLabel(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rincian Pesanan'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const KatalogScreen()),
                (route) => false,
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang Status',
            onPressed: _muatDetailPesanan,
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Kembali ke Katalog',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const KatalogScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: WidgetKeadaan(
        keadaan: _keadaan,
        galat: _galat,
        onCobaLagi: _muatDetailPesanan,
        child: _pesanan == null
            ? const SizedBox()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      color: _getStatusColor(_pesanan!.status)
                          .withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _getStatusColor(_pesanan!.status),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Status Pesanan',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(_pesanan!.status),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _formatStatusLabel(_pesanan!.status),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No. Pesanan: ${_pesanan!.nomorPesanan}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Waktu: ${_pesanan!.createdAt}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Tujuan Pengiriman',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pesanan!.namaPenerima,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(_pesanan!.alamat),
                            const Divider(height: 16),
                            Text(
                              _pesanan!.rajaongkirService != null
                                  ? 'Pengiriman: ${_pesanan!.rajaongkirService}'
                                  : 'Kurir: ${_pesanan!.kurir?.nama ?? "Kurir Apotek"} (${_pesanan!.kurir?.wilayah ?? "-"})',
                              style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_pesanan!.nomorResep != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.assignment_outlined,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'No. Resep: ${_pesanan!.nomorResep}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Item Pembelian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._pesanan!.details.map((item) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            item.namaProduk,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item.jumlah} x ${formatRupiah(item.hargaSaatBeli)}',
                          ),
                          trailing: Text(
                            formatRupiah(item.subtotal),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    }),

                    const Divider(height: 24),

                    _buildRow(
                      'Subtotal Produk',
                      formatRupiah(_pesanan!.subtotal),
                    ),
                    _buildRow(
                      'Ongkos Kirim',
                      formatRupiah(_pesanan!.ongkosKirim),
                    ),
                    const Divider(),
                    _buildRow(
                      'Total Akhir',
                      formatRupiah(_pesanan!.total),
                      isTotal: true,
                    ),
                    _buildRow(
                      'Metode Pembayaran',
                      _pesanan!.metodePembayaran.toUpperCase(),
                    ),

                    if (_pesanan!.metodePembayaran == 'xendit' &&
                        _pesanan!.xenditPaymentUrl != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.indigo.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Xendit Payment Invoice:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            Text(
                              'ID: ${_pesanan!.xenditInvoiceId ?? "-"}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Status: ${_pesanan!.xenditStatus ?? "PENDING"}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _bukaInvoiceXendit,
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Buka Invoice Xendit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Alur UTS: pembeli menekan tombol bayar agar status
                    // menunggu_pembayaran -> menunggu_konfirmasi (pembayaran
                    // disimulasikan, admin kemudian mengonfirmasi -> dibayar).
                    // Pesanan Xendit (mode oyi) memakai sinkronisasi otomatis.
                    if (_pesanan!.status == 'menunggu_pembayaran' &&
                        _pesanan!.metodePembayaran != 'xendit') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _sedangUbahStatus
                              ? null
                              : () => _ubahStatus(
                                  'menunggu_konfirmasi',
                                  'Pembayaran diteruskan! Menunggu konfirmasi admin.',
                                ),
                          icon: const Icon(Icons.payments_outlined),
                          label: Text(
                            _pesanan!.metodePembayaran == 'transfer_manual'
                                ? 'Saya Sudah Transfer (Bayar)'
                                : 'Bayar Pesanan (COD)',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Semua perpindahan status lain dikelola admin. Pelanggan
                    // hanya mengonfirmasi penerimaan ketika barang sudah tiba.
                    if (_pesanan!.status == 'dikirim') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _sedangUbahStatus
                              ? null
                              : () => _ubahStatus(
                                  'selesai',
                                  'Pesanan telah selesai diterima dengan baik.',
                                ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Pesanan Sudah Sampai (Selesai)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.teal : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
