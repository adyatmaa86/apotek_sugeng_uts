import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apotek_online_uts/models/pesanan_model.dart';
import 'package:apotek_online_uts/utils/app_state.dart';
import 'package:apotek_online_uts/widgets/widget_keadaan.dart';

void main() {
  test('formatRupiah memakai format rupiah tanpa desimal', () {
    expect(formatRupiah(15000).replaceAll('\u00A0', ' '), 'Rp 15.000');
  });

  test('PesananModel membaca data Xendit dan detail pesanan', () {
    final pesanan = PesananModel.fromJson({
      'id': 1,
      'nomor_pesanan': 'APT-TEST-001',
      'pelanggan_id': 'pelanggan_uts_01',
      'nama_penerima': 'Test',
      'alamat': 'Yogyakarta',
      'kurir_id': null,
      'ongkos_kirim': 18000,
      'subtotal': 5000,
      'total': 23000,
      'metode_pembayaran': 'xendit',
      'status': 'menunggu_pembayaran',
      'nomor_resep': null,
      'rajaongkir_service': 'RajaOngkir JNE - REG',
      'xendit_invoice_id': 'INV-1',
      'xendit_payment_url': 'https://checkout.xendit.co/web/1',
      'xendit_status': 'PENDING',
      'created_at': '2026-11-04T10:00:00Z',
      'details': [
        {
          'id': 1,
          'pesanan_id': 1,
          'produk_id': 1,
          'nama_produk': 'Paracetamol',
          'harga_saat_beli': 5000,
          'jumlah': 1,
          'subtotal': 5000,
          'perlu_resep': false,
        },
      ],
    });

    expect(pesanan.total, 23000);
    expect(pesanan.xenditStatus, 'PENDING');
    expect(pesanan.details.single.namaProduk, 'Paracetamol');
  });

  testWidgets('WidgetKeadaan menampilkan pesan kosong', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WidgetKeadaan(keadaan: KeadaanMuat.kosong, child: SizedBox()),
        ),
      ),
    );

    expect(find.text('Belum ada data tersedia.'), findsOneWidget);
  });
}
