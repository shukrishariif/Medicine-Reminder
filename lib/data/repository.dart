import 'package:sembast/sembast.dart';
import 'models.dart';

class LocalRepository {
  final Database db;
  final records = stringMapStoreFactory.store('records');
  final preferences = stringMapStoreFactory.store('preferences');
  LocalRepository(this.db);
  Future<List<Json>> all(String owner) async => (await records.find(
    db,
    finder: Finder(filter: Filter.equals('owner', owner)),
  )).map((r) => r.value).toList();
  Future<Json> settings() async => Map<String, dynamic>.from(
    await preferences.record('device').get(db) ?? {},
  );
  Future<void> saveSettings(Json value) async {
    await preferences.record('device').put(db, value);
  }

  Future<void> put(
    String owner,
    String kind,
    String id,
    Json data, {
    bool deleted = false,
  }) async {
    await records.record('$owner/$kind/$id').put(db, {
      'owner': owner,
      'kind': kind,
      'id': id,
      'data': data,
      'deleted': deleted,
      'modified': DateTime.now().toUtc().toIso8601String(),
      'dirty': true,
    });
  }

  Future<void> merge(String owner, List<Json> remote) async {
    await db.transaction((txn) async {
      for (final row in remote) {
        final ref = records.record('$owner/${row['kind']}/${row['id']}');
        final local = await ref.get(txn);
        if (local == null ||
            DateTime.parse(
                  row['modified'],
                ).compareTo(DateTime.parse(local['modified'] as String)) >=
                0) {
          await ref.put(txn, {...row, 'owner': owner, 'dirty': false});
        }
      }
    });
  }

  Future<void> migrateGuest(String owner) async {
    final guest = await all('guest');

    await db.transaction((txn) async {
      for (final row in guest) {
        await records.record('$owner/${row['kind']}/${row['id']}').put(txn, {
          ...row,
          'owner': owner,
          'dirty': true,
        });
        await records.record('guest/${row['kind']}/${row['id']}').delete(txn);
      }
    });
  }

  Future<void> clearOwner(String owner) async {
    await records.delete(
      db,
      finder: Finder(filter: Filter.equals('owner', owner)),
    );
  }
}
