import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'app_constants.dart';

class DatabaseService {
  // Private constructor to prevent instantiation
  DatabaseService._();

  // The single static instance of FirebaseDatabase
  static final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: AppConstants.firebaseDbUrl,
  );

  // Expose a static getter that returns a DatabaseReference to the root
  static DatabaseReference get db => _database.ref();
}
