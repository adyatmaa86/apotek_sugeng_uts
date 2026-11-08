import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/keranjang_model.dart';
import '../models/kurir_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../widgets/widget_keadaan.dart';
import 'pesanan_detail_screen.dart';

class CheckoutUtsScreen extends StatefulWidget {
  final KeranjangDataModel keranjangData;

  const CheckoutUtsScreen({super.key, required this.keranjangData});

  @override
  State<CheckoutUtsScreen> createState() => _CheckoutUtsScreenState();
}

class _CheckoutUtsScreenState extends State<CheckoutUtsScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaController = TextEditingController(
    text: 'Ceo Adyatma86',
  );
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _resepController = TextEditingController();

  late final String _idempotencyKey;

  List<KurirModel> _daftarKurir = [];
  KurirModel? _kurirDipilih;
  bool _isMemuatKurir = false;
  String? _galatKurir;

  String _metodePembayaran = 'cod';

  bool _isSedangCheckout = false;
  InfoGalat? _galatCheckout;

  @override
  void initState() {
    super.initState();
    _idempotencyKey = const Uuid().v4();
    _muatKurir();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _resepController.dispose();
    super.dispose();
  }

  bool get _apakahAdaResep =>
      widget.keranjangData.items.any((item) => item.produk?.perluResep == true);

  int get _ongkir => _kurirDipilih?.tarif ?? 0;

  int get _totalEstimasi => widget.keranjangData.subtotal + _ongkir;

  Future<void> _muatKurir() async {
    setState(() {
      _isMemuatKurir = true;
      _galatKurir = null;
    });

    try {
      final kurir = await LayananApi.getKurir();
      if (!mounted) return;
      setState(() => _daftarKurir = kurir);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galatKurir = e is InfoGalat ? e.pesan : e.toString();
      });
    } finally {
      if (mounted) setState(() => _isMemuatKurir = false);
    }
  }

  Future<void> _prosesCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    if (_kurirDipilih == null) {
      setState(
        () => _galatCheckout = InfoGalat(
          jenis: JenisGalat.lainnya,
          pesan: 'Pilih wilayah pengantaran kurir terlebih dahulu.',
        ),
      );
      return;
    }

    setState(() {
      _isSedangCheckout = true;
      _galatCheckout = null;
    });

    try {
      // Ongkir dihitung di server dari tabel kurir internal (bukan dari
      // aplikasi), sesuai ketentuan konsistensi data klien-server.
      final pesanan = await LayananApi.checkout(
        idempotencyKey: _idempotencyKey,
        namaPenerima: _namaController.text,
        alamat: _alamatController.text,
        kurirId: _kurirDipilih!.id,
        metodePembayaran: _metodePembayaran,
        nomorResep: _resepController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan #${pesanan.nomorPesanan} berhasil dibuat!'),
          backgroundColor: Colors.teal,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PesananDetailScreen(pesananId: pesanan.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galatCheckout = e is InfoGalat
            ? e
            : InfoGalat(jenis: JenisGalat.lainnya, pesan: e.toString());
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_galatCheckout!.pesan),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSedangCheckout = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Checkout Pesanan'),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white70),
              ),
              child: const Text(
                'UTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: const Text(
                  'Mode Simulasi UTS — pengiriman memakai kurir internal toko '
                  'dan pembayaran disimulasikan lewat perubahan status pesanan.',
                  style: TextStyle(fontSize: 12, color: Colors.teal),
                ),
              ),
              const SizedBox(height: 16),

              if (_galatCheckout != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _galatCheckout!.pesan,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Data Penerima
              _buildSectionHeader(Icons.person, '1. Data Penerima'),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap Penerima',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _alamatController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alamat Lengkap Antar',
                  hintText: 'Nama jalan, nomor rumah, RT/RW, kelurahan, kota',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Alamat minimal 10 karakter'
                    : null,
              ),
              if (_apakahAdaResep) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _resepController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Resep Dokter (wajib - ada obat keras)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (_apakahAdaResep &&
                          (v == null || v.trim().isEmpty))
                      ? 'Keranjang memuat obat keras, nomor resep wajib diisi'
                      : null,
                ),
              ],

              const Divider(height: 36),

              // 2. Wilayah Pengantaran (kurir internal toko)
              _buildSectionHeader(Icons.local_shipping, '2. Wilayah & Kurir Toko'),
              const SizedBox(height: 4),
              const Text(
                'Tarif diambil dari tabel kurir internal apotek dan dihitung '
                'di server sesuai wilayah yang dipilih.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              if (_isMemuatKurir)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_galatKurir != null)
                GestureDetector(
                  onTap: _muatKurir,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      '$_galatKurir\nKetuk untuk coba lagi.',
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                )
              else if (_daftarKurir.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Text(
                    'Belum ada kurir internal terdaftar. Hubungi admin.',
                    style: TextStyle(color: Colors.orange),
                  ),
                )
              else
                Column(
                  children: _daftarKurir.map(_buildKurirOption).toList(),
                ),

              const Divider(height: 36),

              // 3. Metode Pembayaran (simulasi internal)
              _buildSectionHeader(Icons.payment, '3. Metode Pembayaran'),
              RadioGroup<String>(
                groupValue: _metodePembayaran,
                onChanged: (val) {
                  if (val != null) setState(() => _metodePembayaran = val);
                },
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: 'cod',
                      title: const Text('Bayar Tunai di Tempat (COD)'),
                      subtitle: const Text(
                        'Pembayaran tunai disimulasikan saat obat diterima',
                      ),
                      activeColor: Colors.teal,
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    RadioListTile<String>(
                      value: 'transfer_manual',
                      title: const Text('Transfer Bank Manual'),
                      subtitle: const Text(
                        'Transfer ke rekening Apotek Sugeng lalu tekan tombol '
                        'sudah bayar di rincian pesanan',
                      ),
                      activeColor: Colors.teal,
                    ),
                  ],
                ),
              ),

              const Divider(height: 36),

              // 4. Ringkasan Biaya
              _buildSectionHeader(Icons.receipt_long, '4. Ringkasan Biaya'),
              _buildRowBiaya(
                'Subtotal Produk',
                formatRupiah(widget.keranjangData.subtotal),
              ),
              _buildRowBiaya(
                'Ongkos Kirim (${_kurirDipilih?.nama ?? 'belum dipilih'})',
                formatRupiah(_ongkir),
              ),
              const Divider(),
              _buildRowBiaya(
                'Total Estimasi',
                formatRupiah(_totalEstimasi),
                isBold: true,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSedangCheckout ? null : _prosesCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSedangCheckout
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Buat Pesanan Sekarang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKurirOption(KurirModel kurir) {
    final dipilih = _kurirDipilih?.id == kurir.id;
    return GestureDetector(
      onTap: () => setState(() => _kurirDipilih = kurir),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dipilih ? Colors.teal.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: dipilih ? Colors.teal : Colors.grey.shade300,
            width: dipilih ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              dipilih ? Icons.radio_button_checked : Icons.radio_button_off,
              color: dipilih ? Colors.teal : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kurir.nama,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    kurir.wilayah,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    'Estimasi: ${kurir.estimasi}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatRupiah(kurir.tarif),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowBiaya(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? Colors.teal : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
