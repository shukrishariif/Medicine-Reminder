import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

Future<Database> openLocalDatabase() async => databaseFactoryIo.openDatabase(
  p.join((await getApplicationSupportDirectory()).path, 'daryeel.db'),
);
