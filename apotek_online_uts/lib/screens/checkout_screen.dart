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
import '../widgets/widget_keadaan.dart';
import 'pesanan_detail_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final KeranjangDataModel keranjangData;

  const CheckoutScreen({super.key, required this.keranjangData});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaController = TextEditingController(
    text: 'Ceo Adyatma86',
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _isMemuatProvinsi = false);
    }
  }

  Future<void> _muatKota(String provinsiId) async {
    setState(() {
      _isMemuatKota = true;
      _galatKota = null;
      _daftarKota = [];
      _daftarKecamatan = [];
      _daftarDesa = [];
      _kotaDipilih = null;
      _kecamatanDipilih = null;
      _desaDipilih = null;
      _layananRajaOngkir = [];
      _layananDipilih = null;
      _ongkirRajaOngkir = 0;
    });
    try {
      final data = await LayananApi.getRajaongkirCitiesByProvince(provinsiId);
      if (!mounted) return;
      setState(() {
        _daftarKota = data;
        _isMemuatKota = false;
        if (data.isEmpty) _galatKota = 'Tidak ada kota untuk provinsi ini.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isMemuatKota = false;
        _galatKota = 'Gagal memuat kota. Ketuk untuk coba lagi.';
      });
    }
  }

  Future<void> _muatKecamatan(String kotaId) async {
    setState(() {
      _isMemuatKecamatan = true;
      _daftarKecamatan = [];
      _daftarDesa = [];
      _kecamatanDipilih = null;
      _desaDipilih = null;
    });
    try {
      final data = await LayananApi.getRajaongkirDistrictsByCity(kotaId);
      if (!mounted) return;
      setState(() {
        _daftarKecamatan = data;
        _isMemuatKecamatan = false;
      });

      await _hitungTarifRajaOngkir(kotaId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isMemuatKecamatan = false;
        _galatKecamatan = 'Gagal memuat kecamatan. Ketuk untuk coba lagi.';
      });
    }
  }

  Future<void> _muatDesa(String kecamatanId) async {
    setState(() {
      _isMemuatDesa = true;
      _daftarDesa = [];
      _desaDipilih = null;
    });
    try {
      final data = await LayananApi.getRajaongkirVillagesByDistrict(
        kecamatanId,
      );
      if (!mounted) return;
      setState(() {
        _daftarDesa = data;
        _isMemuatDesa = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isMemuatDesa = false;
        _galatDesa = 'Gagal memuat desa. Ketuk untuk coba lagi.';
      });
    }
  }

  Future<void> _hitungTarifRajaOngkir(String kotaId) async {
    setState(() {
      _isMemuatTarif = true;
      _layananRajaOngkir = [];
      _layananDipilih = null;
      _ongkirRajaOngkir = 0;
    });
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

              // Auto-isi kecamatan dari locality/subLocality
              final namaKec = (pm.locality ?? pm.subLocality ?? '').toLowerCase();
              if (namaKec.isNotEmpty && _daftarKecamatan.isNotEmpty) {
                final kecMatch = _daftarKecamatan.where((k) {
                  final kn = (k['name'] as String).toLowerCase();
                  return kn.contains(namaKec) || namaKec.contains(kn);
                }).toList();

                if (kecMatch.isNotEmpty && mounted) {
                  setState(() => _kecamatanDipilih = kecMatch.first);
                  await _muatDesa(kecMatch.first['id'].toString());

                  // Auto-isi desa dari thoroughfare/subThoroughfare
                  final namaDesa = (pm.subLocality ?? pm.thoroughfare ?? '').toLowerCase();
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
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
  }

  void _onPetaTap(LatLng latLng) {
    setState(() {
      _posisiPeta = latLng;
      _markers = {
        Marker(
          markerId: const MarkerId('lokasi_saya'),
          position: latLng,
          infoWindow: const InfoWindow(title: 'Lokasi Pengiriman'),
        ),
      };
    });
    _reverseGeocode(latLng);
  }

  bool get _apakahAdaResep =>
      widget.keranjangData.items.any((item) => item.produk?.perluResep == true);

  int get _hitungPerkiraanTotal {
    final subtotal = widget.keranjangData.subtotal;
    return subtotal + _ongkirRajaOngkir;
  }

  String get _alamatLengkap {
    final parts = <String>[];
    if (_alamatDetailController.text.trim().isNotEmpty) {
      parts.add(_alamatDetailController.text.trim());
    }
    if (_desaDipilih != null) {
      parts.add(_desaDipilih!['name'] as String);
    }
    if (_kecamatanDipilih != null) {
      parts.add(_kecamatanDipilih!['name'] as String);
    }
    if (_kotaDipilih != null) {
      parts.add(_kotaDipilih!['name'] as String);
    }
    if (_provinsiDipilih != null) {
      parts.add(_provinsiDipilih!['name'] as String);
    }
    if (_kodePostalController.text.trim().isNotEmpty) {
      parts.add(_kodePostalController.text.trim());
    }
    return parts.join(', ');
  }

  Future<void> _prosesCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    if (_provinsiDipilih == null || _kotaDipilih == null) {
      setState(
        () => _setGalatCheckout(
          'Pilih provinsi dan kota tujuan pengiriman terlebih dahulu.',
        ),
      );
      return;
    }

    if (_layananDipilih == null || _ongkirRajaOngkir <= 0) {
      setState(
        () => _setGalatCheckout(
          'Tarif pengiriman belum tersedia. Tunggu sebentar atau pilih kota lain.',
        ),
      );
      return;
    }

    setState(() {
      _isSedangCheckout = true;
      _galatCheckout = null;
    });

    try {
      final pesanan = await LayananApi.checkout(
        idempotencyKey: _idempotencyKey,
        namaPenerima: _namaController.text,
        alamat: _alamatLengkap,
        kurirId: null,
        metodePembayaran: _metodePembayaran,
        nomorResep: _resepController.text,
        rajaongkirDestination: _kotaDipilih!['id'].toString(),
        rajaongkirService: _layananDipilih!['service'].toString(),
        rajaongkirCourier: 'jne',
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
        title: const Text('Checkout Pesanan'),
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
              if (_galatCheckout != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _galatCheckout!.pesan,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_apakahAdaResep) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pesanan Anda memuat obat keras. Nomor resep dokter wajib diisi.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _buildSectionHeader(Icons.person, '1. Informasi Penerima'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap Penerima *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Nama penerima tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _resepController,
                decoration: InputDecoration(
                  labelText: _apakahAdaResep
                      ? 'Nomor Resep Dokter (Wajib) *'
                      : 'Nomor Resep Dokter (Opsional)',
                  hintText: 'Contoh: RSP-2026/04/88',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description_outlined),
                  errorText:
                      _galatCheckout?.rincianValidasi?['nomor_resep']?.first,
                ),
                validator: (val) {
                  if (_apakahAdaResep && (val == null || val.trim().isEmpty)) {
                    return 'Obat memerlukan resep. Harap cantumkan nomor resep dokter.';
                  }
                  return null;
                },
              ),

              const Divider(height: 36),

              _buildSectionHeader(Icons.location_on, '2. Alamat Pengiriman'),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isMemuatLokasi ? null : _dapatkanLokasiSaya,
                  icon: _isMemuatLokasi
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, color: Colors.teal),
                  label: Text(
                    _isMemuatLokasi
                        ? 'Mendeteksi lokasi...'
                        : '📍 Gunakan Lokasi Saya (Auto-isi)',
                    style: const TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.teal),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              RepaintBoundary(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 200,
                    child: GoogleMap(
                      gestureRecognizers: {
                        Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      },
                      initialCameraPosition: CameraPosition(
                        target: _posisiPeta,
                        zoom: 12,
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
                'Ketuk peta untuk memilih lokasi pengiriman',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 12),

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
                validator: (val) => val == null ? 'Pilih kota/kabupaten' : null,
              ),
              const SizedBox(height: 10),

              _buildDropdownAlamat<Map<String, dynamic>>(
                label: 'Kecamatan',
                isLoading: _isMemuatKecamatan,
                items: _daftarKecamatan,
                value: _kecamatanDipilih,
                itemLabel: (item) => item['name'] as String,
                enabled: _kotaDipilih != null,
                errorText: _galatKecamatan,
                onRetry: _kotaDipilih != null
                    ? () => _muatKecamatan(_kotaDipilih!['id'].toString())
                    : null,
                onChanged: (val) {
                  setState(() => _kecamatanDipilih = val);
                  if (val != null) _muatDesa(val['id'].toString());
                },
              ),
              const SizedBox(height: 10),

              _buildDropdownAlamat<Map<String, dynamic>>(
                label: 'Desa / Kelurahan',
                isLoading: _isMemuatDesa,
                items: _daftarDesa,
                value: _desaDipilih,
                itemLabel: (item) => item['name'] as String,
                enabled: _kecamatanDipilih != null,
                errorText: _galatDesa,
                onRetry: _kecamatanDipilih != null
                    ? () => _muatDesa(_kecamatanDipilih!['id'].toString())
                    : null,
                onChanged: (val) => setState(() => _desaDipilih = val),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _kodePostalController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Kode Pos',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _alamatDetailController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Nama Jalan / Detail Alamat *',
                  hintText: 'Contoh: Jl. Malioboro No. 45, RT 02 RW 03',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Detail alamat wajib diisi'
                    : null,
              ),

              const Divider(height: 36),

              _buildSectionHeader(
                Icons.local_shipping,
                '3. Kurir & Tarif Pengiriman',
              ),
              const SizedBox(height: 10),

              if (_kotaDipilih == null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pilih kota tujuan untuk melihat tarif pengiriman',
                          style: TextStyle(color: Colors.grey),
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
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Menghitung tarif JNE...',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_layananRajaOngkir.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Text(
                    'Tarif tidak tersedia untuk kota ini.',
                    style: TextStyle(color: Colors.orange),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.local_shipping,
                            color: Colors.teal,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'JNE Express (via RajaOngkir API)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<Map<String, dynamic>>(
                        initialValue: _layananDipilih,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Paket Pengiriman',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _layananRajaOngkir.map((l) {
                          final cost = l['cost'][0]['value'];
                          final etd = l['cost'][0]['etd'];
                          return DropdownMenuItem(
                            value: l,
                            child: Text(
                              '${l['service']} — ${formatRupiah(cost)} ($etd hari)',
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

              const Divider(height: 36),

              _buildSectionHeader(Icons.payment, '4. Metode Pembayaran'),
              const SizedBox(height: 4),

              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: RadioGroup<String>(
                  groupValue: _metodePembayaran,
                  onChanged: (val) {
                    if (val != null) setState(() => _metodePembayaran = val);
                  },
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: 'cod',
                        title: const Text('Bayar Tunai di Tempat (COD)'),
                        subtitle: const Text('Pembayaran saat obat diterima'),
                        activeColor: Colors.teal,
                      ),
                      Divider(height: 1, color: Colors.grey.shade200),
                      RadioListTile<String>(
                        value: 'transfer_manual',
                        title: const Text('Transfer Bank Manual'),
                        subtitle: const Text('Transfer ke rekening Apotek Sehat'),
                        activeColor: Colors.teal,
                      ),
                      Divider(height: 1, color: Colors.grey.shade200),
                      RadioListTile<String>(
                        value: 'xendit',
                        title: Row(
                          children: [
                            const Flexible(
                              child: Text(
                                'Xendit Payment Gateway',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'UNGGULAN',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: const Text(
                          'QRIS, Virtual Account, E-Wallet via Xendit',
                        ),
                        activeColor: Colors.indigo,
                      ),
                    ],
                  ),
                ),
              ),

              if (_metodePembayaran == 'xendit') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.indigo, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Setelah checkout, Anda akan mendapatkan link pembayaran Xendit yang bisa dibuka di halaman rincian pesanan.',
                          style: TextStyle(fontSize: 12, color: Colors.indigo),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 36),

              _buildSectionHeader(Icons.receipt_long, '5. Ringkasan Biaya'),
              const SizedBox(height: 8),
              _buildRowBiaya(
                'Subtotal Produk',
                formatRupiah(widget.keranjangData.subtotal),
              ),
              _buildRowBiaya(
                'Ongkos Kirim (JNE)',
                formatRupiah(_ongkirRajaOngkir),
              ),
              const Divider(),
              _buildRowBiaya(
                'Total Estimasi',
                formatRupiah(_hitungPerkiraanTotal),
                isBold: true,
              ),

              const SizedBox(height: 8),
              if (_provinsiDipilih != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Dikirim ke: $_alamatLengkap',
                    style: const TextStyle(fontSize: 12, color: Colors.teal),
                  ),
                ),
              ],
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
                    disabledBackgroundColor: Colors.teal.shade200,
                  ),
                  child: _isSedangCheckout
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Memproses Pesanan...',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
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

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
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
          border: const OutlineInputBorder(),
        ),
        child: const SizedBox(
          height: 20,
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Memuat data...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Tampilkan error + tombol retry jika gagal
    if (errorText != null && enabled) {
      return GestureDetector(
        onTap: onRetry,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
            suffixIcon: onRetry != null
                ? const Icon(Icons.refresh, color: Colors.orange)
                : null,
          ),
          child: Text(
            errorText,
            style: const TextStyle(color: Colors.orange, fontSize: 13),
          ),
        ),
      );
    }

    final isDisabled = !enabled;
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        enabled: !isDisabled,
      ),
      hint: Text(
        isDisabled
            ? 'Pilih ${label.split('/').first.trim()} dulu'
            : items.isEmpty
                ? 'Tidak ada data tersedia'
                : 'Pilih $label',
        style: TextStyle(
          fontSize: 14,
          color: (isDisabled || items.isEmpty) ? Colors.grey : null,
        ),
      ),
      isExpanded: true,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (!isDisabled && items.isNotEmpty) ? onChanged : null,
      validator: validator,
    );
  }

  Widget _buildRowBiaya(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
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
