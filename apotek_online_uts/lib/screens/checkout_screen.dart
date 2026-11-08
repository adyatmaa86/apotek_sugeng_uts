import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/keranjang_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../utils/url_berkas.dart';
import 'pesanan_detail_screen.dart';
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
    text: SesiAuth.pengguna?.nama.isNotEmpty == true
        ? SesiAuth.pengguna!.nama
        : 'Ceo Adyatma86',
  );
  final TextEditingController _teleponController = TextEditingController(
    text: '0812-3456-7890',
  );
  final TextEditingController _alamatDetailController = TextEditingController();
  final TextEditingController _kodePostalController = TextEditingController();
  final TextEditingController _resepController = TextEditingController();

  late final String _idempotencyKey;

  List<Map<String, dynamic>> _daftarProvinsi = [];
  List<Map<String, dynamic>> _daftarKota = [];
  List<Map<String, dynamic>> _daftarKecamatan = [];
  List<Map<String, dynamic>> _daftarDesa = [];

  Map<String, dynamic>? _provinsiDipilih;
  Map<String, dynamic>? _kotaDipilih;
  Map<String, dynamic>? _kecamatanDipilih;
  Map<String, dynamic>? _desaDipilih;

  bool _isMemuatProvinsi = false;
  bool _isMemuatKota = false;
  bool _isMemuatKecamatan = false;
  bool _isMemuatDesa = false;

  String? _galatKota;
  String? _galatKecamatan;
  String? _galatDesa;

  List<Map<String, dynamic>> _layananRajaOngkir = [];
  Map<String, dynamic>? _layananDipilih;
  int _ongkirRajaOngkir = 0;
  bool _isMemuatTarif = false;

  final Geocoding _geocoding = Geocoding();

  GoogleMapController? _mapController;
  LatLng _posisiPeta = const LatLng(-7.7956, 110.3695);
  Set<Marker> _markers = {};
  bool _isMemuatLokasi = false;

  String _metodePembayaran = 'cod';

  bool _isSedangCheckout = false;
  InfoGalat? _galatCheckout;

  @override
  void initState() {
    super.initState();
    _idempotencyKey = const Uuid().v4();
    _muatProvinsi();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _alamatDetailController.dispose();
    _kodePostalController.dispose();
    _resepController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _setGalatCheckout(String pesan) {
    _galatCheckout = InfoGalat(jenis: JenisGalat.lainnya, pesan: pesan);
  }

  Future<void> _muatProvinsi() async {
    setState(() => _isMemuatProvinsi = true);
    try {
      final data = await LayananApi.getRajaongkirProvinces();
      if (!mounted) return;
      setState(() {
        _daftarProvinsi = data;
        _isMemuatProvinsi = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isMemuatProvinsi = false);
    }
  }

  Future<void> _muatKota(String provId) async {
    setState(() {
      _isMemuatKota = true;
      _galatKota = null;
      _daftarKota = [];
      _kotaDipilih = null;
      _daftarKecamatan = [];
      _kecamatanDipilih = null;
      _daftarDesa = [];
      _desaDipilih = null;
      _layananRajaOngkir = [];
      _layananDipilih = null;
      _ongkirRajaOngkir = 0;
    });

    try {
      final data = await LayananApi.getRajaongkirCitiesByProvince(provId);
      if (!mounted) return;
      setState(() {
        _daftarKota = data;
        _isMemuatKota = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galatKota = 'Gagal memuat kota. Ketuk untuk coba lagi.';
        _isMemuatKota = false;
      });
    }
  }

  Future<void> _muatKecamatan(String kotaId) async {
    setState(() {
      _isMemuatKecamatan = true;
      _galatKecamatan = null;
      _daftarKecamatan = [];
      _kecamatanDipilih = null;
      _daftarDesa = [];
      _desaDipilih = null;
    });

    _hitungOngkir(kotaId);

    try {
      final data = await LayananApi.getRajaongkirDistrictsByCity(kotaId);
      if (!mounted) return;
      setState(() {
        _daftarKecamatan = data;
        _isMemuatKecamatan = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galatKecamatan = 'Gagal memuat kecamatan.';
        _isMemuatKecamatan = false;
      });
    }
  }

  Future<void> _muatDesa(String kecId) async {
    setState(() {
      _isMemuatDesa = true;
      _galatDesa = null;
      _daftarDesa = [];
      _desaDipilih = null;
    });

    try {
      final data = await LayananApi.getRajaongkirVillagesByDistrict(kecId);
      if (!mounted) return;
      setState(() {
        _daftarDesa = data;
        _isMemuatDesa = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galatDesa = 'Gagal memuat kelurahan.';
        _isMemuatDesa = false;
      });
    }
  }

  Future<void> _hitungOngkir(String kotaId) async {
    setState(() => _isMemuatTarif = true);
    try {
      final hasil = await LayananApi.checkRajaongkirCost(
        destinationCityId: kotaId,
      );
      if (!mounted) return;

      List<Map<String, dynamic>> layanan = [];
      for (final kurir in hasil) {
        final costs = kurir['costs'];
        if (costs is List && costs.isNotEmpty) {
          layanan = costs.map((e) => Map<String, dynamic>.from(e)).toList();
          break;
        }
      }

      setState(() {
        _layananRajaOngkir = layanan;
        _layananDipilih = layanan.isNotEmpty ? layanan.first : null;
        _ongkirRajaOngkir = layanan.isNotEmpty
            ? int.tryParse(layanan.first['cost'][0]['value'].toString()) ?? 0
            : 0;
        _isMemuatTarif = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isMemuatTarif = false);
    }
  }

  Future<void> _dapatkanLokasiSaya() async {
    setState(() => _isMemuatLokasi = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin lokasi ditolak. Aktifkan di pengaturan.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izin lokasi diblokir permanen. Buka Settings untuk mengaktifkan.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;

      final latLng = LatLng(pos.latitude, pos.longitude);

      await _reverseGeocode(latLng);

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));

      setState(() {
        _posisiPeta = latLng;
        _markers = {
          Marker(
            markerId: const MarkerId('lokasi_saya'),
            position: latLng,
            infoWindow: const InfoWindow(title: 'Lokasi Saya'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        };
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mendapatkan lokasi: ${e.toString().split(':').first}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isMemuatLokasi = false);
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isEmpty || !mounted) return;

      final pm = placemarks.first;

      if (pm.postalCode != null && pm.postalCode!.isNotEmpty) {
        _kodePostalController.text = pm.postalCode!;
      }

      final jalan = [
        pm.street,
        pm.subLocality,
      ].where((e) => e != null && e.isNotEmpty).join(', ');
      if (jalan.isNotEmpty) {
        _alamatDetailController.text = jalan;
      }

      if (pm.administrativeArea != null && _daftarProvinsi.isNotEmpty) {
        final namaProv = pm.administrativeArea!.toLowerCase();
        final provMatch = _daftarProvinsi.where((p) {
          return (p['name'] as String).toLowerCase().contains(namaProv) ||
              namaProv.contains(
                (p['name'] as String)
                    .toLowerCase()
                    .replaceAll('d.i. ', '')
                    .replaceAll('d.k.i. ', ''),
              );
        }).toList();

        if (provMatch.isNotEmpty && mounted) {
          setState(() => _provinsiDipilih = provMatch.first);
          await _muatKota(provMatch.first['id'].toString());

          if (pm.subAdministrativeArea != null && _daftarKota.isNotEmpty) {
            final namaKota = pm.subAdministrativeArea!.toLowerCase();
            final kotaMatch = _daftarKota.where((k) {
              final kn = (k['name'] as String).toLowerCase();
              return kn.contains(namaKota) ||
                  namaKota.contains(
                    kn.replaceAll('kab. ', '').replaceAll('kota ', ''),
                  );
            }).toList();

            if (kotaMatch.isNotEmpty && mounted) {
              setState(() => _kotaDipilih = kotaMatch.first);
              await _muatKecamatan(kotaMatch.first['id'].toString());

              final namaKec =
                  (pm.locality ?? pm.subLocality ?? '').toLowerCase();
              if (namaKec.isNotEmpty && _daftarKecamatan.isNotEmpty) {
                final kecMatch = _daftarKecamatan.where((k) {
                  final kn = (k['name'] as String).toLowerCase();
                  return kn.contains(namaKec) || namaKec.contains(kn);
                }).toList();

                if (kecMatch.isNotEmpty && mounted) {
                  setState(() => _kecamatanDipilih = kecMatch.first);
                  await _muatDesa(kecMatch.first['id'].toString());

                  final namaDesa =
                      (pm.subLocality ?? pm.thoroughfare ?? '').toLowerCase();
                  if (namaDesa.isNotEmpty && _daftarDesa.isNotEmpty) {
                    final desaMatch = _daftarDesa.where((d) {
                      final dn = (d['name'] as String).toLowerCase();
                      return dn.contains(namaDesa) || namaDesa.contains(dn);
                    }).toList();

                    if (desaMatch.isNotEmpty && mounted) {
                      setState(() => _desaDipilih = desaMatch.first);
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  void _onPetaTap(LatLng pos) {
    setState(() {
      _posisiPeta = pos;
      _markers = {
        Marker(
          markerId: const MarkerId('lokasi_dipilih'),
          position: pos,
          infoWindow: const InfoWindow(title: 'Lokasi Pengiriman'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      };
    });
    _reverseGeocode(pos);
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

  Future<void> _prosesCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    if (_provinsiDipilih == null || _kotaDipilih == null) {
      _setGalatCheckout('Harap pilih provinsi dan kota pengiriman.');
      setState(() {});
      return;
    }

    if (_layananDipilih == null) {
      _setGalatCheckout('Pilih paket pengiriman JNE yang tersedia.');
      setState(() {});
      return;
    }

    setState(() {
      _isSedangCheckout = true;
      _galatCheckout = null;
    });

    try {
      final paket = _layananDipilih?['service'] as String? ?? 'REG';
      final rajaongkirService = paket;

      final pesanan = await LayananApi.checkout(
        idempotencyKey: _idempotencyKey,
        namaPenerima: _namaController.text.trim(),
        alamat: _alamatLengkap,
        metodePembayaran: _metodePembayaran,
        nomorResep: _resepController.text.trim().isEmpty
            ? null
            : _resepController.text.trim(),
        rajaongkirDestination: _kotaDipilih?['id']?.toString(),
        rajaongkirService: rajaongkirService,
        rajaongkirCourier: 'jne',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan #${pesanan.nomorPesanan} berhasil dibuat!'),
          backgroundColor: const Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
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
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSedangCheckout = false);
    }
  }

  String _formatRupiah(num angka) {
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

  @override
  Widget build(BuildContext context) {
    final fotoUrl = UrlBerkas.dari(SesiAuth.pengguna?.fotoUrl);
    final namaPengguna = SesiAuth.pengguna?.nama ?? 'Ceo Adyatma86';

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
                  MaterialPageRoute(builder: (context) => const ProfilScreen()),
                );
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF0284C7),
                backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                    ? NetworkImage(fotoUrl)
                    : null,
                child: fotoUrl == null || fotoUrl.isEmpty
                    ? Text(
                        namaPengguna.isNotEmpty
                            ? namaPengguna.substring(0, 1).toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
              // Stepper / Status Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0284C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Langkah 1 dari 2',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            'Penerima & Pengiriman',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            color: Color(0xFF16A34A),
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Farmasi Resmi',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Banner Galat (jika ada)
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
              _buildCardSection(
                icon: Icons.person_outline,
                title: '1. Informasi Penerima',
                subtitle: 'Pastikan kontak pasien/penerima aktif',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nama Lengkap Penerima *',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _namaController,
                      style: const TextStyle(fontSize: 13),
                      decoration: _buildInputDecoration(
                        hint: 'Nama penerima',
                        prefixIcon: Icons.person_outline,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nomor WhatsApp / Telepon *',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _teleponController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 13),
                      decoration: _buildInputDecoration(
                        hint: '0812-3456-7890',
                        prefixIcon: Icons.phone_outlined,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nomor telepon wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Kurir farmasi akan menghubungi nomor ini saat pengantaran',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nomor Resep Dokter',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                        Text(
                          _apakahAdaResep
                              ? '* Wajib untuk obat keras'
                              : '(Opsional)',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: _apakahAdaResep
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _resepController,
                      style: const TextStyle(fontSize: 13),
                      decoration: _buildInputDecoration(
                        hint: 'Contoh: RSP-YK-2024-8849',
                        prefixIcon: Icons.receipt_long_outlined,
                      ),
                      validator: (v) {
                        if (_apakahAdaResep &&
                            (v == null || v.trim().isEmpty)) {
                          return 'Keranjang memuat obat keras, nomor resep dokter wajib diisi';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. ALAMAT PENGIRIMAN & PETA
              _buildCardSection(
                icon: Icons.location_on_outlined,
                title: '2. Alamat Pengiriman',
                subtitle: 'Tentukan lokasi pengantaran obat presisi',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tombol Auto-isi Lokasi
                    InkWell(
                      onTap: _isMemuatLokasi ? null : _dapatkanLokasiSaya,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isMemuatLokasi)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0284C7),
                                ),
                              )
                            else
                              const Icon(
                                Icons.my_location,
                                color: Color(0xFF0284C7),
                                size: 18,
                              ),
                            const SizedBox(width: 8),
                            Text(
                              _isMemuatLokasi
                                  ? 'Mendeteksi koordinat GPS...'
                                  : 'Gunakan Lokasi Saya (Auto-isi)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Google Map View
                    RepaintBoundary(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 190,
                          child: GoogleMap(
                            gestureRecognizers: {
                              Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer(),
                              ),
                            },
                            initialCameraPosition: CameraPosition(
                              target: _posisiPeta,
                              zoom: 13,
                            ),
                            onMapCreated: (c) => _mapController = c,
                            markers: _markers,
                            onTap: _onPetaTap,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: true,
                            mapType: MapType.normal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ketuk peta untuk memilih lokasi presisi pengiriman',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 14),

                    // Cascading Dropdowns
                    _buildDropdownAlamat<Map<String, dynamic>>(
                      label: 'Provinsi *',
                      isLoading: _isMemuatProvinsi,
                      items: _daftarProvinsi,
                      value: _provinsiDipilih,
                      itemLabel: (item) => item['name'] as String,
                      onChanged: (val) {
                        setState(() => _provinsiDipilih = val);
                        if (val != null) _muatKota(val['id'].toString());
                      },
                      validator: (val) => val == null ? 'Pilih provinsi' : null,
                    ),
                    const SizedBox(height: 10),

                    _buildDropdownAlamat<Map<String, dynamic>>(
                      label: 'Kota / Kabupaten *',
                      isLoading: _isMemuatKota,
                      items: _daftarKota,
                      value: _kotaDipilih,
                      itemLabel: (item) => item['name'] as String,
                      enabled: _provinsiDipilih != null,
                      errorText: _galatKota,
                      onRetry: _provinsiDipilih != null
                          ? () => _muatKota(_provinsiDipilih!['id'].toString())
                          : null,
                      onChanged: (val) {
                        setState(() => _kotaDipilih = val);
                        if (val != null) _muatKecamatan(val['id'].toString());
                      },
                      validator: (val) =>
                          val == null ? 'Pilih kota/kabupaten' : null,
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownAlamat<Map<String, dynamic>>(
                            label: 'Kecamatan',
                            isLoading: _isMemuatKecamatan,
                            items: _daftarKecamatan,
                            value: _kecamatanDipilih,
                            itemLabel: (item) => item['name'] as String,
                            enabled: _kotaDipilih != null,
                            errorText: _galatKecamatan,
                            onRetry: _kotaDipilih != null
                                ? () => _muatKecamatan(
                                      _kotaDipilih!['id'].toString(),
                                    )
                                : null,
                            onChanged: (val) {
                              setState(() => _kecamatanDipilih = val);
                              if (val != null) _muatDesa(val['id'].toString());
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDropdownAlamat<Map<String, dynamic>>(
                            label: 'Desa / Kelurahan',
                            isLoading: _isMemuatDesa,
                            items: _daftarDesa,
                            value: _desaDipilih,
                            itemLabel: (item) => item['name'] as String,
                            enabled: _kecamatanDipilih != null,
                            errorText: _galatDesa,
                            onRetry: _kecamatanDipilih != null
                                ? () => _muatDesa(
                                      _kecamatanDipilih!['id'].toString(),
                                    )
                                : null,
                            onChanged: (val) =>
                                setState(() => _desaDipilih = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _alamatDetailController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: _buildInputDecoration(
                        hint:
                            'Jl. Suroto No. 4, Kotabaru, Gondokusuman (Depan Toko Roti, Pagar Hitam)',
                        prefixIcon: Icons.home_outlined,
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Detail alamat wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _kodePostalController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(fontSize: 13),
                      decoration: _buildInputDecoration(
                        hint: 'Kode Pos (misal: 55224)',
                        prefixIcon: Icons.markunread_mailbox_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. KURIR RAJAONGKIR
              _buildCardSection(
                icon: Icons.local_shipping_outlined,
                title: '3. Kurir & Layanan Pengiriman',
                subtitle: 'Tarif resmi terhubung API RajaOngkir JNE',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_kotaDipilih == null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFF64748B),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pilih kota tujuan pengiriman untuk mengecek ongkir resmi.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_isMemuatTarif)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Menghitung ongkos kirim JNE...',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_layananRajaOngkir.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Text(
                          'Layanan JNE belum menjangkau kota tujuan ini.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<Map<String, dynamic>>(
                        initialValue: _layananDipilih,
                        decoration: _buildInputDecoration(
                          hint: 'Pilih Paket Pengiriman JNE',
                          prefixIcon: Icons.local_shipping_outlined,
                        ),
                        items: _layananRajaOngkir.map((l) {
                          final cost = l['cost'][0]['value'];
                          final etd = l['cost'][0]['etd'];
                          return DropdownMenuItem(
                            value: l,
                            child: Text(
                              '${l['service']} — ${_formatRupiah(cost)} ($etd hari)',
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            _layananDipilih = val;
                            _ongkirRajaOngkir =
                                int.tryParse(
                                  val['cost'][0]['value'].toString(),
                                ) ??
                                0;
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. METODE PEMBAYARAN
              _buildCardSection(
                icon: Icons.payment_outlined,
                title: '4. Metode Pembayaran',
                subtitle: 'Pilih kanal pembayaran yang paling nyaman',
                content: Column(
                  children: [
                    _buildPaymentOption(
                      value: 'cod',
                      title: 'Bayar Tunai di Tempat (COD)',
                      subtitle:
                          'Pembayaran tunai langsung ke kurir saat paket obat sampai.',
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentOption(
                      value: 'transfer_manual',
                      title: 'Transfer Bank Manual',
                      subtitle: 'Transfer rekening ke Bank Apotek Sugeng.',
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentOption(
                      value: 'xendit',
                      title: 'Xendit Payment Gateway (Unggulan)',
                      subtitle:
                          'QRIS, Virtual Account, & E-Wallet terverifikasi otomatis.',
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 5. RINGKASAN PESANAN
              _buildCardSection(
                icon: Icons.receipt_long_outlined,
                title: '5. Ringkasan Pesanan',
                subtitle:
                    '${widget.keranjangData.totalItem} Produk Farmasi Siap Dikirim',
                content: Column(
                  children: [
                    // Box Preview Item
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: widget.keranjangData.items.map((it) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.medication_outlined,
                                  color: Color(0xFF0284C7),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${it.produk?.nama ?? "Obat"} (${it.jumlah} ${it.produk?.satuan ?? "pcs"})',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF334155),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _formatRupiah(
                                    (it.produk?.harga ?? 0) * it.jumlah,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildRowBiaya(
                      'Subtotal Pesanan',
                      _formatRupiah(widget.keranjangData.subtotal),
                    ),
                    const SizedBox(height: 6),
                    _buildRowBiaya(
                      'Biaya Kirim JNE',
                      _formatRupiah(_ongkirRajaOngkir),
                    ),
                    const SizedBox(height: 6),
                    _buildRowBiaya(
                      'Biaya Layanan & Kemasan Higienis',
                      'Gratis',
                      isGreen: true,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Color(0xFFE2E8F0)),
                    ),
                    _buildRowBiaya(
                      'Total Tagihan',
                      _formatRupiah(_hitungPerkiraanTotal),
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Bar Checkout
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Tagihan',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatRupiah(_hitungPerkiraanTotal),
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: _isSedangCheckout ? null : _prosesCheckout,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0369A1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSedangCheckout
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lanjut ke Pembayaran',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF0284C7), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    bool isHighlight = false,
  }) {
    final dipilih = _metodePembayaran == value;
    return InkWell(
      onTap: () => setState(() => _metodePembayaran = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dipilih ? const Color(0xFFF0F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dipilih ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            width: dipilih ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                dipilih ? Icons.radio_button_checked : Icons.radio_button_off,
                color:
                    dipilih ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isHighlight) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ONLINE',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownAlamat<T>({
    required String label,
    required bool isLoading,
    required List<T> items,
    required T? value,
    required String Function(T) itemLabel,
    bool enabled = true,
    void Function(T?)? onChanged,
    String? Function(T?)? validator,
    String? errorText,
    VoidCallback? onRetry,
  }) {
    if (isLoading) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: const SizedBox(
          height: 18,
          child: Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF0284C7),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Memuat data...',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    if (errorText != null && enabled) {
      return GestureDetector(
        onTap: onRetry,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: onRetry != null
                ? const Icon(Icons.refresh, color: Colors.orange, size: 18)
                : null,
          ),
          child: Text(
            errorText,
            style: const TextStyle(color: Colors.orange, fontSize: 11),
          ),
        ),
      );
    }

    final isDisabled = !enabled;
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabled: !isDisabled,
      ),
      hint: Text(
        isDisabled
            ? 'Pilih ${label.split('/').first.trim()} dulu'
            : items.isEmpty
                ? 'Tidak ada data'
                : 'Pilih $label',
        style: TextStyle(
          fontSize: 12,
          color: (isDisabled || items.isEmpty) ? Colors.grey : null,
        ),
      ),
      isExpanded: true,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            itemLabel(item),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
      onChanged: (!isDisabled && items.isNotEmpty) ? onChanged : null,
      validator: validator,
    );
  }

  Widget _buildRowBiaya(
    String label,
    String value, {
    bool isBold = false,
    bool isGreen = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 13 : 11.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isGreen
                ? const Color(0xFF16A34A)
                : isBold
                    ? const Color(0xFF0284C7)
                    : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 18),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
      ),
    );
  }
}
