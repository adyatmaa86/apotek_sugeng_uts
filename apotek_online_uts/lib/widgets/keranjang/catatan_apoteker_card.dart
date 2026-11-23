import 'package:flutter/material.dart';

/// Catatan Resep Dokter untuk Apoteker (statis — zero re-renders).
class CatatanApotekerCard extends StatelessWidget {
  const CatatanApotekerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.edit_note_rounded,
            color: Color(0xFF0284C7),
            size: 22,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan Resep untuk Apoteker',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Nomor resep dokter dapat diisikan pada tahap checkout.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
