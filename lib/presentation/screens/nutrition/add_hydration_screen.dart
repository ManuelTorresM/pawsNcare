import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../theme/app_theme.dart';
import 'nutrition_screen.dart';

class AddHydrationScreen extends StatefulWidget {
  const AddHydrationScreen({super.key});

  @override
  State<AddHydrationScreen> createState() => _AddHydrationScreenState();
}

class _AddHydrationScreenState extends State<AddHydrationScreen> {
  final List<String> _selectedPets = ['All Pets'];
  String _selectedFrequency = '2h'; // '2h', '4h', '6h', 'custom'
  final _customFrequencyController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _customFrequencyController.dispose();
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

  void _saveReminder() {
    String label = '';
    if (_selectedFrequency == '2h') {
      label = 'Every 2 Hours';
    } else if (_selectedFrequency == '4h') {
      label = 'Every 4 Hours';
    } else if (_selectedFrequency == '6h') {
      label = 'Every 6 Hours';
    } else {
      final hours = _customFrequencyController.text.trim().isNotEmpty
          ? _customFrequencyController.text.trim()
          : '3';
      label = 'Every $hours Hours';
    }

    final newItem = ReminderItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: label,
      subtitle: 'Daily Reminder',
      targetPets: List.from(_selectedPets),
      type: 'hydration',
      notes: _notesController.text.trim(),
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
                    // Hero Section with Animation Style Card
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryFixed.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.water_drop,
                            color: AppTheme.primary,
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Keep them hydrated',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.primary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Automated water intake reminders for your furry friends',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Pet Selection Title
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

                    // Frequency Section Title
                    const Text(
                      'FREQUENCY',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 1.0,
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
                        _buildFrequencyCard('2h', '2h', 'Every 2 Hours'),
                        _buildFrequencyCard('4h', '4h', 'Every 4 Hours'),
                        _buildFrequencyCard('6h', '6h', 'Every 6 Hours'),
                        _buildCustomFrequencyCard(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Additional Notes Card
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
                          const Text(
                            'ADDITIONAL NOTES',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: AppTheme.primary,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _notesController,
                            maxLines: 2,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'e.g. Refill water fountain with fresh filtered water...',
                              hintStyle: TextStyle(
                                color: AppTheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 12,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Fixed Bottom Actions
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

  Widget _buildFrequencyCard(String key, String title, String subtitle) {
    final isSelected = _selectedFrequency == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFrequency = key),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryFixedDim.withValues(alpha: 0.2)
              : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: isSelected ? AppTheme.primary : AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomFrequencyCard() {
    final isSelected = _selectedFrequency == 'custom';
    return GestureDetector(
      onTap: () => setState(() => _selectedFrequency = 'custom'),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryFixedDim.withValues(alpha: 0.2)
              : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _customFrequencyController,
              keyboardType: TextInputType.number,
              onTap: () {
                setState(() => _selectedFrequency = 'custom');
              },
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: isSelected ? AppTheme.primary : AppTheme.onSurface,
              ),
              decoration: const InputDecoration(
                hintText: 'Custom',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const Text(
              'Hours',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
