import 'package:flutter/material.dart';

import '../models/produk_model.dart';
import '../services/layanan_api.dart';
import '../utils/app_state.dart';

class FormProdukScreen extends StatefulWidget {
  final ProdukModel? produk;

  const FormProdukScreen({super.key, this.produk});

  @override
  State<FormProdukScreen> createState() => _FormProdukScreenState();
}

class _FormProdukScreenState extends State<FormProdukScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaController;
  late final TextEditingController _hargaController;
  late final TextEditingController _stokController;
  late final TextEditingController _batasController;
  late final TextEditingController _satuanController;
  late final TextEditingController _deskripsiController;

  late String _kategori;
  late bool _perluResep;
  late bool _tersedia;

  bool _sedangMenyimpan = false;

  bool get _isEdit => widget.produk != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produk;
    _namaController = TextEditingController(text: p?.nama ?? '');
    _hargaController = TextEditingController(
      text: p != null ? '${p.harga}' : '',
    );
    _stokController = TextEditingController(
      text: p != null ? '${p.stok}' : '10',
    );
    _batasController = TextEditingController(
      text: p != null ? '${p.batasPerPembelian}' : '5',
    );
    _satuanController = TextEditingController(
      text: p?.satuan ?? 'Strip (10 Tablet)',
    );
    _deskripsiController = TextEditingController(text: p?.deskripsi ?? '');

    _kategori = p?.kategori ?? 'Obat';
    _perluResep = p?.perluResep ?? false;
    _tersedia = p?.tersedia ?? true;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    _batasController.dispose();
    _satuanController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sedangMenyimpan = true);

    final body = {
      'nama': _namaController.text.trim(),
      'harga': int.tryParse(_hargaController.text.trim()) ?? 0,
      'kategori': _kategori,
      'stok': int.tryParse(_stokController.text.trim()) ?? 0,
      'batas_per_pembelian': int.tryParse(_batasController.text.trim()) ?? 1,
      'satuan': _satuanController.text.trim(),
      'deskripsi': _deskripsiController.text.trim(),
      'perlu_resep': _perluResep,
      'tersedia': _tersedia,
    };

    try {
      if (_isEdit) {
        await LayananApi.updateProduk(widget.produk!.id, body);
      } else {
        await LayananApi.tambahProduk(body);
      }

      if (!mounted) return;
      // Kembali dengan hasil berhasil
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sedangMenyimpan = false);
      final pesan = e is InfoGalat ? e.pesan : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesan),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _batal() {
    // Kembali dengan hasil batal
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Ubah Produk Obat / Alkes' : 'Tambah Produk Baru';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Batal',
            onPressed: _batal,
          ),
          actions: [
            TextButton(
              onPressed: _sedangMenyimpan ? null : _batal,
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Produk *',
                    hintText: 'Contoh: Paracetamol 500mg',
                    prefixIcon: Icon(Icons.medication),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nama produk wajib diisi' : null,
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  initialValue: _kategori,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Produk *',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Obat', child: Text('Obat')),
                    DropdownMenuItem(
                      value: 'Alat Kesehatan',
                      child: Text('Alat Kesehatan'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _kategori = val);
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _hargaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga (Rupiah bulat) *',
                    hintText: 'Contoh: 15000',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Harga harus lebih besar dari 0';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stokController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah Stok *',
                          hintText: '0',
                          prefixIcon: Icon(Icons.inventory),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 0) return 'Stok tidak boleh negatif';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _batasController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Batas Beli *',
                          hintText: '5',
                          prefixIcon: Icon(Icons.production_quantity_limits),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1) return 'Minimal 1';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _satuanController,
                  decoration: const InputDecoration(
                    labelText: 'Satuan',
                    hintText: 'Strip, Botol, Tablet, Pcs, Box',
                    prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _deskripsiController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Produk',
                    hintText: 'Keterangan manfaat, komposisi, atau aturan pakai...',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'Perlu Resep Dokter',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Tandai jika obat termasuk golongan obat keras',
                        ),
                        value: _perluResep,
                        activeThumbColor: Colors.teal,
                        onChanged: (val) => setState(() => _perluResep = val),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text(
                          'Produk Aktif / Tersedia',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Jika dinonaktifkan, produk tampil sebagai tidak tersedia',
                        ),
                        value: _tersedia,
                        activeThumbColor: Colors.teal,
                        onChanged: (val) => setState(() => _tersedia = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _sedangMenyimpan ? null : _batal,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _sedangMenyimpan ? null : _simpan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: _sedangMenyimpan
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _sedangMenyimpan
                              ? 'Menyimpan...'
                              : (_isEdit ? 'Simpan Perubahan' : 'Tambah Produk'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

