import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../theme/app_theme.dart';
import 'nutrition_screen.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  String _selectedUnit = 'Cups';
  final List<String> _selectedPets = ['All Pets'];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handlePetSelection(String petName, List<String> allRegisteredPets) {
    setState(() {
      if (petName == 'All Pets') {
        _selectedPets.clear();
        _selectedPets.add('All Pets');
      } else {
        _selectedPets.remove('All Pets');
        if (_selectedPets.contains(petName)) {
          _selectedPets.remove(petName);
        } else {
          _selectedPets.add(petName);
        }

        // If all registered pets are selected, reset to All Pets
        final containsAll = allRegisteredPets.every(
          (p) => _selectedPets.contains(p),
        );
        if (containsAll || _selectedPets.isEmpty) {
          _selectedPets.clear();
          _selectedPets.add('All Pets');
        }
      }
    });
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              padding: EdgeInsets.all(12),
              dialTextStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          child: Transform.scale(
            scale: 1.25,
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveReminder() {
    final title = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Meal';
    final amountText = _amountController.text.trim().isNotEmpty
        ? _amountController.text.trim()
        : '1.0';

    final formattedTime = _selectedTime.format(context);
    final subtitle =
        '$formattedTime • $amountText ${_selectedUnit.toLowerCase()}';

    final newItem = ReminderItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      subtitle: subtitle,
      targetPets: List.from(_selectedPets),
      type: 'feeding',
      notes: _notesController.text.trim(),
      time: _selectedTime,
    );

    Navigator.of(context).pop(newItem);
  }

  @override
  Widget build(BuildContext context) {
    final petState = context.watch<PetBloc>().state;
    final List<String> registeredPets = [];
    if (petState is PetLoaded) {
      registeredPets.addAll(petState.pets.map((p) => p.name));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paws & Care',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppTheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Add Meal Reminder',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pet Selection
                    const Text(
                      'SELECT PETS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // All Pets Chip
                        _buildPetChip(
                          'All Pets',
                          Colors.transparent,
                          registeredPets,
                        ),
                        // Individual Pets Chips
                        ...registeredPets.map((name) {
                          // Standard colors for tags from Stitch layout
                          Color bulletColor = AppTheme.secondary;
                          if (name.toLowerCase() == 'luna') {
                            bulletColor = AppTheme.tertiary;
                          } else if (name.toLowerCase() == 'oliver') {
                            bulletColor = AppTheme.primaryFixedDim;
                          }
                          return _buildPetChip(
                            name,
                            bulletColor,
                            registeredPets,
                          );
                        }), //.toList(),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Form Fields Bento Grid style
                    // Meal Name (Sage Accent Border)
                    _buildBentoInputCard(
                      label: 'Meal Name',
                      accentColor: AppTheme.primary,
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(fontFamily: 'Inter'),
                        decoration: InputDecoration(
                          hintText: 'e.g. Breakfast',
                          hintStyle: TextStyle(
                            color: AppTheme.secondary.withValues(alpha: 0.4),
                          ),
                          suffixIcon: const Icon(
                            Icons.edit,
                            size: 20,
                            color: AppTheme.secondary,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reminder Time (Terracotta Accent Border)
                    _buildBentoInputCard(
                      label: 'Reminder Time',
                      accentColor: AppTheme.tertiary,
                      child: GestureDetector(
                        onTap: _selectTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: Colors.transparent,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedTime.format(context),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(
                                Icons.access_time,
                                color: AppTheme.tertiary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Food Amount (Secondary Accent Border)
                    _buildBentoInputCard(
                      label: 'Food Amount',
                      accentColor: AppTheme.secondary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: const TextStyle(fontFamily: 'Inter'),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 1.5',
                                    hintStyle: TextStyle(
                                      color: AppTheme.secondary.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              DropdownButton<String>(
                                value: _selectedUnit,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Cups',
                                    child: Text('Cups'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Grams',
                                    child: Text('Grams'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Ounces',
                                    child: Text('Ounces'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Scoops',
                                    child: Text('Scoops'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedUnit = val);
                                  }
                                },
                              ),
                            ],
                          ),
                          const Divider(),
                          const Text(
                            'Recommended: 1.2 cups based on age/weight.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Additional Notes (Optional)
                    _buildBentoInputCard(
                      label: 'Additional Notes (Optional)',
                      accentColor: AppTheme.primary,
                      child: TextField(
                        controller: _notesController,
                        maxLines: 2,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Mix with supplement or warm water...',
                          hintStyle: TextStyle(
                            color: AppTheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 12,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withValues(alpha: 0.9),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppTheme.primary),
                      ),
                      child: const Text(
                        'Discard',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveReminder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Reminder',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetChip(
    String name,
    Color bulletColor,
    List<String> allRegisteredPets,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedPets.contains(name);
    return ChoiceChip(
      avatar: bulletColor != Colors.transparent
          ? CircleAvatar(radius: 4, backgroundColor: bulletColor)
          : null,
      label: Text(name),
      selected: isSelected,
      onSelected: (val) => _handlePetSelection(name, allRegisteredPets),
      selectedColor: AppTheme.primary,
      backgroundColor:
          isDark ? const Color(0xFF383634) : AppTheme.surfaceContainerLowest,
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        color: isSelected
            ? Colors.white
            : (isDark ? AppTheme.darkOnSurface : AppTheme.secondary),
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? AppTheme.primary
              : (isDark ? const Color(0xFF4A4846) : AppTheme.surfaceContainer),
        ),
      ),
    );
  }

  Widget _buildBentoInputCard({
    required String label,
    required Color accentColor,
    required Widget child,
  }) {
    final stripeWidth = accentColor == AppTheme.surfaceContainer ? 1.0 : 4.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.surfaceContainer),
        ),
        child: Stack(
          children: [
            // Accent stripe on the left
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: stripeWidth, color: accentColor),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: accentColor == AppTheme.surfaceContainer
                          ? AppTheme.onSurfaceVariant
                          : accentColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
