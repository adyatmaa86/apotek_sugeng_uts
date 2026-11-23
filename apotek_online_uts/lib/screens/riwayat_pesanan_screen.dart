import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/riwayat_pesanan_controller.dart';
import '../models/pesanan_model.dart';
import '../utils/app_state.dart';
import '../widgets/nav_bar_bawah.dart';
import '../widgets/riwayat_pesanan/riwayat_bantuan_apoteker.dart';
import '../widgets/riwayat_pesanan/riwayat_dialog_resep.dart';
import '../widgets/riwayat_pesanan/riwayat_filter_tabs.dart';
import '../widgets/riwayat_pesanan/riwayat_kartu_pesanan.dart';
import '../widgets/riwayat_pesanan/riwayat_search_bar.dart';
import '../widgets/riwayat_pesanan/riwayat_top_header.dart';
import '../widgets/widget_keadaan.dart';
import 'pesanan_detail_screen.dart';
import 'profil_screen.dart';

class RiwayatPesananScreen extends StatefulWidget {
  const RiwayatPesananScreen({super.key});

  @override
  State<RiwayatPesananScreen> createState() => _RiwayatPesananScreenState();
}

class _RiwayatPesananScreenState extends State<RiwayatPesananScreen> {
  late final RiwayatPesananController _c;

  KeadaanMuat get _keadaan => _c.keadaan.value;
  InfoGalat? get _galat => _c.galat.value;
  List<PesananModel> get _semuaPesanan => _c.semuaPesanan;
  int get _tabFilter => _c.tabFilter.value;
  TextEditingController get _pencarianController => _c.pencarianController;
  DateTimeRange? get _rentangTanggal => _c.rentangTanggal.value;
  List<PesananModel> get _daftarPesananTersaring => _c.daftarPesananTersaring;
  int get _hitungBerlangsung => _c.hitungBerlangsung;
  int get _hitungSelesai => _c.hitungSelesai;

  @override
  void initState() {
    super.initState();
    _c = Get.put(RiwayatPesananController());
  }

  Future<void> _muatRiwayat() => _c.muatRiwayat();

  void _bukaProfil() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilScreen(),
      ),
    );
  }

  Future<void> _pilihRentangTanggal() async {
    final hasil = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _rentangTanggal,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0284C7),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (hasil != null) {
      _c.rentangTanggal.value = hasil;
    }
  }

  Future<void> _bukaDetail(PesananModel pesanan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PesananDetailScreen(pesananId: pesanan.id),
      ),
    );
    if (!mounted) return;
    _muatRiwayat();
  }

  Future<void> _beliLagiAtauLacak(PesananModel pesanan) async {
    if (pesanan.status.toLowerCase() == 'dikirim' && pesanan.kurir != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kurir: ${pesanan.kurir?.nama ?? "Ekspedisi"} (${pesanan.kurir?.wilayah ?? "Siap Kirim"})',
          ),
          backgroundColor: const Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      await _bukaDetail(pesanan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = _daftarPesananTersaring;

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              RiwayatTopHeader(
                onTapNotifikasi: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tidak ada pemberitahuan baru'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                onTapProfil: _bukaProfil,
              ),
              RiwayatFilterTabs(
                tabFilter: _tabFilter,
                totalSemua: _semuaPesanan.length,
                totalBerlangsung: _hitungBerlangsung,
                totalSelesai: _hitungSelesai,
                onTabSelected: (index) {
                  _c.tabFilter.value = index;
                },
              ),
              RiwayatSearchBar(
                controller: _pencarianController,
                rentangTanggal: _rentangTanggal,
                onPilihRentangTanggal: _pilihRentangTanggal,
                onHapusRentangTanggal: () {
                  _c.rentangTanggal.value = null;
                },
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _muatRiwayat();
                  },
                  color: const Color(0xFF0284C7),
                  child: WidgetKeadaan(
                    keadaan: _keadaan,
                    galat: _galat,
                    pesanKosong: _pencarianController.text.isNotEmpty ||
                            _tabFilter != 0 ||
                            _rentangTanggal != null
                        ? 'Tidak ada pesanan yang sesuai dengan filter atau kata kunci.'
                        : 'Anda belum memiliki riwayat pesanan obat.',
                    onCobaLagi: () {
                      _muatRiwayat();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: list.length + 1,
                      itemBuilder: (context, index) {
                        if (index == list.length) {
                          return RiwayatHelpBanner(
                            onTap: () => tampilkanBantuanApoteker(context),
                          );
                        }
                        final p = list[index];
                        return RiwayatKartuPesanan(
                          pesanan: p,
                          onLihatResep: () => tampilkanDialogResep(context, p),
                          onDetail: () => _bukaDetail(p),
                          onBeliLagiAtauLacak: () => _beliLagiAtauLacak(p),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const NavBarBawah(currentIndex: 3),
      );
    });
  }
}
