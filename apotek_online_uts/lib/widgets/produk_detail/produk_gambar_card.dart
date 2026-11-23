import 'package:flutter/material.dart';
import '../../models/produk_model.dart';
import '../../utils/url_berkas.dart';

class ProdukGambarCard extends StatelessWidget {
  final ProdukModel produk;

  const ProdukGambarCard({super.key, required this.produk});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (produk.fotoUrl != null && produk.fotoUrl!.isNotEmpty)
            Image.network(
              UrlBerkas.dari(produk.fotoUrl) ?? '',
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => Icon(
                produk.kategori == 'Obat'
                    ? Icons.medication_liquid_outlined
                    : Icons.medical_services_outlined,
                size: 80,
                color: const Color(0xFF0284C7),
              ),
            )
          else
            Icon(
              produk.kategori == 'Obat'
                  ? Icons.medication_liquid_outlined
                  : Icons.medical_services_outlined,
              size: 80,
              color: const Color(0xFF0284C7),
            ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                produk.kategori,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.verified,
                    size: 13,
                    color: Color(0xFF16A34A),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '100% Asli',
                    style: TextStyle(
                      color: Color(0xFF16A34A),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
