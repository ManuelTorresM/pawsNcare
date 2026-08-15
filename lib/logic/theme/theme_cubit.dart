import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<bool> {
  static const String _key = 'pawsncare_is_dark_mode';

  ThemeCubit() : super(false) {
    loadTheme();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? false;
    emit(isDark);
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final nextState = !state;
    await prefs.setBool(_key, nextState);
    emit(nextState);
  }
}
