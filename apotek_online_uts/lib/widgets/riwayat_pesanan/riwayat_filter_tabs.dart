import 'package:flutter/material.dart';

/// Tab filter status pesanan: Semua, Berlangsung, dan Selesai.
class RiwayatFilterTabs extends StatelessWidget {
  final int tabFilter;
  final int totalSemua;
  final int totalBerlangsung;
  final int totalSelesai;
  final ValueChanged<int> onTabSelected;

  const RiwayatFilterTabs({
    super.key,
    required this.tabFilter,
    required this.totalSemua,
    required this.totalBerlangsung,
    required this.totalSelesai,
    required this.onTabSelected,
  });

  Widget _buildChip({
    required int index,
    required String label,
  }) {
    final terpilih = tabFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: terpilih ? const Color(0xFF005B82) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: terpilih
                  ? const Color(0xFF005B82)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: terpilih ? FontWeight.bold : FontWeight.w500,
              color: terpilih ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip(
            index: 0,
            label: 'Semua ($totalSemua)',
          ),
          const SizedBox(width: 8),
          _buildChip(
            index: 1,
            label: 'Berlangsung ($totalBerlangsung)',
          ),
          const SizedBox(width: 8),
          _buildChip(
            index: 2,
            label: 'Selesai ($totalSelesai)',
          ),
        ],
      ),
    );
  }
}
