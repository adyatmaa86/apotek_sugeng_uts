import 'package:flutter/material.dart';

class KelolaProdukKategoriTabs extends StatelessWidget {
  final List<String> kategoriList;
  final String kategoriDipilih;
  final ValueChanged<String> onSelected;

  const KelolaProdukKategoriTabs({
    super.key,
    required this.kategoriList,
    required this.kategoriDipilih,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: kategoriList.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final kat = kategoriList[index];
          final isSelected = kat == kategoriDipilih;
          return ChoiceChip(
            label: Text(kat),
            selected: isSelected,
            selectedColor: const Color(0xFF005B82),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF005B82)
                  : const Color(0xFFE2E8F0),
            ),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            onSelected: (selected) {
              if (selected) {
                onSelected(kat);
              }
            },
          );
        },
      ),
    );
  }
}
