import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../controllers/auth_controller.dart';
import '../controllers/checkout_uts_controller.dart';
import '../models/keranjang_model.dart';
import '../models/kurir_model.dart';
import '../utils/app_state.dart';
import '../utils/url_berkas.dart';
import '../widgets/checkout/checkout_penerima_section.dart';
import '../widgets/checkout_uts/checkout_uts_bottom_bar.dart';
import '../widgets/checkout_uts/checkout_uts_kurir_section.dart';
import '../widgets/checkout_uts/checkout_uts_pembayaran_section.dart';
import '../widgets/checkout_uts/checkout_uts_ringkasan_section.dart';
import 'profil_screen.dart';

class CheckoutUtsScreen extends StatefulWidget {
  final KeranjangDataModel keranjangData;

  const CheckoutUtsScreen({super.key, required this.keranjangData});

  @override
  State<CheckoutUtsScreen> createState() => _CheckoutUtsScreenState();
}

class _CheckoutUtsScreenState extends State<CheckoutUtsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final CheckoutUtsController _c;

  final TextEditingController _namaController = TextEditingController(
    text: AuthController.to.pengguna.value?.nama.isNotEmpty == true
        ? AuthController.to.pengguna.value!.nama
        : 'Ceo Adyatma86',
  );
  final TextEditingController _teleponController = TextEditingController(
    text: '0812-3456-7890',
  );
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _resepController = TextEditingController();

  late final String _idempotencyKey;

  List<KurirModel> get _daftarKurir => _c.daftarKurir;
  KurirModel? get _kurirDipilih => _c.kurirDipilih.value;
  bool get _isMemuatKurir => _c.isMemuatKurir.value;
  String? get _galatKurir => _c.galatKurir.value;
  String get _metodePembayaran => _c.metodePembayaran.value;
  bool get _isSedangCheckout => _c.isSedangCheckout.value;
  InfoGalat? get _galatCheckout => _c.galatCheckout.value;

  @override
  void initState() {
    super.initState();
    _c = Get.put(CheckoutUtsController());
    _idempotencyKey = const Uuid().v4();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _alamatController.dispose();
    _resepController.dispose();
    super.dispose();
  }

  bool get _apakahAdaResep =>
      widget.keranjangData.items.any((item) => item.produk?.perluResep == true);

  int get _ongkir => _c.ongkir;

  int get _totalEstimasi => _c.hitungTotal(widget.keranjangData);

  Future<void> _muatKurir() => _c.muatKurir();

  Future<void> _prosesCheckout() => _c.prosesCheckout(
        context: context,
        formKey: _formKey,
        idempotencyKey: _idempotencyKey,
        nama: _namaController.text,
        telepon: _teleponController.text,
        alamat: _alamatController.text,
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
          title: Row(
            children: [
              const Text(
                'Checkout',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: const Text(
                  'Mode UTS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
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

                // 2. ALAMAT & KURIR TOKO
                CheckoutUtsKurirSection(
                  alamatController: _alamatController,
                  isMemuatKurir: _isMemuatKurir,
                  galatKurir: _galatKurir,
                  onRetryKurir: _muatKurir,
                  daftarKurir: _daftarKurir,
                  kurirDipilih: _kurirDipilih,
                  onPilihKurir: (kurir) => _c.kurirDipilih.value = kurir,
                ),
                const SizedBox(height: 14),

                // 3. METODE PEMBAYARAN
                CheckoutUtsPembayaranSection(
                  metodePembayaran: _metodePembayaran,
                  onMetodeChanged: (val) => _c.metodePembayaran.value = val,
                ),
                const SizedBox(height: 14),

                // 4. RINGKASAN PESANAN
                CheckoutUtsRingkasanSection(
                  keranjangData: widget.keranjangData,
                  ongkir: _ongkir,
                  totalEstimasi: _totalEstimasi,
                ),
              ],
            ),
          ),
        ),

        // Bottom Checkout Bar
        bottomNavigationBar: CheckoutUtsBottomBar(
          totalEstimasi: _totalEstimasi,
          isSedangCheckout: _isSedangCheckout,
          onProsesCheckout: _prosesCheckout,
        ),
      );
    });
  }
}
