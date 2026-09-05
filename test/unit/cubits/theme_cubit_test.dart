import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pawsncare/logic/theme/theme_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeCubit Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'pawsncare_is_dark_mode': false});
    });

    test('initial state is false (light mode default)', () {
      final cubit = ThemeCubit();
      expect(cubit.state, isFalse);
    });

    test('loadTheme loads stored theme setting from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'pawsncare_is_dark_mode': true});
      final cubit = ThemeCubit();
      await cubit.loadTheme();
      expect(cubit.state, isTrue);
    });

    test('toggleTheme toggles theme state and persists value to SharedPreferences', () async {
      final cubit = ThemeCubit();
      expect(cubit.state, isFalse);

      await cubit.toggleTheme();
      expect(cubit.state, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('pawsncare_is_dark_mode'), isTrue);

      await cubit.toggleTheme();
      expect(cubit.state, isFalse);
      expect(prefs.getBool('pawsncare_is_dark_mode'), isFalse);
    });
  });
}
