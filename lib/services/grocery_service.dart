import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/grocery_item.dart';
import 'app_mode.dart';
import 'local_store.dart';

class GroceryService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

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
  }) async {
    if (AppMode.useLocal) {
      await LocalStore.instance.addToCollection('groceryItems', householdId, {
        'name': name,
        'addedBy': addedBy,
        'bought': false,
        'boughtBy': null,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      return;
    }
    await _collection(householdId).add(
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
    if (AppMode.useLocal) {
      return LocalStore.instance.updateInCollection(
        'groceryItems',
        householdId,
        itemId,
        {'bought': bought, 'boughtBy': bought ? boughtBy : null},
      );
    }
    return _collection(householdId).doc(itemId).update({
      'bought': bought,
      'boughtBy': bought ? boughtBy : null,
    });
  }

  Future<void> deleteItem(String householdId, String itemId) {
    if (AppMode.useLocal) {
      return LocalStore.instance.deleteFromCollection(
        'groceryItems',
        householdId,
        itemId,
      );
    }
    return _collection(householdId).doc(itemId).delete();
  }

  Stream<List<GroceryItem>> watchItems(String householdId) {
    if (AppMode.useLocal) {
      return LocalStore.instance
          .watchCollection('groceryItems', householdId)
          .map((items) {
            final groceries = items
                .map(
                  (raw) => GroceryItem.fromMap(
                    raw['id'] as String,
                    LocalStore.withTimestamps(raw, ['createdAt']),
                  ),
                )
                .toList();
            groceries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return groceries;
          });
    }
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
