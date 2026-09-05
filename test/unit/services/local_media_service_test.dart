import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pawsncare/data/services/local_media_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalMediaService Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saveLocalAvatar and getLocalAvatar persist and retrieve avatar path', () async {
      const petId = 'pet_123';
      const path = '/storage/emulated/0/Pictures/pet.jpg';

      await LocalMediaService.saveLocalAvatar(petId, path);
      final retrieved = await LocalMediaService.getLocalAvatar(petId);

      expect(retrieved, equals(path));
    });

    test('saveLocalPhotos and getLocalPhotos persist and retrieve photo list', () async {
      const petId = 'pet_123';
      final photos = ['/path/photo1.png', '/path/photo2.png'];

      await LocalMediaService.saveLocalPhotos(petId, photos);
      final retrieved = await LocalMediaService.getLocalPhotos(petId);

      expect(retrieved, equals(photos));
    });

    test('returns null / empty when petId is empty or non-existent', () async {
      expect(await LocalMediaService.getLocalAvatar('non_existent'), isNull);
      expect(await LocalMediaService.getLocalPhotos('non_existent'), isEmpty);

      await LocalMediaService.saveLocalAvatar('', '/path.jpg');
      expect(await LocalMediaService.getLocalAvatar(''), isNull);
    });
  });
}
