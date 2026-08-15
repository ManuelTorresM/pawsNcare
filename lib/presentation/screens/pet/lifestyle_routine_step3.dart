import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LifestyleRoutineStep3 extends StatelessWidget {
  final String selectedActivityLevel;
  final ValueChanged<String> onActivityLevelChanged;

  final bool isDietEnabled;
  final ValueChanged<bool> onDietEnabledChanged;
  final String selectedFoodType;
  final ValueChanged<String> onFoodTypeChanged;
  final TextEditingController feedingNotesController;

  final List<String> selectedBehaviorTags;
  final ValueChanged<String> onBehaviorTagToggled;

  const LifestyleRoutineStep3({
    super.key,
    required this.selectedActivityLevel,
    required this.onActivityLevelChanged,
    required this.isDietEnabled,
    required this.onDietEnabledChanged,
    required this.selectedFoodType,
    required this.onFoodTypeChanged,
    required this.feedingNotesController,
    required this.selectedBehaviorTags,
    required this.onBehaviorTagToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intro
        const Text(
          'Lifestyle & Routine',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Help us understand your pet\'s daily habits for better care recommendations.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),

        // Section 1: Activity Level
        const Text(
          'Activity Level',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildActivityCard('Low', Icons.bed_outlined, 'Low'),
            _buildActivityCard('Moderate', Icons.directions_walk, 'Moderate'),
            _buildActivityCard('High', Icons.run_circle_outlined, 'High'),
            _buildActivityCard('Very High', Icons.bolt, 'Very High'),
          ],
        ),
        const SizedBox(height: 32),

        // Section 2: Diet & Nutrition Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.surfaceContainer),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Diet & Nutrition',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Switch(
                    value: isDietEnabled,
                    activeColor: AppTheme.primary,
                    onChanged: onDietEnabledChanged,
                  ),
                ],
              ),
              if (isDietEnabled) ...[
                const SizedBox(height: 16),
                const Text(
                  'Main food type',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedFoodType,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Dry Kibble', child: Text('Dry Kibble')),
                    DropdownMenuItem(value: 'Wet Food', child: Text('Wet Food')),
                    DropdownMenuItem(value: 'Raw Diet', child: Text('Raw Diet')),
                    DropdownMenuItem(value: 'Mixed', child: Text('Mixed')),
                    DropdownMenuItem(value: 'Home-cooked', child: Text('Home-cooked')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      onFoodTypeChanged(val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Feeding Schedule/Notes',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: feedingNotesController,
                  maxLines: 3,
                  style: const TextStyle(fontFamily: 'Inter'),
                  decoration: InputDecoration(
                    hintText: 'e.g. 1/2 cup twice a day, morning and evening.',
                    hintStyle: TextStyle(color: AppTheme.secondary.withOpacity(0.5)),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Section 3: Behavior Tags
        const Text(
          'Behavior Tags (Optional)',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ['Social', 'Anxious', 'Quiet', 'Playful', 'Vocal', 'Independent'].map((tag) {
            final isSelected = selectedBehaviorTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (val) => onBehaviorTagToggled(tag),
              selectedColor: AppTheme.secondaryContainer,
              checkmarkColor: AppTheme.secondary,
              labelStyle: TextStyle(
                fontFamily: 'Inter',
                color: isSelected ? AppTheme.onSurface : AppTheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActivityCard(String value, IconData icon, String label) {
    final isSelected = selectedActivityLevel == value;
    return GestureDetector(
      onTap: () => onActivityLevelChanged(value),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryFixedDim.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.surfaceContainer,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppTheme.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
