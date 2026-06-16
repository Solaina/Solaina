import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/grocery_item.dart';

class GroceryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String householdId) {
    return _db
        .collection('households')
        .doc(householdId)
        .collection('groceryItems');
  }

  Future<void> addItem({
    required String householdId,
    required String name,
    required String addedBy,
  }) {
    return _collection(householdId).add(
      GroceryItem(
        id: '',
        name: name,
        addedBy: addedBy,
        bought: false,
        boughtBy: null,
        createdAt: DateTime.now(),
      ).toMap(),
    );
  }

  Future<void> setBought(
    String householdId,
    String itemId,
    bool bought,
    String? boughtBy,
  ) {
    return _collection(householdId).doc(itemId).update({
      'bought': bought,
      'boughtBy': bought ? boughtBy : null,
    });
  }

  Future<void> deleteItem(String householdId, String itemId) {
    return _collection(householdId).doc(itemId).delete();
  }

  Stream<List<GroceryItem>> watchItems(String householdId) {
    return _collection(householdId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => GroceryItem.fromMap(d.id, d.data()))
              .toList(),
        );
  }
}
