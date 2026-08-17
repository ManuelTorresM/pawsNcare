import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MedicalHistoryStep2 extends StatefulWidget {
  final List<Map<String, dynamic>> vaccinations;
  final ValueChanged<int> onVaccineRemoved;
  final Function(int, DateTime) onVaccineDateChanged;
  final ValueChanged<String> onAddCustomVaccine;

  final List<String> selectedConditions;
  final ValueChanged<String> onConditionToggled;
  final ValueChanged<String> onAddCustomCondition;

  final List<String> selectedAllergies;
  final ValueChanged<String> onAllergyAdded;
  final ValueChanged<String> onAllergyRemoved;

  const MedicalHistoryStep2({
    super.key,
    required this.vaccinations,
    required this.onVaccineRemoved,
    required this.onVaccineDateChanged,
    required this.onAddCustomVaccine,
    required this.selectedConditions,
    required this.onConditionToggled,
    required this.onAddCustomCondition,
    required this.selectedAllergies,
    required this.onAllergyAdded,
    required this.onAllergyRemoved,
  });

  @override
  State<MedicalHistoryStep2> createState() => _MedicalHistoryStep2State();
}

class _MedicalHistoryStep2State extends State<MedicalHistoryStep2> {
  // Custom Condition Input State
  bool _isCustomConditionVisible = false;
  final _customConditionController = TextEditingController();

  // Custom Vaccine Input State
  bool _isCustomVaccineVisible = false;
  final _customVaccineController = TextEditingController();

  // Allergies Autocomplete State
  final _allergySearchController = TextEditingController();
  final List<String> _allergyLibrary = const [
    'Beef',
    'Pollen',
    'Grain-Free',
    'Chicken',
    'Dairy',
    'Flea Saliva',
    'Penicillin',
    'Soy',
    'Wheat',
    'Dust Mites',
  ];
  List<String> _filteredAllergies = [];
  bool _isAllergyDropdownVisible = false;

  @override
  void dispose() {
    _customConditionController.dispose();
    _customVaccineController.dispose();
    _allergySearchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredAllergies = [];
        _isAllergyDropdownVisible = false;
      });
      return;
    }

    final filtered = _allergyLibrary
        .where(
          (allergy) =>
              allergy.toLowerCase().contains(query.toLowerCase()) &&
              !widget.selectedAllergies.contains(allergy),
        )
        .toList();

    setState(() {
      _filteredAllergies = filtered;
      _isAllergyDropdownVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intro
        const Text(
          'Health Details',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Help us personalize your pet\'s care by providing their previous medical records.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),

        // Section 1: Vaccinations
        Row(
          children: const [
            Icon(Icons.medical_services_outlined, color: AppTheme.primary),
            SizedBox(width: 8),
            Text(
              'Vaccinations',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...widget.vaccinations.asMap().entries.map((entry) {
          final index = entry.key;
          final vaccine = entry.value;
          final date = vaccine['date'] as DateTime?;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceContainer),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vaccine['name'],
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vaccine['subtitle'],
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date ?? DateTime.now(),
                      firstDate: DateTime(2015),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      widget.onVaccineDateChanged(index, picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.surfaceContainer),
                    ),
                    child: Text(
                      date == null
                          ? 'Select Date'
                          : '${date.day}/${date.month}/${date.year}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.secondary,
                    size: 20,
                  ),
                  onPressed: () => widget.onVaccineRemoved(index),
                ),
              ],
            ),
          );
        }), //.toList(),
        // Add Custom Vaccine button or input
        if (!_isCustomVaccineVisible)
          OutlinedButton.icon(
            onPressed: () => setState(() => _isCustomVaccineVisible = true),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Custom Vaccination'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(
                color: AppTheme.primary,
                style: BorderStyle.solid,
              ),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customVaccineController,
                  decoration: const InputDecoration(
                    hintText: 'Vaccine name...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_customVaccineController.text.trim().isNotEmpty) {
                    widget.onAddCustomVaccine(
                      _customVaccineController.text.trim(),
                    );
                    _customVaccineController.clear();
                    setState(() => _isCustomVaccineVisible = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add'),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () =>
                    setState(() => _isCustomVaccineVisible = false),
              ),
            ],
          ),
        const SizedBox(height: 32),

        // Section 2: Medical Conditions
        Row(
          children: const [
            Icon(Icons.healing_outlined, color: AppTheme.primary),
            SizedBox(width: 8),
            Text(
              'Medical Conditions',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...[
              'Diabetes',
              'Arthritis',
              'Heart Murmur',
              'Epilepsy',
              'None',
            ].map((condition) {
              final isSelected = widget.selectedConditions.contains(
                condition.toLowerCase(),
              );
              return _buildConditionChip(condition, isSelected);
            }), //.toList(),
            ...widget.selectedConditions
                .where(
                  (c) =>
                      c != 'diabetes' &&
                      c != 'arthritis' &&
                      c != 'heart murmur' &&
                      c != 'epilepsy' &&
                      c != 'none',
                )
                .map((condition) {
                  return _buildConditionChip(condition, true, isCustom: true);
                }), //.toList(),
          ],
        ),
        const SizedBox(height: 12),

        // Custom Condition field
        if (!_isCustomConditionVisible)
          OutlinedButton.icon(
            onPressed: () => setState(() => _isCustomConditionVisible = true),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Custom Condition'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(
                color: AppTheme.primary,
                style: BorderStyle.solid,
              ),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customConditionController,
                  decoration: const InputDecoration(
                    hintText: 'Enter condition name...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_customConditionController.text.trim().isNotEmpty) {
                    widget.onAddCustomCondition(
                      _customConditionController.text.trim(),
                    );
                    _customConditionController.clear();
                    setState(() => _isCustomConditionVisible = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add'),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () =>
                    setState(() => _isCustomConditionVisible = false),
              ),
            ],
          ),
        const SizedBox(height: 32),

        // Section 3: Allergies Search & Tags
        Row(
          children: const [
            Icon(Icons.eco_outlined, color: AppTheme.primary),
            SizedBox(width: 8),
            Text(
              'Allergies',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Stack(
          clipBehavior: Clip.none,
          children: [
            TextField(
              controller: _allergySearchController,
              decoration: const InputDecoration(
                hintText: 'Search allergies (e.g. Beef, Pollen)...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
            if (_isAllergyDropdownVisible && _filteredAllergies.isNotEmpty)
              Positioned(
                top: 56,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: _filteredAllergies.map((allergy) {
                      return ListTile(
                        title: Text(allergy),
                        onTap: () {
                          widget.onAllergyAdded(allergy);
                          _allergySearchController.clear();
                          setState(() {
                            _isAllergyDropdownVisible = false;
                            _filteredAllergies = [];
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Selected Allergies tags
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.selectedAllergies.map((allergy) {
            return Chip(
              label: Text(allergy),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => widget.onAllergyRemoved(allergy),
              backgroundColor: AppTheme.surfaceContainerLow,
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        // Decorative Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryFixedDim.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.info, color: AppTheme.primary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This information helps our vet network prepare better care plans for your furry friend. You can always edit these details later.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConditionChip(
    String label,
    bool isSelected, {
    bool isCustom = false,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        widget.onConditionToggled(label.toLowerCase());
      },
      selectedColor: AppTheme.primaryFixedDim,
      checkmarkColor: AppTheme.primary,
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        color: isSelected ? AppTheme.primary : AppTheme.secondary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
