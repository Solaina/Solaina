import 'package:cloud_firestore/cloud_firestore.dart';

class GroceryItem {
  final String id;
  final String name;
  final String addedBy;
  final bool bought;
  final String? boughtBy;
  final DateTime createdAt;

  GroceryItem({
    required this.id,
    required this.name,
    required this.addedBy,
    required this.bought,
    required this.boughtBy,
    required this.createdAt,
  });

  factory GroceryItem.fromMap(String id, Map<String, dynamic> data) {
    return GroceryItem(
      id: id,
      name: data['name'] as String? ?? '',
      addedBy: data['addedBy'] as String? ?? '',
      bought: data['bought'] as bool? ?? false,
      boughtBy: data['boughtBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'addedBy': addedBy,
      'bought': bought,
      'boughtBy': boughtBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
