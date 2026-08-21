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
            Icon(Icons.vaccines, color: AppTheme.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Vaccinations & Immunization Scheme',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Track past administration dates, next booster due dates, and batch numbers.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),

        if (widget.vaccinations.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceContainer),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.secondary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No vaccinations added yet. Choose a preset or custom vaccine below.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

        ...widget.vaccinations.asMap().entries.map((entry) {
          final index = entry.key;
          final vaccine = entry.value;
          final date = vaccine['date'] as DateTime?;
          final nextDoseDate = vaccine['nextDoseDate'] as DateTime?;
          final lotNumber = (vaccine['lotNumber'] as String?) ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.surfaceContainer),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.vaccines_outlined,
                        size: 20,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vaccine['name'] ?? 'Vaccine',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if ((vaccine['subtitle'] ?? '').toString().isNotEmpty)
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
                const SizedBox(height: 14),

                // Date Selection Row: Administered Date & Next Booster Date
                Row(
                  children: [
                    // Administered Date Picker
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Administered Date',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: date ?? DateTime.now(),
                                firstDate: DateTime(2015),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                widget.onVaccineDateChanged(index, picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.surfaceContainer,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: AppTheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      date == null
                                          ? 'Select Date'
                                          : '${date.day}/${date.month}/${date.year}',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Next Booster Date Picker
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Next Booster Due',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    nextDoseDate ??
                                    (date != null
                                        ? DateTime(
                                            date.year + 1,
                                            date.month,
                                            date.day,
                                          )
                                        : DateTime.now().add(
                                            const Duration(days: 365),
                                          )),
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 30),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365 * 3),
                                ),
                              );
                              if (picked != null) {
                                setState(() {
                                  vaccine['nextDoseDate'] = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.surfaceContainer,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.notifications_active_outlined,
                                    size: 14,
                                    color: AppTheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      nextDoseDate == null
                                          ? 'None'
                                          : '${nextDoseDate.day}/${nextDoseDate.month}/${nextDoseDate.year}',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: nextDoseDate == null
                                            ? AppTheme.secondary
                                            : AppTheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (nextDoseDate != null)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          vaccine['nextDoseDate'] = null;
                                        });
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: AppTheme.secondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Lot Number Field
                TextFormField(
                  initialValue: lotNumber,
                  onChanged: (val) {
                    vaccine['lotNumber'] = val.trim();
                  },
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Batch / Lot # (optional, e.g. VAC-99402)',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceContainerLowest,
                    prefixIcon: const Icon(Icons.qr_code, size: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.surfaceContainer,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.surfaceContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 8),

        // Action Row: Add Preset Vaccine or Custom Vaccine
        Row(
          children: [
            // Add Preset Popup Menu Button
            Expanded(
              child: PopupMenuButton<Map<String, String>>(
                onSelected: (preset) {
                  widget.onAddCustomVaccine(preset['name']!);
                  final added = widget.vaccinations.last;
                  added['subtitle'] = preset['subtitle'];
                  setState(() {});
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: {
                      'name': 'Rabies',
                      'subtitle': 'Core vaccine - Annual / 3-Yr Booster',
                    },
                    child: Text('🐶/🐱 Rabies Vaccine'),
                  ),
                  PopupMenuItem(
                    value: {
                      'name': 'DHPP (Distemper/Parvo)',
                      'subtitle': 'Core combination protection',
                    },
                    child: Text('🐶 DHPP (Distemper/Parvo)'),
                  ),
                  PopupMenuItem(
                    value: {
                      'name': 'Bordetella',
                      'subtitle': 'Kennel Cough protection',
                    },
                    child: Text('🐶 Bordetella'),
                  ),
                  PopupMenuItem(
                    value: {
                      'name': 'Leptospirosis',
                      'subtitle': 'Bacterial infection protection',
                    },
                    child: Text('🐶 Leptospirosis'),
                  ),
                  PopupMenuItem(
                    value: {
                      'name': 'FVRCP',
                      'subtitle': 'Feline core combination',
                    },
                    child: Text('🐱 FVRCP (Feline Combo)'),
                  ),
                  PopupMenuItem(
                    value: {
                      'name': 'FeLV',
                      'subtitle': 'Feline Leukemia Virus protection',
                    },
                    child: Text('🐱 FeLV (Feline Leukemia)'),
                  ),
                  PopupMenuItem(
                    value: {
                      'name': 'Lyme Vaccine',
                      'subtitle': 'Tick-borne disease protection',
                    },
                    child: Text('🐶 Lyme Disease Vaccine'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 18, color: AppTheme.primary),
                      SizedBox(width: 6),
                      Text(
                        'Preset Vaccine',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Custom Vaccine Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _isCustomVaccineVisible = true),
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text(
                  'Custom Vaccine',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),

        if (_isCustomVaccineVisible) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customVaccineController,
                  decoration: const InputDecoration(
                    hintText: 'Enter vaccine name...',
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
        ],
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
        const SizedBox(height: 14),

        // 2-Column Grid Layout
        Column(
          children: [
            // Row 1: [Diabetes] [Arthritis]
            Row(
              children: [
                Expanded(child: _buildConditionButton('Diabetes')),
                const SizedBox(width: 10),
                Expanded(child: _buildConditionButton('Arthritis')),
              ],
            ),
            const SizedBox(height: 10),

            // Row 2: [Heart Murmur] [Epilepsy]
            Row(
              children: [
                Expanded(child: _buildConditionButton('Heart Murmur')),
                const SizedBox(width: 10),
                Expanded(child: _buildConditionButton('Epilepsy')),
              ],
            ),
            const SizedBox(height: 10),

            // Row 3: [None] [Add Custom]
            Row(
              children: [
                Expanded(child: _buildConditionButton('None')),
                const SizedBox(width: 10),
                Expanded(child: _buildAddCustomButton()),
              ],
            ),
          ],
        ),

        // Custom Added Conditions Tags
        if (widget.selectedConditions.any(
          (c) =>
              c != 'diabetes' &&
              c != 'arthritis' &&
              c != 'heart murmur' &&
              c != 'epilepsy' &&
              c != 'none',
        )) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedConditions
                .where(
                  (c) =>
                      c != 'diabetes' &&
                      c != 'arthritis' &&
                      c != 'heart murmur' &&
                      c != 'epilepsy' &&
                      c != 'none',
                )
                .map((condition) {
                  return Chip(
                    label: Text(condition),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => widget.onConditionToggled(condition),
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                      fontSize: 12,
                    ),
                  );
                })
                .toList(),
          ),
        ],

        if (_isCustomConditionVisible) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customConditionController,
                  autofocus: true,
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
        ],
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
        TextField(
          controller: _allergySearchController,
          decoration: const InputDecoration(
            hintText: 'Search or type custom allergy...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            final query = value.trim();
            if (query.isNotEmpty) {
              widget.onAllergyAdded(query);
              _allergySearchController.clear();
              setState(() {
                _isAllergyDropdownVisible = false;
                _filteredAllergies = [];
              });
            }
          },
          onChanged: _onSearchChanged,
        ),
        if (_isAllergyDropdownVisible && _filteredAllergies.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceContainer),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
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
        ],
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

  Widget _buildConditionButton(String label) {
    final lowerKey = label.toLowerCase();
    final isSelected = widget.selectedConditions.contains(lowerKey);

    return InkWell(
      onTap: () => widget.onConditionToggled(lowerKey),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.12)
              : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.surfaceContainerHighest,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_circle, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? AppTheme.primary : AppTheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCustomButton() {
    return InkWell(
      onTap: () => setState(() => _isCustomConditionVisible = true),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 16, color: AppTheme.primary),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Add custom',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
