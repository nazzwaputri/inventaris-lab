import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()), //kembali ke halaman login
        (route) => false,
      );
    }
  }

  Future<void> _kembalikanAlat(
    //1. mengubah status catatan peminjaman di akun
    //2. mengubah status barang aslinya di koleksi utama agar alat tsb muncul kembali sbg barang yg tersedia
    BuildContext context,
    String uid,
    String borrowDocId,
    String? itemId,
  ) async {
    try {
      await FirebaseFirestore.instance // menghubungkan kode ke firestore
      //await untuk memberitahui aplikasi agar menunggu proses pengambilan data ke internet selesai
          .collection('users')
          .doc(uid)
          .collection('borrowings')
          .doc(borrowDocId)
          .update({'status': 'Returned'});

      if (itemId != null && itemId.isNotEmpty) //agar item tidak kosong
       {
        await FirebaseFirestore.instance
            .collection('items')
            .doc(itemId)
            .update({'status': 'Available'});
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alat berhasil dikembalikan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengembalikan alat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Pakai UID user yang login, atau fallback ke 'guest_siswa' agar tidak pernah error null
    final uid = user?.uid ?? 'guest_siswa';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Keluar / Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- KARTU INFORMASI PROFIL ---
            StreamBuilder<DocumentSnapshot>(
              //membaca data dokumen profil dari koleksi user di firestore
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                String nama = user?.displayName ?? 'Nazwa Putri Restyahartanti';
                String email = user?.email ?? 'nazwa@gmail.com';
                String kelas = 'XI RPL 7';

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null) {
                    nama = data['nama'] ?? data['name'] ?? nama;
                    email = data['email'] ?? email;
                    kelas = data['kelas'] ?? data['class'] ?? kelas;
                  }
                }

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: const Color(0xFF1A237E),
                              child: Text(
                                nama.isNotEmpty ? nama[0].toUpperCase() : 'S',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nama,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Kelas: $kelas',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A237E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _logout(context),
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text(
                              'Logout / Ganti Akun',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            const Text(
              'Riwayat Peminjaman Alat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // --- DAFTAR RIWAYAT PEMINJAMAN ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('borrowings')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Gagal memuat riwayat: ${snapshot.error}');
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada riwayat peminjaman alat.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true, //supaya daftar riwayat tidak bentrok dgn halaman utama
                  physics: const NeverScrollableScrollPhysics(), //supaya daftar riwayat tidak bentrok dgn halaman utama
                  itemCount: docs.length, //menentukan berapa kali kartu harus dicetak
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final item = doc.data() as Map<String, dynamic>; //mengambil 1 dokumen sesuai nomor urutny
                    final itemName = item['itemName'] ?? item['namaAlat'] ?? 'Alat Lab';
                    final itemCode = item['itemCode'] ?? item['kodeAlat'] ?? '-';
                    final status = item['status'] ?? 'Borrowed';
                    final itemId = item['itemId']?.toString();
                    final isBorrowed = status == 'Borrowed';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isBorrowed
                              ? Colors.orange[50]
                              : Colors.green[50],
                          child: Icon(
                            isBorrowed ? Icons.pending_actions : Icons.check_circle,
                            color: isBorrowed ? Colors.orange : Colors.green,
                          ),
                        ),
                        title: Text(
                          itemName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Kode: $itemCode • Status: $status'),
                        trailing: isBorrowed
                            ? ElevatedButton(
                                onPressed: () => _kembalikanAlat(
                                  context,
                                  uid,
                                  doc.id,
                                  itemId,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A237E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text(
                                  'Kembalikan',
                                  style: TextStyle(fontSize: 12),
                                ),
                              )
                            : const Text(
                                'Selesai',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}