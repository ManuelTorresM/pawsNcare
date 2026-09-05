import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../../data/models/pet.dart';
import '../../../core/services/local_media_service.dart';
import 'pet_profile_screen.dart';

class CreatePetFinishScreen extends StatelessWidget {
  final Pet pet;

  const CreatePetFinishScreen({
    super.key,
    required this.pet,
  });

  ImageProvider _getPetImageProvider(String url) {
    return LocalMediaService.resolveImageProvider(
      url,
      fallbackAsset: 'assets/avatars/dog.png',
    )!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // 1. Hero Image & Checkmark Badge
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ambient halo background
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryContainer.withAlpha(60),
                      ),
                    ),
                    // Circular Pet Image
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(30),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        image: DecorationImage(
                          image: _getPetImageProvider(pet.avatarUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Floating Check Badge
                    Positioned(
                      bottom: 8,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // 2. Headline Title
              Text(
                '${pet.name} is all set!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 12),

              // 3. Subtitle Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'You can now start tracking ${pet.name}\'s health, weight, and medications. We\'ll help you keep their tail wagging.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    height: 1.5,
                    color: AppTheme.secondary,
                  ),
                ),
              ),

              const Spacer(),

              // 4. Action Buttons (View Profile & Go to Dashboard)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => PetProfileScreen(pet: pet),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.visibility,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'View Profile',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(
                        Icons.dashboard,
                        color: AppTheme.onSurface,
                        size: 20,
                      ),
                      label: const Text(
                        'Go to Dashboard',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryContainer,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
