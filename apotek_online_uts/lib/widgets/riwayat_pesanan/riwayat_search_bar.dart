import 'package:flutter/material.dart';

/// Bar pencarian nomor nota pesanan dan tombol filter rentang tanggal.
class RiwayatSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final DateTimeRange? rentangTanggal;
  final VoidCallback onPilihRentangTanggal;
  final VoidCallback onHapusRentangTanggal;

  const RiwayatSearchBar({
    super.key,
    required this.controller,
    required this.rentangTanggal,
    required this.onPilihRentangTanggal,
    required this.onHapusRentangTanggal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: controller,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Cari nomor nota atau pesanan...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          onPressed: () {
                            controller.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPilihRentangTanggal,
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: rentangTanggal != null
                    ? const Color(0xFFE0F2FE)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: rentangTanggal != null
                      ? const Color(0xFF0284C7)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: rentangTanggal != null
                    ? const Color(0xFF0284C7)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
          if (rentangTanggal != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.clear, size: 18, color: Colors.red),
              onPressed: onHapusRentangTanggal,
            ),
          ],
        ],
      ),
    );
  }
}
