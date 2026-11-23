import 'package:flutter/material.dart';

/// Header Unit Farmasi statis pada layar Keranjang.
class UnitFarmasiHeader extends StatelessWidget {
  const UnitFarmasiHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.storefront_outlined,
          size: 18,
          color: Color(0xFF0284C7),
        ),
        const SizedBox(width: 6),
        const Text(
          'Apotek Sugeng – Unit Farmasi',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Siap Dikirim',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}
