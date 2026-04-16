import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'app_constants.dart';

class DatabaseService {
  final FirebaseDatabase _database;

  DatabaseService({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: AppConstants.firebaseDbUrl,
        );

  DatabaseReference get db => _database.ref();
}
