import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../screens/pesanan_detail_screen.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';

/// GetX Controller untuk Checkout Reguler dengan RajaOngkir & Google Maps.
class CheckoutController extends GetxController {
  final RxList<Map<String, dynamic>> daftarProvinsi = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> daftarKota = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> daftarKecamatan = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> daftarDesa = <Map<String, dynamic>>[].obs;

  final Rx<Map<String, dynamic>?> provinsiDipilih = Rx<Map<String, dynamic>?>(null);
  final Rx<Map<String, dynamic>?> kotaDipilih = Rx<Map<String, dynamic>?>(null);
  final Rx<Map<String, dynamic>?> kecamatanDipilih = Rx<Map<String, dynamic>?>(null);
  final Rx<Map<String, dynamic>?> desaDipilih = Rx<Map<String, dynamic>?>(null);

  final RxBool isMemuatProvinsi = false.obs;
  final RxBool isMemuatKota = false.obs;
  final RxBool isMemuatKecamatan = false.obs;
  final RxBool isMemuatDesa = false.obs;

  final Rx<String?> galatKota = Rx<String?>(null);
  final Rx<String?> galatKecamatan = Rx<String?>(null);
  final Rx<String?> galatDesa = Rx<String?>(null);

  final RxList<Map<String, dynamic>> layananRajaOngkir = <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>?> layananDipilih = Rx<Map<String, dynamic>?>(null);
  final RxInt ongkirRajaOngkir = 0.obs;
  final RxBool isMemuatTarif = false.obs;

  final Rx<LatLng> posisiPeta = const LatLng(-7.7956, 110.3695).obs;
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxBool isMemuatLokasi = false.obs;

  final Rx<File?> fotoResep = Rx<File?>(null);
  final RxString metodePembayaran = 'cod'.obs;

  final RxBool isSedangCheckout = false.obs;
  final Rx<InfoGalat?> galatCheckout = Rx<InfoGalat?>(null);

  final Geocoding _geocoding = Geocoding();
  GoogleMapController? mapController;

  @override
  void onInit() {
    super.onInit();
    muatProvinsi();
  }

  @override
  void onClose() {
    mapController?.dispose();
    super.onClose();
  }

  void setGalatCheckout(String pesan) {
    galatCheckout.value = InfoGalat(jenis: JenisGalat.lainnya, pesan: pesan);
  }

  Future<void> muatProvinsi() async {
    isMemuatProvinsi.value = true;
    try {
      final data = await LayananApi.getRajaongkirProvinces();
      daftarProvinsi.assignAll(data);
    } catch (e) {
      debugPrint('Gagal memuat provinsi RajaOngkir: $e');
    } finally {
      isMemuatProvinsi.value = false;
    }
  }

  Future<void> muatKota(String provId) async {
    isMemuatKota.value = true;
    galatKota.value = null;
    daftarKota.clear();
    kotaDipilih.value = null;
    daftarKecamatan.clear();
    kecamatanDipilih.value = null;
    daftarDesa.clear();
    desaDipilih.value = null;
    layananRajaOngkir.clear();
    layananDipilih.value = null;
    ongkirRajaOngkir.value = 0;

    try {
      final data = await LayananApi.getRajaongkirCitiesByProvince(provId);
      daftarKota.assignAll(data);
    } catch (e) {
      galatKota.value = 'Gagal memuat kota. Ketuk untuk coba lagi.';
    } finally {
      isMemuatKota.value = false;
    }
  }

  Future<void> muatKecamatan(String kotaId) async {
    isMemuatKecamatan.value = true;
    galatKecamatan.value = null;
    daftarKecamatan.clear();
    kecamatanDipilih.value = null;
    daftarDesa.clear();
    desaDipilih.value = null;

    hitungOngkir(kotaId);

    try {
      final data = await LayananApi.getRajaongkirDistrictsByCity(kotaId);
      daftarKecamatan.assignAll(data);
    } catch (e) {
      galatKecamatan.value = 'Gagal memuat kecamatan.';
    } finally {
      isMemuatKecamatan.value = false;
    }
  }

  Future<void> muatDesa(String kecId) async {
    isMemuatDesa.value = true;
    galatDesa.value = null;
    daftarDesa.clear();
    desaDipilih.value = null;

    try {
      final data = await LayananApi.getRajaongkirVillagesByDistrict(kecId);
      daftarDesa.assignAll(data);
    } catch (e) {
      galatDesa.value = 'Gagal memuat kelurahan.';
    } finally {
      isMemuatDesa.value = false;
    }
  }

  Future<void> hitungOngkir(String kotaId) async {
    isMemuatTarif.value = true;
    try {
      final hasil = await LayananApi.checkRajaongkirCost(
        destinationCityId: kotaId,
      );

      List<Map<String, dynamic>> layanan = [];
      for (final kurir in hasil) {
        final costs = kurir['costs'];
        if (costs is List && costs.isNotEmpty) {
          layanan = costs.map((e) => Map<String, dynamic>.from(e)).toList();
          break;
        }
      }

      layananRajaOngkir.assignAll(layanan);
      if (layanan.isNotEmpty) {
        pilihLayanan(layanan.first);
      } else {
        layananDipilih.value = null;
        ongkirRajaOngkir.value = 0;
      }
    } catch (e) {
      debugPrint('Gagal menghitung tarif RajaOngkir: $e');
      layananRajaOngkir.clear();
      layananDipilih.value = null;
      ongkirRajaOngkir.value = 0;
    } finally {
      isMemuatTarif.value = false;
    }
  }

  void pilihLayanan(Map<String, dynamic> layanan) {
    layananDipilih.value = layanan;
    final costList = layanan['cost'] as List<dynamic>?;
    if (costList != null && costList.isNotEmpty) {
      ongkirRajaOngkir.value = (costList[0]['value'] as num).toInt();
    } else {
      ongkirRajaOngkir.value = 0;
    }
  }

  Future<void> dapatkanLokasiSaya({
    required BuildContext context,
    required TextEditingController kodePosController,
    required TextEditingController alamatDetailController,
  }) async {
    isMemuatLokasi.value = true;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!context.mounted) return;
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
        if (!context.mounted) return;
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

      final latLng = LatLng(pos.latitude, pos.longitude);

      await reverseGeocode(
        latLng: latLng,
        kodePosController: kodePosController,
        alamatDetailController: alamatDetailController,
      );

      mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));

      posisiPeta.value = latLng;
      markers.assignAll({
        Marker(
          markerId: const MarkerId('lokasi_saya'),
          position: latLng,
          infoWindow: const InfoWindow(title: 'Lokasi Saya'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mendapatkan lokasi: ${e.toString().split(':').first}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      isMemuatLokasi.value = false;
    }
  }

  Future<void> reverseGeocode({
    required LatLng latLng,
    required TextEditingController kodePosController,
    required TextEditingController alamatDetailController,
  }) async {
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isEmpty) return;

      final pm = placemarks.first;

      if (pm.postalCode != null && pm.postalCode!.isNotEmpty) {
        kodePosController.text = pm.postalCode!;
      }

      final jalan = [
        pm.street,
        pm.subLocality,
      ].where((e) => e != null && e.isNotEmpty).join(', ');
      if (jalan.isNotEmpty) {
        alamatDetailController.text = jalan;
      }

      if (pm.administrativeArea != null && daftarProvinsi.isNotEmpty) {
        final namaProv = pm.administrativeArea!.toLowerCase();
        final provMatch = daftarProvinsi.where((p) {
          return (p['name'] as String).toLowerCase().contains(namaProv) ||
              namaProv.contains(
                (p['name'] as String)
                    .toLowerCase()
                    .replaceAll('d.i. ', '')
                    .replaceAll('d.k.i. ', ''),
              );
        }).toList();

        if (provMatch.isNotEmpty) {
          provinsiDipilih.value = provMatch.first;
          await muatKota(provMatch.first['id'].toString());

          if (pm.subAdministrativeArea != null && daftarKota.isNotEmpty) {
            final namaKota = pm.subAdministrativeArea!.toLowerCase();
            final kotaMatch = daftarKota.where((k) {
              final kn = (k['name'] as String).toLowerCase();
              return kn.contains(namaKota) ||
                  namaKota.contains(
                    kn.replaceAll('kab. ', '').replaceAll('kota ', ''),
                  );
            }).toList();

            if (kotaMatch.isNotEmpty) {
              kotaDipilih.value = kotaMatch.first;
              await muatKecamatan(kotaMatch.first['id'].toString());

              final namaKec =
                  (pm.locality ?? pm.subLocality ?? '').toLowerCase();
              if (namaKec.isNotEmpty && daftarKecamatan.isNotEmpty) {
                final kecMatch = daftarKecamatan.where((k) {
                  final kn = (k['name'] as String).toLowerCase();
                  return kn.contains(namaKec) || namaKec.contains(kn);
                }).toList();

                if (kecMatch.isNotEmpty) {
                  kecamatanDipilih.value = kecMatch.first;
                  await muatDesa(kecMatch.first['id'].toString());

                  final namaDesa =
                      (pm.subLocality ?? pm.thoroughfare ?? '').toLowerCase();
                  if (namaDesa.isNotEmpty && daftarDesa.isNotEmpty) {
                    final desaMatch = daftarDesa.where((d) {
                      final dn = (d['name'] as String).toLowerCase();
                      return dn.contains(namaDesa) || namaDesa.contains(dn);
                    }).toList();

                    if (desaMatch.isNotEmpty) {
                      desaDipilih.value = desaMatch.first;
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Gagal reverse geocoding lokasi peta: $e');
    }
  }

  void onPetaTap(
    LatLng pos, {
    required TextEditingController kodePosController,
    required TextEditingController alamatDetailController,
  }) {
    posisiPeta.value = pos;
    markers.assignAll({
      Marker(
        markerId: const MarkerId('lokasi_dipilih'),
        position: pos,
        infoWindow: const InfoWindow(title: 'Lokasi Pengiriman'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
      ),
    });
    reverseGeocode(
      latLng: pos,
      kodePosController: kodePosController,
      alamatDetailController: alamatDetailController,
    );
  }

  Future<void> pilihFotoResep(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      fotoResep.value = File(picked.path);
    }
  }

  void hapusFotoResep() {
    fotoResep.value = null;
  }

  Future<void> prosesCheckout({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required String idempotencyKey,
    required String nama,
    required String alamatLengkap,
    required String nomorResep,
  }) async {
    if (!formKey.currentState!.validate()) return;

    if (provinsiDipilih.value == null || kotaDipilih.value == null) {
      setGalatCheckout('Harap pilih provinsi dan kota pengiriman.');
      return;
    }

    if (layananDipilih.value == null) {
      setGalatCheckout('Pilih paket pengiriman JNE yang tersedia.');
      return;
    }

    isSedangCheckout.value = true;
    galatCheckout.value = null;

    try {
      final paket = layananDipilih.value?['service'] as String? ?? 'REG';

      final pesanan = await LayananApi.checkout(
        idempotencyKey: idempotencyKey,
        namaPenerima: nama.trim(),
        alamat: alamatLengkap,
        metodePembayaran: metodePembayaran.value,
        nomorResep: nomorResep.trim().isEmpty ? null : nomorResep.trim(),
        fotoResep: fotoResep.value,
        rajaongkirDestination: kotaDipilih.value?['id']?.toString(),
        rajaongkirService: paket,
        rajaongkirCourier: 'jne',
      );

      if (!context.mounted) return;

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
      galatCheckout.value = e is InfoGalat
          ? e
          : InfoGalat(jenis: JenisGalat.lainnya, pesan: e.toString());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(galatCheckout.value!.pesan),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      isSedangCheckout.value = false;
    }
  }
}
