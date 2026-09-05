import 'package:flutter/material.dart';
import '../../../data/models/pet.dart';
import '../../theme/app_theme.dart';
import '../base_form_dialog.dart';

class EditLifestyleDialog extends StatefulWidget {
  final Pet pet;
  final ValueChanged<Pet> onSave;

  const EditLifestyleDialog({
    super.key,
    required this.pet,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required Pet pet,
    required ValueChanged<Pet> onSave,
  }) {
    return showDialog(
      context: context,
      builder: (_) => EditLifestyleDialog(
        pet: pet,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditLifestyleDialog> createState() => _EditLifestyleDialogState();
}

class _EditLifestyleDialogState extends State<EditLifestyleDialog> {
  late String _selectedActivity;
  late bool _isDietEnabled;
  late String _selectedFoodType;
  late TextEditingController _notesCtrl;
  late List<String> _selectedBehaviorTags;

  static const List<String> _foodTypeItems = [
    'Mixed',
    'Home-cooked',
    'Dry Kibble',
    'Wet Food',
    'Raw Diet',
    'Other',
  ];

  static const List<String> _presetBehaviorTags = [
    'Social',
    'Anxious',
    'Quiet',
    'Playful',
    'Vocal',
    'Independent',
  ];

  @override
  void initState() {
    super.initState();
    _selectedActivity = widget.pet.activityLevel.isNotEmpty
        ? widget.pet.activityLevel
        : 'Moderate';
    _isDietEnabled = widget.pet.dietEnabled;
    _selectedFoodType = widget.pet.foodType.isNotEmpty
        ? widget.pet.foodType
        : 'Dry Kibble';
    _notesCtrl = TextEditingController(text: widget.pet.feedingNotes);
    _selectedBehaviorTags = List<String>.from(widget.pet.behaviorTags);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Widget _buildActivityCard(
    String value,
    IconData icon,
    String label,
  ) {
    final isSelected =
        _selectedActivity.toLowerCase() == value.toLowerCase();
    return GestureDetector(
      onTap: () => setState(() => _selectedActivity = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryFixedDim.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.surfaceContainer,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primary, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseFormDialog(
      icon: Icons.directions_run,
      title: 'Edit Lifestyle & Routine',
      subtitle: 'Update activity level, diet & behavior tags',
      primaryButtonText: 'Save',
      primaryButtonIcon: Icons.check,
      onPrimaryPressed: () {
        final updated = widget.pet.copyWith(
          activityLevel: _selectedActivity,
          dietEnabled: _isDietEnabled,
          foodType: _selectedFoodType,
          feedingNotes: _notesCtrl.text.trim(),
          behaviorTags: _selectedBehaviorTags,
        );
        widget.onSave(updated);
        Navigator.pop(context);
      },
      children: [
        // Section 1: Activity Level
        const Text(
          'Activity Level',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.3,
          children: [
            _buildActivityCard('Low', Icons.bed_outlined, 'Low'),
            _buildActivityCard(
              'Moderate',
              Icons.directions_walk,
              'Moderate',
            ),
            _buildActivityCard(
              'High',
              Icons.run_circle_outlined,
              'High',
            ),
            _buildActivityCard('Very High', Icons.bolt, 'Very High'),
          ],
        ),
        const SizedBox(height: 20),

        // Section 2: Diet & Nutrition Card
        Container(
          padding: const EdgeInsets.all(16),
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
                      fontSize: 14,
                    ),
                  ),
                  Switch(
                    value: _isDietEnabled,
                    activeThumbColor: AppTheme.primary,
                    onChanged: (val) {
                      setState(() => _isDietEnabled = val);
                    },
                  ),
                ],
              ),
              if (_isDietEnabled) ...[
                const SizedBox(height: 14),
                const Text(
                  'Main food type',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _foodTypeItems.contains(_selectedFoodType)
                      ? _selectedFoodType
                      : 'Dry Kibble',
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  items: _foodTypeItems
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedFoodType = val);
                    }
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  'Feeding Schedule/Notes',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  minLines: 2,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'e.g. 1/2 cup twice a day, morning and evening.',
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
        const SizedBox(height: 20),

        // Section 3: Behavior Tags
        const Text(
          'Behavior Tags (Optional)',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetBehaviorTags.map((tag) {
            final isSelected = _selectedBehaviorTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (isSelected) {
                    _selectedBehaviorTags.remove(tag);
                  } else {
                    _selectedBehaviorTags.add(tag);
                  }
                });
              },
              selectedColor: AppTheme.secondaryContainer,
              checkmarkColor: AppTheme.secondary,
              labelStyle: TextStyle(
                fontFamily: 'Inter',
                color: isSelected
                    ? AppTheme.onSurface
                    : AppTheme.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
