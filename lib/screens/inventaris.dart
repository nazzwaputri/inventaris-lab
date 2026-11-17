import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InventarisScreen extends StatefulWidget {
  const InventarisScreen({super.key});

  @override
  State<InventarisScreen> createState() => _InventarisScreenState();
}

class _InventarisScreenState extends State<InventarisScreen> {
  final CollectionReference _itemsRef =
      FirebaseFirestore.instance.collection('items'); //untuk menghubungkan apk ke penyimpanan bernama items di database firebase firestore

  // --- FORM TAMBAH / EDIT ALAT ---
  void _showFormDialog({DocumentSnapshot? doc}) { //untuk memunculkan kotak pop-up
    final data = doc?.data() as Map<String, dynamic>?;
    final nameController =
        TextEditingController(text: data?['name'] ?? data?['nama'] ?? '');
    final codeController =
        TextEditingController(text: data?['code'] ?? data?['kode'] ?? '');
    final imageController = TextEditingController(
        text: data?['imageUrl'] ?? data?['gambar'] ?? '');
    String selectedCategory =
        data?['category'] ?? data?['kategori'] ?? 'Mikrokontroler';

    final categories = [
      'Elektronika',
      'Jaringan',
      'Mikrokontroler',
      'Lainnya',
    ];
    if (!categories.contains(selectedCategory)) {
      selectedCategory = 'Mikrokontroler';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(doc == null ? 'Tambah Alat Baru' : 'Edit Data Alat'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Alat',
                    hintText: 'Contoh: Arduino Uno R3',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Kode Alat',
                    hintText: 'Contoh: LAB001',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedCategory = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(
                    labelText: 'URL Gambar (Opsional)',
                    hintText: 'https://...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A7A),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final code = codeController.text.trim();
                final imageUrl = imageController.text.trim();

                if (name.isEmpty || code.isEmpty) return;

                final payload = {
                  'name': name,
                  'code': code,
                  'category': selectedCategory,
                  'imageUrl': imageUrl,
                  'status': data?['status'] ?? 'Available',
                };

                if (doc == null) {
                  await _itemsRef.add(payload);
                } else {
                  await _itemsRef.doc(doc.id).update(payload);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(doc == null
                          ? 'Alat berhasil ditambahkan!'
                          : 'Data alat diperbarui!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  // --- PINJAM ALAT ---
  Future<void> _pinjamAlat(DocumentSnapshot doc) async { 
    //fungsinya ada 2 saat tombol pinjam ditekan
    //mengubah status alat di koleksi tems dari Available menjadi Borrowed
    //mencatat riwayat peminjaman
    final data = doc.data() as Map<String, dynamic>;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_siswa';

    await _itemsRef.doc(doc.id).update({'status': 'Borrowed'});

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('borrowings')
        .add({
      'itemId': doc.id,
      'itemName': data['name'] ?? data['nama'] ?? 'Alat Lab',
      'itemCode': data['code'] ?? data['kode'] ?? '-',
      'status': 'Borrowed',
      'borrowedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil meminjam alat! Cek di tab Profil.'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  // --- HAPUS ALAT ---
  //menghapus 1 dokumen alat secara permanen
  Future<void> _hapusAlat(String docId) async {
    await _itemsRef.doc(docId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alat berhasil dihapus.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Data Inventaris Lab'),
        backgroundColor: const Color(0xFF1A3A7A),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A3A7A),
        foregroundColor: Colors.white,
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _itemsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada data peralatan.\nTekan tombol + di kanan bawah untuk menambah.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            //mengulang desain kartu sebanyak jumlah barang yang ada di database (docs.length)
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? data['nama'] ?? 'Alat Lab';
              final code = data['code'] ?? data['kode'] ?? '-';
              final category = data['category'] ?? data['kategori'] ?? 'Umum';
              final status = data['status'] ?? 'Available';
              final imageUrl =
                  (data['imageUrl'] ?? data['gambar'] ?? '').toString();
              final isAvailable = status == 'Available';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: 65,
                                height: 65,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 65,
                                  height: 65,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.grey),
                                ),
                              )
                            : Container(
                                width: 65,
                                height: 65,
                                color: Colors.grey[200],
                                child: const Icon(Icons.devices,
                                    color: Colors.grey),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$code • $category',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? Colors.green[50]
                                    : Colors.orange[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isAvailable
                                      ? Colors.green[700]
                                      : Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit,
                                    color: Colors.blue, size: 20),
                                onPressed: () => _showFormDialog(doc: doc),
                              ),
                              IconButton(
                                tooltip: 'Hapus',
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 20),
                                onPressed: () => _hapusAlat(doc.id),
                              ),
                            ],
                          ),
                          if (isAvailable)
                            SizedBox(
                              height: 30,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00796B),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                ),
                                onPressed: () => _pinjamAlat(doc),
                                child: const Text('Pinjam',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}