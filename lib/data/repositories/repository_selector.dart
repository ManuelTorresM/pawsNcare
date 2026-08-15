import 'package:shared_preferences/shared_preferences.dart';
import 'base_repository.dart';
import 'mock_repository.dart';
import 'firebase_repository.dart';

class RepositorySelector {
  static const String _key = 'pawsncare_db_source';
  
  final MockRepository _mockRepository = MockRepository();
  final FirebaseRepository _firebaseRepository = FirebaseRepository();

  static Future<String> getDbSource() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? 'mock';
  }

  static Future<void> setDbSource(String source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, source);
  }

  Future<BaseRepository> getActiveRepository() async {
    final source = await getDbSource();
    if (source == 'firebase') {
      return _firebaseRepository;
    }
    return _mockRepository;
  }
}
