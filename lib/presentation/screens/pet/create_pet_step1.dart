import 'package:flutter/material.dart';
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
                      backgroundImage: NetworkImage(selectedAvatar),
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
            hintStyle: TextStyle(color: AppTheme.secondary.withOpacity(0.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _buildSpeciesChip('dog', Icons.pets, 'Dog'),
            _buildSpeciesChip('cat', Icons.star, 'Cat'),
            _buildSpeciesChip('bird', Icons.flutter_dash, 'Bird'),
            _buildSpeciesChip('rabbit', Icons.cruelty_free, 'Rabbit'),
            _buildSpeciesChip('hamster', Icons.pets, 'Hamster'),
            _buildSpeciesChip('fish', Icons.set_meal, 'Fish'),
            _buildSpeciesChip('other', Icons.psychology_alt, 'Other'),
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
            hintStyle: TextStyle(color: AppTheme.secondary.withOpacity(0.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: AppTheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Asymmetric Suggestion Card (Collie image card)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryFixedDim.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryFixedDim.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCUJTjOkcgom3y9eaGx5QDFMWOjaIXt0muqzbfsVfi5NAzenR8DmNAhQG0CzZTo9aDGmFAYLBe1e8YCr6wNDHdlDS3Cg-ONgCf6q-oa3A1gz42lkrD39l1SHBtOkskyYKWpCXGh-A0uOPYIXgIDyNTOHQybgKNYmUfRttzmnClTMx5Tp8W5wxYYYM29q4G5CpBNWj4zO6QoZR1gRuRYebTpWxIboMV-Lh6xC15wbBdZmrRZgsnqw7jVFgPcb9NE5Yb9E9HF2QxIZNM',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not sure?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Try browsing our library of popular breeds for common traits.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            Expanded(child: _buildOptionChip('Male', Icons.male, selectedGender, onGenderChanged)),
            const SizedBox(width: 12),
            Expanded(child: _buildOptionChip('Female', Icons.female, selectedGender, onGenderChanged)),
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
            Expanded(child: _buildOptionChip('Yes', null, selectedNeutered, onNeuteredChanged)),
            const SizedBox(width: 12),
            Expanded(child: _buildOptionChip('No', null, selectedNeutered, onNeuteredChanged)),
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
              initialDate: birthDate ?? DateTime.now().subtract(const Duration(days: 365)),
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
                    color: birthDate == null ? AppTheme.secondary.withOpacity(0.5) : AppTheme.onSurface,
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
    return ChoiceChip(
      avatar: Icon(
        icon,
        color: isSelected ? Colors.white : AppTheme.secondary,
        size: 20,
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          onSpeciesChanged(value);
        }
      },
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.surfaceContainerLow,
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        color: isSelected ? Colors.white : AppTheme.secondary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceContainer,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        backgroundColor: isSelected ? AppTheme.primary : AppTheme.surfaceContainerLow,
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
