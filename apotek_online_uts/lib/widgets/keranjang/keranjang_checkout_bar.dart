import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/keranjang_controller.dart';
import '../../utils/format_rupiah.dart';

/// Bar checkout melayang di bagian bawah halaman Keranjang.
class KeranjangCheckoutBar extends StatelessWidget {
  final VoidCallback onCheckout;

  const KeranjangCheckoutBar({
    super.key,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = KeranjangController.to;

    return Container(
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
                    'Subtotal Tagihan',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Obx(
                    () => Text(
                      formatRupiah(ctrl.subtotal),
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: onCheckout,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0369A1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Checkout Pesanan',
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
    );
  }
}
