import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

class CreatePetStep1 extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController breedController;
  final String? selectedSpecies;
  final ValueChanged<String?> onSpeciesChanged;
  final String? selectedGender;
  final ValueChanged<String?> onGenderChanged;
  final String? selectedNeutered;
  final ValueChanged<String?> onNeuteredChanged;
  final DateTime? birthDate;
  final ValueChanged<DateTime?> onBirthDateChanged;
  final String selectedAvatar;
  final VoidCallback onPhotoSelectorPressed;

  const CreatePetStep1({
    super.key,
    required this.nameController,
    required this.breedController,
    required this.selectedSpecies,
    required this.onSpeciesChanged,
    required this.selectedGender,
    required this.onGenderChanged,
    required this.selectedNeutered,
    required this.onNeuteredChanged,
    required this.birthDate,
    required this.onBirthDateChanged,
    required this.selectedAvatar,
    required this.onPhotoSelectorPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photo Upload Area
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: onPhotoSelectorPressed,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 64,
                      backgroundColor: AppTheme.secondaryContainer,
                      backgroundImage:
                          selectedAvatar.startsWith('assets/')
                          ? AssetImage(selectedAvatar) as ImageProvider
                          : (selectedAvatar.startsWith('http') ||
                                      selectedAvatar.startsWith('https')
                                  ? NetworkImage(selectedAvatar)
                                  : FileImage(File(selectedAvatar)))
                              as ImageProvider,
                    ),
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primary,
                      child: Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Help us identify your companion with a clear photo.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppTheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Pet Name Field
        const Text(
          'Pet Name',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: nameController,
          style: const TextStyle(fontFamily: 'Inter'),
          decoration: InputDecoration(
            hintText: 'e.g. Luna',
            hintStyle: TextStyle(
              color: AppTheme.secondary.withValues(alpha: 0.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            filled: true,
            fillColor: AppTheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Species Section (Chips matching HTML wrap)
        const Text(
          'Species',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSpeciesChip('dog', LucideIcons.dog, 'Dog'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSpeciesChip('cat', LucideIcons.cat, 'Cat'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSpeciesChip('bird', LucideIcons.bird, 'Bird'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSpeciesChip(
                    'rabbit',
                    Icons.cruelty_free,
                    'Rabbit',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSpeciesChip(
                    'hamster',
                    LucideIcons.squirrel,
                    'Hamster',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSpeciesChip('fish', LucideIcons.fish, 'Fish'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSpeciesChip(
                    'other',
                    LucideIcons.helpCircle,
                    'Other',
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Breed Search & suggestion card
        const Text(
          'Breed',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: breedController,
          style: const TextStyle(fontFamily: 'Inter'),
          decoration: InputDecoration(
            hintText: 'Search breeds...',
            hintStyle: TextStyle(
              color: AppTheme.secondary.withValues(alpha: 0.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            filled: true,
            fillColor: AppTheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Gender Selection Chips
        const Text(
          'Gender',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildOptionChip(
                'Male',
                Icons.male,
                selectedGender,
                onGenderChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOptionChip(
                'Female',
                Icons.female,
                selectedGender,
                onGenderChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Neutered / Spayed Chips
        const Text(
          'Neutered / Spayed',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildOptionChip(
                'Yes',
                null,
                selectedNeutered,
                onNeuteredChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOptionChip(
                'No',
                null,
                selectedNeutered,
                onNeuteredChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Date of Birth
        const Text(
          'Date of Birth',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate:
                  birthDate ??
                  DateTime.now().subtract(const Duration(days: 365)),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              onBirthDateChanged(date);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  birthDate == null
                      ? 'Select date'
                      : '${birthDate!.day}/${birthDate!.month}/${birthDate!.year}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: birthDate == null
                        ? AppTheme.secondary.withValues(alpha: 0.5)
                        : AppTheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(Icons.calendar_today, color: AppTheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeciesChip(String value, IconData icon, String label) {
    final isSelected = selectedSpecies == value;
    return OutlinedButton(
      onPressed: () => onSpeciesChanged(value),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? AppTheme.primary
            : AppTheme.surfaceContainerLow,
        foregroundColor: isSelected ? Colors.white : AppTheme.secondary,
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceContainer,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : AppTheme.secondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChip(
    String value,
    IconData? icon,
    String? currentValue,
    ValueChanged<String?> onChanged,
  ) {
    final isSelected = currentValue == value;
    return OutlinedButton(
      onPressed: () => onChanged(value),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? AppTheme.primary
            : AppTheme.surfaceContainerLow,
        foregroundColor: isSelected ? Colors.white : AppTheme.secondary,
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceContainer,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: isSelected ? Colors.white : AppTheme.secondary),
            const SizedBox(width: 8),
          ],
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
