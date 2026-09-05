import 'package:flutter/material.dart';
import '../../../data/models/pet.dart';
import '../../theme/app_theme.dart';
import '../base_form_dialog.dart';

class EditHealthProfileDialog extends StatefulWidget {
  final Pet pet;
  final ValueChanged<Pet> onSave;

  const EditHealthProfileDialog({
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
      builder: (_) => EditHealthProfileDialog(
        pet: pet,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditHealthProfileDialog> createState() => _EditHealthProfileDialogState();
}

class _EditHealthProfileDialogState extends State<EditHealthProfileDialog> {
  late List<String> _selectedConditions;
  late List<String> _selectedAllergies;

  bool _isCustomConditionVisible = false;
  final TextEditingController _customConditionCtrl = TextEditingController();
  final TextEditingController _allergySearchCtrl = TextEditingController();

  static const List<String> _allergyLibrary = [
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
  void initState() {
    super.initState();
    _selectedConditions = List<String>.from(widget.pet.medicalConditions);
    if (_selectedConditions.isEmpty) {
      _selectedConditions = ['none'];
    }
    _selectedAllergies = List<String>.from(widget.pet.allergies);
  }

  @override
  void dispose() {
    _customConditionCtrl.dispose();
    _allergySearchCtrl.dispose();
    super.dispose();
  }

  void _toggleCondition(String condition) {
    setState(() {
      final lower = condition.toLowerCase();
      if (lower == 'none') {
        _selectedConditions = ['none'];
      } else {
        _selectedConditions.remove('none');
        if (_selectedConditions.contains(lower)) {
          _selectedConditions.remove(lower);
        } else {
          _selectedConditions.add(lower);
        }
        if (_selectedConditions.isEmpty) {
          _selectedConditions = ['none'];
        }
      }
    });
  }

  Widget _buildConditionButton(String label) {
    final lower = label.toLowerCase();
    final isSelected = _selectedConditions.contains(lower);
    return OutlinedButton(
      onPressed: () => _toggleCondition(label),
      style: OutlinedButton.styleFrom(
        backgroundColor:
            isSelected ? AppTheme.primary : AppTheme.surfaceContainerLow,
        foregroundColor: isSelected ? Colors.white : AppTheme.secondary,
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceContainer,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAddCustomButton() {
    return OutlinedButton.icon(
      onPressed: () => setState(() => _isCustomConditionVisible = true),
      icon: const Icon(Icons.add, size: 14),
      label: const Text(
        'Add Custom',
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
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseFormDialog(
      icon: Icons.healing_outlined,
      title: 'Edit Health Profile',
      subtitle: 'Update medical conditions & allergies',
      primaryButtonText: 'Save',
      primaryButtonIcon: Icons.check,
      onPrimaryPressed: () {
        final updated = widget.pet.copyWith(
          medicalConditions: _selectedConditions,
          allergies: _selectedAllergies,
        );
        widget.onSave(updated);
        Navigator.pop(context);
      },
      children: [
        // Section 1: Medical Conditions
        const Row(
          children: [
            Icon(
              Icons.healing_outlined,
              color: AppTheme.primary,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Medical Conditions',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2-Column Grid Layout
        Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildConditionButton('Diabetes')),
                const SizedBox(width: 8),
                Expanded(child: _buildConditionButton('Arthritis')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildConditionButton('Heart Murmur')),
                const SizedBox(width: 8),
                Expanded(child: _buildConditionButton('Epilepsy')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildConditionButton('None')),
                const SizedBox(width: 8),
                Expanded(child: _buildAddCustomButton()),
              ],
            ),
          ],
        ),

        // Custom Added Conditions Tags
        if (_selectedConditions.any(
          (c) =>
              c != 'diabetes' &&
              c != 'arthritis' &&
              c != 'heart murmur' &&
              c != 'epilepsy' &&
              c != 'none',
        )) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedConditions
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
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => _toggleCondition(condition),
                    backgroundColor: AppTheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    labelStyle: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                      fontSize: 11,
                    ),
                  );
                })
                .toList(),
          ),
        ],

        if (_isCustomConditionVisible) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customConditionCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Enter condition...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: () {
                  final text = _customConditionCtrl.text.trim();
                  if (text.isNotEmpty) {
                    _toggleCondition(text);
                    _customConditionCtrl.clear();
                    setState(
                      () => _isCustomConditionVisible = false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Add'),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(
                  () => _isCustomConditionVisible = false,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 20),

        // Section 2: Allergies
        const Row(
          children: [
            Icon(Icons.eco_outlined, color: AppTheme.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Allergies',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _allergySearchCtrl,
          decoration: const InputDecoration(
            hintText: 'Search or type custom allergy...',
            isDense: true,
            prefixIcon: Icon(Icons.search, size: 18),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          onSubmitted: (value) {
            final query = value.trim();
            if (query.isNotEmpty) {
              setState(() {
                if (!_selectedAllergies.contains(query)) {
                  _selectedAllergies.add(query);
                }
                _allergySearchCtrl.clear();
                _isAllergyDropdownVisible = false;
                _filteredAllergies = [];
              });
            }
          },
          onChanged: (query) {
            if (query.isEmpty) {
              setState(() {
                _filteredAllergies = [];
                _isAllergyDropdownVisible = false;
              });
              return;
            }
            final filtered = _allergyLibrary
                .where(
                  (a) =>
                      a.toLowerCase().contains(query.toLowerCase()) &&
                      !_selectedAllergies.contains(a),
                )
                .toList();
            setState(() {
              _filteredAllergies = filtered;
              _isAllergyDropdownVisible = true;
            });
          },
        ),

        if (_isAllergyDropdownVisible &&
            _filteredAllergies.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceContainer),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: _filteredAllergies.map((allergy) {
                  return ListTile(
                    dense: true,
                    title: Text(
                      allergy,
                      style: const TextStyle(fontSize: 13),
                    ),
                    onTap: () {
                      setState(() {
                        if (!_selectedAllergies.contains(allergy)) {
                          _selectedAllergies.add(allergy);
                        }
                        _allergySearchCtrl.clear();
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

        if (_selectedAllergies.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedAllergies.map((allergy) {
              return Chip(
                label: Text(allergy),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () {
                  setState(() {
                    _selectedAllergies.remove(allergy);
                  });
                },
                backgroundColor: AppTheme.errorContainer,
                labelStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.error,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
