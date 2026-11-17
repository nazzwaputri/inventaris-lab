import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/itemmodel.dart';

class detailScreen extends StatefulWidget {
  final ItemModel item;

  const detailScreen({super.key, required this.item});

  @override
  State<detailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<detailScreen> {
  bool _isSubmitting = false;

  Future<void> _ajukanPinjam() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final firestore = FirebaseFirestore.instance;
      // Buat referensi dokumen baru di sub-koleksi users/{uid}/borrowings
      final borrowDoc = firestore
          .collection('users')
          .doc(user.uid)
          .collection('borrowings')
          .doc();

      // 1. Simpan data peminjaman sesuai skema soal
      await borrowDoc.set({
        'borrow_id': borrowDoc.id,
        'item_id': widget.item.itemId,
        'item_name': widget.item.itemName,
        'borrow_date': FieldValue.serverTimestamp(),
      });

      // 2. Update status alat di koleksi items menjadi 'Borrowed'
      await firestore
          .collection('items')
          .doc(widget.item.itemId)
          .update({'status': 'Borrowed'});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan pinjam berhasil dicatat!'),
          backgroundColor: Color(0xFF0D9488),
        ),
      );
      Navigator.pop(context); // Kembali ke halaman sebelumnya
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal meminjam alat: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = widget.item.status == 'Available';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Alat Lab'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gambar Alat
            Image.network(
              widget.item.image,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 240,
                color: Colors.grey.shade200,
                child: const Icon(Icons.inventory_2_outlined,
                    size: 64, color: Colors.grey),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori & Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.item.category,
                          style: const TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.item.status,
                          style: TextStyle(
                            color: isAvailable
                                ? Colors.green.shade700
                                : Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nama Alat
                  Text(
                    widget.item.itemName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Kode Serial
                  Row(
                    children: [
                      const Icon(Icons.qr_code, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Kode Serial: ${widget.item.code}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Spesifikasi Alat
                  const Text(
                    'Spesifikasi Alat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      widget.item.specification,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Tombol Pengajuan Pinjam di bagian bawah
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: (isAvailable && !_isSubmitting) ? _ajukanPinjam : null,
            icon: const Icon(Icons.assignment_turned_in_outlined),
            label: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    isAvailable
                        ? 'AJUKAN PINJAM ALAT'
                        : 'SEDANG DIPINJAM (BORROWED)',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade400,
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}