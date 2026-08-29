import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import 'base_repository.dart';
import 'firebase_repository.dart';
import 'demo_repository.dart';

class RepositorySelector {
  static const String _key = 'pawsncare_db_source';

  final FirebaseRepository _firebaseRepository = FirebaseRepository();
  final DemoRepository _demoRepository = DemoRepository();

  static Future<String> getDbSource() async {
    return AppConfig.isDemoMode ? 'demo' : 'firebase';
  }

  static Future<void> setDbSource(String source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, source);
  }

  Future<BaseRepository> getActiveRepository() async {
    if (AppConfig.isDemoMode) {
      return _demoRepository;
    }
    return _firebaseRepository;
  }
}
