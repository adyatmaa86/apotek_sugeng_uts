import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'checkout_card_section.dart';

/// Section 2: Alamat Pengiriman, Deteksi GPS, Peta Interaktif & Dropdown Wilayah.
class CheckoutAlamatSection extends StatelessWidget {
  final bool isMemuatLokasi;
  final VoidCallback? onDapatkanLokasi;
  final LatLng posisiPeta;
  final Set<Marker> markers;
  final ValueChanged<GoogleMapController> onMapCreated;
  final ValueChanged<LatLng> onPetaTap;

  final bool isMemuatProvinsi;
  final List<Map<String, dynamic>> daftarProvinsi;
  final Map<String, dynamic>? provinsiDipilih;
  final ValueChanged<Map<String, dynamic>?> onProvinsiChanged;

  final bool isMemuatKota;
  final List<Map<String, dynamic>> daftarKota;
  final Map<String, dynamic>? kotaDipilih;
  final String? galatKota;
  final VoidCallback? onRetryKota;
  final ValueChanged<Map<String, dynamic>?> onKotaChanged;

  final bool isMemuatKecamatan;
  final List<Map<String, dynamic>> daftarKecamatan;
  final Map<String, dynamic>? kecamatanDipilih;
  final String? galatKecamatan;
  final VoidCallback? onRetryKecamatan;
  final ValueChanged<Map<String, dynamic>?> onKecamatanChanged;

  final bool isMemuatDesa;
  final List<Map<String, dynamic>> daftarDesa;
  final Map<String, dynamic>? desaDipilih;
  final String? galatDesa;
  final VoidCallback? onRetryDesa;
  final ValueChanged<Map<String, dynamic>?> onDesaChanged;

  final TextEditingController alamatDetailController;
  final TextEditingController kodePosController;

  const CheckoutAlamatSection({
    super.key,
    required this.isMemuatLokasi,
    required this.onDapatkanLokasi,
    required this.posisiPeta,
    required this.markers,
    required this.onMapCreated,
    required this.onPetaTap,
    required this.isMemuatProvinsi,
    required this.daftarProvinsi,
    required this.provinsiDipilih,
    required this.onProvinsiChanged,
    required this.isMemuatKota,
    required this.daftarKota,
    required this.kotaDipilih,
    required this.galatKota,
    required this.onRetryKota,
    required this.onKotaChanged,
    required this.isMemuatKecamatan,
    required this.daftarKecamatan,
    required this.kecamatanDipilih,
    required this.galatKecamatan,
    required this.onRetryKecamatan,
    required this.onKecamatanChanged,
    required this.isMemuatDesa,
    required this.daftarDesa,
    required this.desaDipilih,
    required this.galatDesa,
    required this.onRetryDesa,
    required this.onDesaChanged,
    required this.alamatDetailController,
    required this.kodePosController,
  });

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
    final labelBersih = label.replaceAll('*', '').trim();
    final isWajib = label.contains('*');

    final Widget labelWidget = RichText(
      text: TextSpan(
        text: labelBersih,
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        children: isWajib
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]
            : [],
      ),
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    );

    if (isLoading) {
      return InputDecorator(
        decoration: InputDecoration(
          label: labelWidget,
          border: border,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
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
            label: labelWidget,
            border: border,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
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
        label: labelWidget,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        enabled: !isDisabled,
      ),
      hint: Text(
        isDisabled
            ? 'Pilih ${labelBersih.split('/').first.trim()} dulu'
            : 'Pilih...',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: (isDisabled || items.isEmpty)
              ? Colors.grey
              : const Color(0xFF94A3B8),
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

  @override
  Widget build(BuildContext context) {
    return CheckoutCardSection(
      icon: Icons.location_on_outlined,
      title: '2. Alamat Pengiriman',
      subtitle: 'Tentukan lokasi pengantaran obat presisi',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tombol Auto-isi Lokasi
          InkWell(
            onTap: onDapatkanLokasi,
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
                  if (isMemuatLokasi)
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
                    isMemuatLokasi
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
                    target: posisiPeta,
                    zoom: 13,
                  ),
                  onMapCreated: onMapCreated,
                  markers: markers,
                  onTap: onPetaTap,
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
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),

          // Cascading Dropdowns
          _buildDropdownAlamat<Map<String, dynamic>>(
            label: 'Provinsi *',
            isLoading: isMemuatProvinsi,
            items: daftarProvinsi,
            value: provinsiDipilih,
            itemLabel: (item) => item['name'] as String,
            onChanged: onProvinsiChanged,
            validator: (val) => val == null ? 'Pilih provinsi' : null,
          ),
          const SizedBox(height: 10),

          _buildDropdownAlamat<Map<String, dynamic>>(
            label: 'Kota / Kabupaten *',
            isLoading: isMemuatKota,
            items: daftarKota,
            value: kotaDipilih,
            itemLabel: (item) => item['name'] as String,
            enabled: provinsiDipilih != null,
            errorText: galatKota,
            onRetry: onRetryKota,
            onChanged: onKotaChanged,
            validator: (val) => val == null ? 'Pilih kota/kabupaten' : null,
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildDropdownAlamat<Map<String, dynamic>>(
                  label: 'Kecamatan',
                  isLoading: isMemuatKecamatan,
                  items: daftarKecamatan,
                  value: kecamatanDipilih,
                  itemLabel: (item) => item['name'] as String,
                  enabled: kotaDipilih != null,
                  errorText: galatKecamatan,
                  onRetry: onRetryKecamatan,
                  onChanged: onKecamatanChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdownAlamat<Map<String, dynamic>>(
                  label: 'Desa / Kelurahan',
                  isLoading: isMemuatDesa,
                  items: daftarDesa,
                  value: desaDipilih,
                  itemLabel: (item) => item['name'] as String,
                  enabled: kecamatanDipilih != null,
                  errorText: galatDesa,
                  onRetry: onRetryDesa,
                  onChanged: onDesaChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          TextFormField(
            controller: alamatDetailController,
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: buildCheckoutInputDecoration(
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
            controller: kodePosController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 13),
            decoration: buildCheckoutInputDecoration(
              hint: 'Kode Pos (misal: 55224)',
              prefixIcon: Icons.markunread_mailbox_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
