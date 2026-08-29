import '../models/pet.dart';
import '../models/weight_log.dart';
import '../models/medication.dart';

/// Supplies mock demo pets and sample data ONLY when Demo Mode is activated.
class DemoDataSupplier {
  static List<Pet> get demoPets => [
        Pet(
          id: 'p1',
          name: 'Luna',
          breed: 'Golden Retriever',
          ageString: '2 yrs',
          birthDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
          avatarUrl:
              'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&q=80&w=400',
          status: 'Healthy',
          weight: 28.5,
          weightHistory: [
            WeightLog(
              id: 'w1',
              date: DateTime.now().subtract(const Duration(days: 30)),
              weight: 28.0,
            ),
            WeightLog(
              id: 'w2',
              date: DateTime.now(),
              weight: 28.5,
            ),
          ],
          medications: [
            Medication(
              id: 'm1',
              name: 'Rabies Vaccine',
              dose: '1 vial',
              frequency: 'Annual',
              nextDoseDate: DateTime.now().add(const Duration(days: 180)),
              type: 'vaccine',
            ),
          ],
          photos: const [
            'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&q=80&w=400',
            'https://images.unsplash.com/photo-1537151608828-ea2b11777ee8?auto=format&fit=crop&q=80&w=400',
          ],
          species: 'Dog',
          gender: 'Female',
          neutered: 'Yes',
          medicalConditions: const ['None'],
          allergies: const ['Chicken'],
          activityLevel: 'High',
          dietEnabled: true,
          foodType: 'Dry Kibble',
          feedingNotes: '2 cups twice daily',
          behaviorTags: const ['Friendly', 'Energetic'],
        ),
        Pet(
          id: 'p2',
          name: 'Oliver',
          breed: 'Tabby Cat',
          ageString: '4 yrs',
          birthDate: DateTime.now().subtract(const Duration(days: 365 * 4)),
          avatarUrl:
              'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&q=80&w=400',
          status: 'Healthy',
          weight: 4.2,
          weightHistory: [
            WeightLog(
              id: 'w3',
              date: DateTime.now(),
              weight: 4.2,
            ),
          ],
          medications: [
            Medication(
              id: 'm2',
              name: 'Flea & Tick Prevention',
              dose: '1 pip',
              frequency: 'Monthly',
              nextDoseDate: DateTime.now().add(const Duration(days: 14)),
              type: 'flea_tick',
            ),
          ],
          photos: const [
            'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&q=80&w=400',
          ],
          species: 'Cat',
          gender: 'Male',
          neutered: 'Yes',
          medicalConditions: const ['Sensitive Stomach'],
          allergies: const ['Fish'],
          activityLevel: 'Moderate',
          dietEnabled: true,
          foodType: 'Wet Food',
          feedingNotes: '1 can daily',
          behaviorTags: const ['Playful', 'Curious'],
        ),
        Pet(
          id: 'p3',
          name: 'Bella',
          breed: 'French Bulldog',
          ageString: '1 yr',
          birthDate: DateTime.now().subtract(const Duration(days: 365)),
          avatarUrl:
              'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&q=80&w=400',
          status: 'Puppy',
          weight: 11.0,
          weightHistory: [
            WeightLog(
              id: 'w4',
              date: DateTime.now(),
              weight: 11.0,
            ),
          ],
          medications: const [],
          photos: const [
            'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&q=80&w=400',
          ],
          species: 'Dog',
          gender: 'Female',
          neutered: 'No',
          medicalConditions: const ['None'],
          allergies: const [],
          activityLevel: 'Moderate',
          dietEnabled: true,
          foodType: 'Puppy Formula',
          feedingNotes: '1.5 cups twice daily',
          behaviorTags: const ['Cuddly', 'Calm'],
        ),
      ];
}
