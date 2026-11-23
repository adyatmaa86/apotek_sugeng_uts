import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pesanan_detail_controller.dart';
import '../models/pesanan_model.dart';
import '../utils/app_state.dart';
import '../widgets/pesanan_detail/pesanan_aksi_button.dart';
import '../widgets/pesanan_detail/pesanan_alamat_card.dart';
import '../widgets/pesanan_detail/pesanan_items_card.dart';
import '../widgets/pesanan_detail/pesanan_status_card.dart';
import '../widgets/pesanan_detail/pesanan_tagihan_card.dart';
import '../widgets/pesanan_detail/pesanan_xendit_card.dart';
import '../widgets/widget_keadaan.dart';
import 'beranda_screen.dart';

class PesananDetailScreen extends StatefulWidget {
  final int pesananId;

  const PesananDetailScreen({super.key, required this.pesananId});

  @override
  State<PesananDetailScreen> createState() => _PesananDetailScreenState();
}

class _PesananDetailScreenState extends State<PesananDetailScreen> {
  late final PesananDetailController _c;

  KeadaanMuat get _keadaan => _c.keadaan.value;
  InfoGalat? get _galat => _c.galat.value;
  PesananModel? get _pesanan => _c.pesanan.value;
  bool get _sedangUbahStatus => _c.sedangUbahStatus.value;

  @override
  void initState() {
    super.initState();
    _c = Get.put(PesananDetailController(), tag: '${widget.pesananId}');
    _c.muatDetailPesanan(widget.pesananId);
  }

  Future<void> _muatDetailPesanan() => _c.muatDetailPesanan(widget.pesananId);
  Future<void> _bukaInvoiceXendit() => _c.bukaInvoiceXendit(context);
  Future<void> _ubahStatus(String statusTarget, String pesanSukses) =>
      _c.ubahStatus(context, statusTarget, pesanSukses);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final p = _pesanan;

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Rincian Pesanan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Color(0xFF0F172A),
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const BerandaScreen()),
                  (route) => false,
                );
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF334155)),
              tooltip: 'Muat Ulang Status',
              onPressed: _muatDetailPesanan,
            ),
            IconButton(
              icon: const Icon(Icons.home_outlined, color: Color(0xFF334155)),
              tooltip: 'Kembali ke Beranda',
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const BerandaScreen()),
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
          child: p == null
              ? const SizedBox()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PesananStatusCard(pesanan: p),
                      const SizedBox(height: 14),
                      PesananAlamatCard(pesanan: p),
                      const SizedBox(height: 14),
                      PesananItemsCard(details: p.details),
                      const SizedBox(height: 14),
                      PesananTagihanCard(pesanan: p),
                      PesananXenditCard(
                        pesanan: p,
                        onBukaInvoice: _bukaInvoiceXendit,
                      ),
                      PesananAksiButton(
                        pesanan: p,
                        sedangUbahStatus: _sedangUbahStatus,
                        onUbahStatus: _ubahStatus,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      );
    });
  }
}
