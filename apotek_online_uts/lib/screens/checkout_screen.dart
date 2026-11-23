import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

import '../controllers/auth_controller.dart';
import '../controllers/checkout_controller.dart';
import '../models/keranjang_model.dart';
import '../utils/app_state.dart';
import '../utils/url_berkas.dart';
import '../widgets/checkout/checkout_alamat_section.dart';
import '../widgets/checkout/checkout_bottom_bar.dart';
import '../widgets/checkout/checkout_kurir_section.dart';
import '../widgets/checkout/checkout_pembayaran_section.dart';
import '../widgets/checkout/checkout_penerima_section.dart';
import '../widgets/checkout/checkout_ringkasan_section.dart';
import 'profil_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final KeranjangDataModel keranjangData;

  const CheckoutScreen({super.key, required this.keranjangData});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaController = TextEditingController(
    text: AuthController.to.pengguna.value?.nama.isNotEmpty == true
        ? AuthController.to.pengguna.value!.nama
        : 'Ceo Adyatma86',
  );
  final TextEditingController _teleponController = TextEditingController(
    text: '0812-3456-7890',
  );
  final TextEditingController _alamatDetailController = TextEditingController();
  final TextEditingController _kodePostalController = TextEditingController();
  final TextEditingController _resepController = TextEditingController();

  late final CheckoutController _c;
  late final String _idempotencyKey;

  List<Map<String, dynamic>> get _daftarProvinsi => _c.daftarProvinsi;
  List<Map<String, dynamic>> get _daftarKota => _c.daftarKota;
  List<Map<String, dynamic>> get _daftarKecamatan => _c.daftarKecamatan;
  List<Map<String, dynamic>> get _daftarDesa => _c.daftarDesa;

  Map<String, dynamic>? get _provinsiDipilih => _c.provinsiDipilih.value;
  Map<String, dynamic>? get _kotaDipilih => _c.kotaDipilih.value;
  Map<String, dynamic>? get _kecamatanDipilih => _c.kecamatanDipilih.value;
  Map<String, dynamic>? get _desaDipilih => _c.desaDipilih.value;

  bool get _isMemuatProvinsi => _c.isMemuatProvinsi.value;
  bool get _isMemuatKota => _c.isMemuatKota.value;
  bool get _isMemuatKecamatan => _c.isMemuatKecamatan.value;
  bool get _isMemuatDesa => _c.isMemuatDesa.value;

  String? get _galatKota => _c.galatKota.value;
  String? get _galatKecamatan => _c.galatKecamatan.value;
  String? get _galatDesa => _c.galatDesa.value;

  List<Map<String, dynamic>> get _layananRajaOngkir => _c.layananRajaOngkir;
  Map<String, dynamic>? get _layananDipilih => _c.layananDipilih.value;
  int get _ongkirRajaOngkir => _c.ongkirRajaOngkir.value;
  bool get _isMemuatTarif => _c.isMemuatTarif.value;

  LatLng get _posisiPeta => _c.posisiPeta.value;
  Set<Marker> get _markers => _c.markers;
  bool get _isMemuatLokasi => _c.isMemuatLokasi.value;

  String get _metodePembayaran => _c.metodePembayaran.value;
  bool get _isSedangCheckout => _c.isSedangCheckout.value;
  InfoGalat? get _galatCheckout => _c.galatCheckout.value;

  @override
  void initState() {
    super.initState();
    _c = Get.put(CheckoutController());
    _idempotencyKey = const Uuid().v4();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _alamatDetailController.dispose();
    _kodePostalController.dispose();
    _resepController.dispose();
    super.dispose();
  }

  bool get _apakahAdaResep =>
      widget.keranjangData.items.any((item) => item.produk?.perluResep == true);

  int get _hitungPerkiraanTotal =>
      widget.keranjangData.subtotal + _ongkirRajaOngkir;

  String get _alamatLengkap {
    final bagian = [
      _alamatDetailController.text.trim(),
      _desaDipilih?['name'],
      _kecamatanDipilih?['name'],
      _kotaDipilih?['name'],
      _provinsiDipilih?['name'],
      _kodePostalController.text.trim().isNotEmpty
          ? 'Kode Pos: ${_kodePostalController.text.trim()}'
          : null,
      'Kontak/WA: ${_teleponController.text.trim()}',
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');
    return bagian;
  }

  Future<void> _prosesCheckout() => _c.prosesCheckout(
        context: context,
        formKey: _formKey,
        idempotencyKey: _idempotencyKey,
        nama: _namaController.text,
        alamatLengkap: _alamatLengkap,
        nomorResep: _resepController.text,
      );

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fotoUrl = UrlBerkas.dari(AuthController.to.pengguna.value?.fotoUrl);
      final namaPengguna =
          AuthController.to.pengguna.value?.nama ?? 'Tamu (Guest)';

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Checkout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilScreen(),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF0284C7),
                  backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                      ? NetworkImage(fotoUrl)
                      : null,
                  child: fotoUrl == null || fotoUrl.isEmpty
                      ? Text(
                          namaPengguna.isNotEmpty
                              ? namaPengguna.substring(0, 1).toUpperCase()
                              : 'T',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_galatCheckout != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _galatCheckout!.pesan,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 1. INFORMASI PENERIMA
                CheckoutPenerimaSection(
                  namaController: _namaController,
                  teleponController: _teleponController,
                  resepController: _resepController,
                  fotoResep: _c.fotoResep.value,
                  apakahAdaResep: _apakahAdaResep,
                  onPilihFoto: (source) => _c.pilihFotoResep(source),
                  onHapusFoto: _c.hapusFotoResep,
                ),
                const SizedBox(height: 14),

                // 2. ALAMAT PENGIRIMAN & PETA
                CheckoutAlamatSection(
                  isMemuatLokasi: _isMemuatLokasi,
                  onDapatkanLokasi: () => _c.dapatkanLokasiSaya(
                    context: context,
                    kodePosController: _kodePostalController,
                    alamatDetailController: _alamatDetailController,
                  ),
                  posisiPeta: _posisiPeta,
                  markers: _markers,
                  onMapCreated: (ctrl) => _c.mapController = ctrl,
                  onPetaTap: (pos) => _c.onPetaTap(
                    pos,
                    kodePosController: _kodePostalController,
                    alamatDetailController: _alamatDetailController,
                  ),
                  isMemuatProvinsi: _isMemuatProvinsi,
                  daftarProvinsi: _daftarProvinsi,
                  provinsiDipilih: _provinsiDipilih,
                  onProvinsiChanged: (val) {
                    _c.provinsiDipilih.value = val;
                    if (val != null) _c.muatKota(val['id'].toString());
                  },
                  isMemuatKota: _isMemuatKota,
                  daftarKota: _daftarKota,
                  kotaDipilih: _kotaDipilih,
                  galatKota: _galatKota,
                  onRetryKota: _provinsiDipilih != null
                      ? () => _c.muatKota(_provinsiDipilih!['id'].toString())
                      : null,
                  onKotaChanged: (val) {
                    _c.kotaDipilih.value = val;
                    if (val != null) {
                      _c.muatKecamatan(val['id'].toString());
                    }
                  },
                  isMemuatKecamatan: _isMemuatKecamatan,
                  daftarKecamatan: _daftarKecamatan,
                  kecamatanDipilih: _kecamatanDipilih,
                  galatKecamatan: _galatKecamatan,
                  onRetryKecamatan: _kotaDipilih != null
                      ? () => _c.muatKecamatan(_kotaDipilih!['id'].toString())
                      : null,
                  onKecamatanChanged: (val) {
                    _c.kecamatanDipilih.value = val;
                    if (val != null) {
                      _c.muatDesa(val['id'].toString());
                    }
                  },
                  isMemuatDesa: _isMemuatDesa,
                  daftarDesa: _daftarDesa,
                  desaDipilih: _desaDipilih,
                  galatDesa: _galatDesa,
                  onRetryDesa: _kecamatanDipilih != null
                      ? () => _c.muatDesa(_kecamatanDipilih!['id'].toString())
                      : null,
                  onDesaChanged: (val) => _c.desaDipilih.value = val,
                  alamatDetailController: _alamatDetailController,
                  kodePosController: _kodePostalController,
                ),
                const SizedBox(height: 14),

                // 3. KURIR RAJAONGKIR
                CheckoutKurirSection(
                  kotaDipilih: _kotaDipilih,
                  isMemuatTarif: _isMemuatTarif,
                  layananRajaOngkir: _layananRajaOngkir,
                  layananDipilih: _layananDipilih,
                  onLayananDipilih: (val) => _c.pilihLayanan(val),
                ),
                const SizedBox(height: 14),

                // 4. METODE PEMBAYARAN
                CheckoutPembayaranSection(
                  metodePembayaran: _metodePembayaran,
                  onMetodeChanged: (val) => _c.metodePembayaran.value = val,
                ),
                const SizedBox(height: 14),

                // 5. RINGKASAN PESANAN
                CheckoutRingkasanSection(
                  keranjangData: widget.keranjangData,
                  ongkirRajaOngkir: _ongkirRajaOngkir,
                  hitungPerkiraanTotal: _hitungPerkiraanTotal,
                ),
              ],
            ),
          ),
        ),

        // Bottom Bar Checkout
        bottomNavigationBar: CheckoutBottomBar(
          totalTagihan: _hitungPerkiraanTotal,
          isSedangCheckout: _isSedangCheckout,
          onProsesCheckout: _prosesCheckout,
        ),
      );
    });
  }
}
