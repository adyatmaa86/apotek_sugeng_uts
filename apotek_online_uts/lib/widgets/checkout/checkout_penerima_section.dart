import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'checkout_card_section.dart';

/// Section 1: Informasi Kontak & Identitas Pasien/Penerima serta Resep.
class CheckoutPenerimaSection extends StatelessWidget {
  final TextEditingController namaController;
  final TextEditingController teleponController;
  final TextEditingController resepController;
  final File? fotoResep;
  final bool apakahAdaResep;
  final ValueChanged<ImageSource> onPilihFoto;
  final VoidCallback onHapusFoto;

  const CheckoutPenerimaSection({
    super.key,
    required this.namaController,
    required this.teleponController,
    required this.resepController,
    required this.fotoResep,
    required this.apakahAdaResep,
    required this.onPilihFoto,
    required this.onHapusFoto,
  });

  void _tampilkanModalUploadFoto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upload Foto Resep Dokter',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFF0284C7),
              ),
              title: const Text('Ambil Foto dari Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                onPilihFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: Color(0xFF0284C7),
              ),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                onPilihFoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CheckoutCardSection(
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
            controller: namaController,
            style: const TextStyle(fontSize: 13),
            decoration: buildCheckoutInputDecoration(
              hint: 'Nama penerima',
              prefixIcon: Icons.person_outline,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
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
            controller: teleponController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 13),
            decoration: buildCheckoutInputDecoration(
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
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
            ),
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
                apakahAdaResep ? '* Wajib untuk obat keras' : '(Opsional)',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: apakahAdaResep
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF0284C7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: resepController,
            style: const TextStyle(fontSize: 13),
            decoration: buildCheckoutInputDecoration(
              hint: 'Contoh: RSP-YK-2024-8849',
              prefixIcon: Icons.receipt_long_outlined,
            ),
            validator: (v) {
              if (apakahAdaResep && (v == null || v.trim().isEmpty)) {
                return 'Perlu Resep Dokter';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Foto Resep Dokter',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const Text(
                '(Opsional)',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0284C7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _tampilkanModalUploadFoto(context),
            child: Container(
              width: double.infinity,
              height: fotoResep != null ? 180 : 90,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: fotoResep != null
                      ? const Color(0xFF0284C7)
                      : const Color(0xFFCBD5E1),
                  width: fotoResep != null ? 1.5 : 1,
                ),
              ),
              child: fotoResep != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.file(
                            fotoResep!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: onHapusFoto,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Color(0xFF94A3B8),
                          size: 28,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Ketuk untuk upload foto resep',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Foto resep membantu apoteker memverifikasi obat Anda',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
