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
  final TextEditingController weightController;
  final String selectedWeightUnit;
  final ValueChanged<String> onWeightUnitChanged;

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
    required this.weightController,
    required this.selectedWeightUnit,
    required this.onWeightUnitChanged,
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
        const SizedBox(height: 24),

        // Weight Input Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pet Weight',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.surfaceContainer),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => onWeightUnitChanged('kg'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: selectedWeightUnit == 'kg'
                            ? AppTheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'kg',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: selectedWeightUnit == 'kg'
                              ? Colors.white
                              : AppTheme.secondary,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onWeightUnitChanged('lbs'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: selectedWeightUnit == 'lbs'
                            ? AppTheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'lbs',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: selectedWeightUnit == 'lbs'
                              ? Colors.white
                              : AppTheme.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontFamily: 'Inter'),
          decoration: InputDecoration(
            hintText: selectedWeightUnit == 'kg' ? 'e.g. 10.5' : 'e.g. 23.0',
            suffixText: selectedWeightUnit,
            helperText: selectedWeightUnit == 'kg'
                ? 'Standard weight range: 0.1 kg - 150.0 kg'
                : 'Standard weight range: 0.2 lbs - 330.0 lbs',
            helperStyle: TextStyle(
              color: AppTheme.secondary.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: 24),

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
                    activeThumbColor: AppTheme.primary,
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
                  initialValue: selectedFoodType,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Mixed', child: Text('Mixed')),
                    DropdownMenuItem(
                      value: 'Home-cooked',
                      child: Text('Home-cooked'),
                    ),
                    DropdownMenuItem(
                      value: 'Dry Kibble',
                      child: Text('Dry Kibble'),
                    ),
                    DropdownMenuItem(
                      value: 'Wet Food',
                      child: Text('Wet Food'),
                    ),
                    DropdownMenuItem(
                      value: 'Raw Diet',
                      child: Text('Raw Diet'),
                    ),

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
                  minLines: 2,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g. 1/2 cup twice a day, morning and evening.',
                    hintStyle: TextStyle(
                      color: AppTheme.secondary.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.surfaceContainer,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.surfaceContainer,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 1.5,
                      ),
                    ),
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
          children:
              [
                'Social',
                'Anxious',
                'Quiet',
                'Playful',
                'Vocal',
                'Independent',
              ].map((tag) {
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
          color: isSelected
              ? AppTheme.primaryFixedDim.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.surfaceContainer,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primary, size: 28),
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
