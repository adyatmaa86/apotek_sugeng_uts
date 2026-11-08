import 'package:flutter/material.dart';

import '../models/produk_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';
import '../widgets/widget_keadaan.dart';
import 'keranjang_screen.dart';

class ProdukDetailScreen extends StatefulWidget {
  final int produkId;

  const ProdukDetailScreen({super.key, required this.produkId});

  @override
  State<ProdukDetailScreen> createState() => _ProdukDetailScreenState();
}

class _ProdukDetailScreenState extends State<ProdukDetailScreen> {
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  InfoGalat? _galat;
  ProdukModel? _produk;

  int _jumlah = 1;
  bool _sedangMenambah = false;

  @override
  void initState() {
    super.initState();
    _muatDetail();
  }

  Future<void> _muatDetail() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _galat = null;
    });

    try {
      final p = await LayananApi.getProdukDetail(widget.produkId);
      if (!mounted) return;

      setState(() {
        _produk = p;
        _keadaan = KeadaanMuat.berhasil;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _galat = e is InfoGalat
            ? e
            : InfoGalat(jenis: JenisGalat.lainnya, pesan: e.toString());
        _keadaan = KeadaanMuat.galat;
      });
    }
  }

  Future<void> _tambahKeKeranjang() async {
    if (_produk == null) return;

    setState(() => _sedangMenambah = true);

    try {
      await LayananApi.tambahKeranjang(_produk!.id, _jumlah);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$_jumlah ${_produk!.satuan} berhasil ditambahkan ke keranjang',
          ),
          backgroundColor: Colors.teal,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const KeranjangScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      final pesan = e is InfoGalat ? e.pesan : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesan), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _sedangMenambah = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: WidgetKeadaan(
        keadaan: _keadaan,
        galat: _galat,
        onCobaLagi: _muatDetail,
        child: _produk == null
            ? const SizedBox()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child:
                            _produk!.fotoUrl != null &&
                                _produk!.fotoUrl!.isNotEmpty
                            ? Image.network(
                                _produk!.fotoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Icon(
                                  _produk!.kategori == 'Obat'
                                      ? Icons.medication_liquid_outlined
                                      : Icons.medical_services_outlined,
                                  size: 80,
                                  color: Colors.teal,
                                ),
                              )
                            : Icon(
                                _produk!.kategori == 'Obat'
                                    ? Icons.medication_liquid_outlined
                                    : Icons.medical_services_outlined,
                                size: 80,
                                color: Colors.teal,
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Chip(
                          label: Text(_produk!.kategori),
                          backgroundColor: Colors.teal.shade100,
                          labelStyle: TextStyle(
                            color: Colors.teal.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_produk!.perluResep)
                          const Chip(
                            avatar: Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text('Perlu Resep Dokter'),
                            backgroundColor: Colors.redAccent,
                            labelStyle: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      _produk!.nama,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      formatRupiah(_produk!.harga),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    const Divider(height: 32),

                    const Text(
                      'Informasi Produk & Obat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRowDetail('Satuan Kemasan', _produk!.satuan),
                    _buildRowDetail('Stok Tersedia', '${_produk!.stok}'),
                    _buildRowDetail(
                      'Batas Maks. Beli',
                      '${_produk!.batasPerPembelian} item / transaksi',
                    ),
                    if (_produk!.golongan != null)
                      _buildRowDetail('Golongan Obat', _produk!.golongan!),

                    const Divider(height: 32),

                    const Text(
                      'Deskripsi & Aturan Pakai',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _produk!.deskripsi ??
                          'Tidak ada deskripsi rinci untuk produk ini.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
      bottomNavigationBar:
          _produk == null || !_produk!.tersedia || _produk!.stok <= 0
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade200,
              child: const Text(
                'Produk saat ini sedang habis atau tidak tersedia untuk dibeli.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 20),
                          onPressed: _jumlah > 1
                              ? () => setState(() => _jumlah--)
                              : null,
                        ),
                        Text(
                          '$_jumlah',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          onPressed:
                              _jumlah < _produk!.stok &&
                                  _jumlah < _produk!.batasPerPembelian
                              ? () => setState(() => _jumlah++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _sedangMenambah ? null : _tambahKeKeranjang,
                      icon: _sedangMenambah
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.shopping_cart_outlined),
                      label: Text(
                        _sedangMenambah
                            ? 'Menambahkan...'
                            : 'Tambah ke Keranjang',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRowDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
