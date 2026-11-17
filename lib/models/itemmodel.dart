import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ItemModel {
  final String itemId;
  final String itemName;
  final String category;
  final String code;
  final String status; 
  final String image;
  final String specification;
  final Timestamp? createdAt;
  //untuk data alat laboratorium

  ItemModel({
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.code,
    required this.status,
    required this.image,
    required this.specification,
    this.createdAt,
    //setiap pembuatan objek Itemmodel mengisi seluruh properti agar data tidak kosong
  });

  final List<ItemModel> dummyItems = [
  ItemModel(
    itemId: '1',
    itemName: 'Oscilloscope Digital',
    category: 'Elektronika',
    code: 'LAB-ELK-001',
    status: 'Available',
    image: 'https://images.unsplash.com/photo-1581092160562-40aa08e78837?w=500',
    specification: '100MHz, 4 Channel, 1GSa/s',
  ),
  ItemModel(
    itemId: '2',
    itemName: 'Mikrotik RouterBoard',
    category: 'Jaringan',
    code: 'LAB-NET-004',
    status: 'Borrowed',
    image: 'https://images.unsplash.com/photo-1544197150-b99a580bb7a8?w=500',
    specification: 'RB750Gr3 Hex 5x Gigabit Ethernet',
  ),
  ItemModel(
    itemId: '3',
    itemName: 'Arduino Uno R3 Kit',
    category: 'Mikrokontroler',
    code: 'LAB-MCU-012',
    status: 'Available',
    image: 'https://images.unsplash.com/photo-1553406830-ef2513450d76?w=500',
    specification: 'ATmega328P + Breadboard & Jumper',
  ),
  ItemModel(
    itemId: '4',
    itemName: 'Solder Station Digital',
    category: 'Elektronika',
    code: 'LAB-ELK-009',
    status: 'Available',
    image: 'https://images.unsplash.com/photo-1581092921461-eab62e97a780?w=500',
    specification: '60W Adjustable Temp 200-480°C',
  ),
  ItemModel(
    itemId: '5',
    itemName: 'Crimping Tool RJ45',
    category: 'Jaringan',
    code: 'LAB-NET-015',
    status: 'Borrowed',
    image: 'https://images.unsplash.com/photo-1586864387967-d02ef85d93e8?w=500',
    specification: 'Heavy Duty Cat5e / Cat6 Tester',
  ),
];


//Mengubah dokumen Firestore menjadi objek ItemModel
factory ItemModel.fromFirestore(DocumentSnapshot doc){
  final data = doc.data() as Map<String, dynamic>;
  return ItemModel(
    itemId: doc.id, 
    itemName: data['item_name'] ?? '', 
    category: data['category'] ?? 'Lainnya', 
    code: data['code'], 
    status: data['status'] ?? 'Available', 
    image: data['image'], 
    specification: data['spesification'] ?? data['spesification'] ?? '-',
    createdAt: data['created_at'] as Timestamp,
    );
} 

//Mengubah objek ItemModel menjadi Map untuk disimpan ke firestore
Map<String, dynamic> toMap(){
  return{
    'item_id': itemId,
    'item_name': itemName,
    'category': Category,
    'code': code,
    'status': status,
    'image': image,
    'spesification': specification,
    'created_at': createdAt ?? FieldValue.serverTimestamp(),
  };
}
}