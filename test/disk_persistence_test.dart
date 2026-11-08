import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_io.dart';
import 'package:daryeel/data/models.dart';
import 'package:daryeel/data/repository.dart';

void main() {
  test(
    'medicine and completion persist after closing and reopening disk database',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'daryeel-persistence-',
      );
      final path = '${directory.path}/test.db';
      final database = await databaseFactoryIo.openDatabase(path);
      final repository = LocalRepository(database);
      final now = DateTime.now();
      final m = Medicine(
        id: 'persistent',
        name: 'Test medicine',
        dosage: '1 tablet',
        times: [480],
        start: now,
        strength: 'Label strength',
        category: 'Personal category',
        notes: 'Personal note',
        food: 'After food',
        color: 0xFF2575CA,
        photo: 'cGhvdG8=',
        intervalDays: 2,
        refillAt: now.add(const Duration(days: 10)),
      );
      await repository.put('guest', 'medicine', m.id, m.toJson());
      final d = generateDoses([m], now, now).first.change({
        'status': 'taken',
        'completedAt': now.toUtc().toIso8601String(),
      });
      await repository.put('guest', 'dose', d.id, d.toJson());
      await repository.saveSettings({'name': 'Test'});
      await database.close();
      final reopened = await databaseFactoryIo.openDatabase(path);
      final saved = await LocalRepository(reopened).all('guest');
      expect(saved, hasLength(2));
      expect(
        saved.where((r) => r['kind'] == 'medicine').single['data'],
        m.toJson(),
      );
      expect(
        saved.where((r) => r['kind'] == 'dose').single['data']['status'],
        'taken',
      );
      expect((await LocalRepository(reopened).settings())['name'], 'Test');
      await reopened.close();
      await File(path).delete();
      await directory.delete();
    },
  );
}
