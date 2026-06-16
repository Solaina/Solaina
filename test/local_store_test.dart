import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solaina/services/local_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('sign up creates a user and signs them in', () async {
    final store = LocalStore.instance;
    await store.init();

    await store.signUp(
      email: 'Alice@Example.com',
      password: 'secret1',
      displayName: 'Alice',
    );

    expect(store.currentUserId, isNotNull);
    final user = await store.watchUser(store.currentUserId!).first;
    expect(user!['email'], 'alice@example.com');
    expect(user['displayName'], 'Alice');
  });

  test('sign up rejects duplicate emails', () async {
    final store = LocalStore.instance;
    await store.init();

    await store.signUp(
      email: 'bob@example.com',
      password: 'secret1',
      displayName: 'Bob',
    );
    await store.signOut();

    expect(
      () => store.signUp(
        email: 'bob@example.com',
        password: 'secret2',
        displayName: 'Bob 2',
      ),
      throwsException,
    );
  });

  test('sign in requires a matching password', () async {
    final store = LocalStore.instance;
    await store.init();

    await store.signUp(
      email: 'carol@example.com',
      password: 'secret1',
      displayName: 'Carol',
    );
    await store.signOut();

    expect(
      () => store.signIn(email: 'carol@example.com', password: 'wrong'),
      throwsException,
    );

    await store.signIn(email: 'carol@example.com', password: 'secret1');
    expect(store.currentUserId, isNotNull);
  });

  test('create and join household share the same id and members', () async {
    final store = LocalStore.instance;
    await store.init();

    final householdId = await store.createHousehold(
      name: 'The Burrow',
      userId: 'user-1',
      displayName: 'Alice',
    );
    final household = await store.watchHousehold(householdId).first;
    final inviteCode = household!['inviteCode'] as String;

    final joinedId = await store.joinHousehold(
      inviteCode: inviteCode,
      userId: 'user-2',
      displayName: 'Bob',
    );

    expect(joinedId, householdId);
    final members = await store.watchMembers(householdId).first;
    expect(members.map((m) => m['id']), containsAll(['user-1', 'user-2']));
  });

  test('collection add/update/delete round-trips through watch', () async {
    final store = LocalStore.instance;
    await store.init();

    final id = await store.addToCollection('groceryItems', 'house-1', {
      'name': 'Milk',
      'bought': false,
    });

    var items = await store.watchCollection('groceryItems', 'house-1').first;
    expect(items.single['name'], 'Milk');

    await store.updateInCollection('groceryItems', 'house-1', id, {
      'bought': true,
    });
    items = await store.watchCollection('groceryItems', 'house-1').first;
    expect(items.single['bought'], true);

    await store.deleteFromCollection('groceryItems', 'house-1', id);
    items = await store.watchCollection('groceryItems', 'house-1').first;
    expect(items, isEmpty);
  });
}
