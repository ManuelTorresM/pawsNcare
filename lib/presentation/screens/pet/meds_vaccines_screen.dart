import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/medication.dart';
import '../../theme/app_theme.dart';

class MedsVaccinesScreen extends StatefulWidget {
  final Pet pet;
  const MedsVaccinesScreen({super.key, required this.pet});

  @override
  State<MedsVaccinesScreen> createState() => _MedsVaccinesScreenState();
}

class _MedsVaccinesScreenState extends State<MedsVaccinesScreen> {
  late Pet _pet;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _showAddRecordDialog(BuildContext context) {
    final nameController = TextEditingController();
    final otherNameController = TextEditingController();
    final lotNumberController = TextEditingController();
    final dosageController = TextEditingController(text: '1 Tablet');
    String recordType = 'medication'; // 'medication' or 'vaccine'
    String medCategory = 'heartworm'; // 'heartworm', 'flea_tick', 'as_needed'

    // Vaccine custom fields
    final predefinedVaccines = [
      'Rabies',
      'Leptospirosis',
      'Bordetella',
      'Other',
    ];
    String selectedVaccine = 'Rabies';
    DateTime adminDate = DateTime.now();
    bool scheduleNextBooster = true;
    DateTime nextBoosterDate = DateTime.now().add(const Duration(days: 365));

    // Medication custom fields
    String medRoute = 'Oral';
    String medFrequency = 'Every 24h';
    DateTime medStartDate = DateTime.now();
    TimeOfDay medStartTime = TimeOfDay.now();
    DateTime? medEndDate;
    bool medReminder = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Add Health Log',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Choice chips for record type
                    const Text(
                      'Record Type',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Medication'),
                          selected: recordType == 'medication',
                          selectedColor: AppTheme.primaryFixed,
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() => recordType = 'medication');
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Vaccine'),
                          selected: recordType == 'vaccine',
                          selectedColor: AppTheme.primaryFixed,
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() => recordType = 'vaccine');
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (recordType == 'vaccine') ...[
                      // 1. Vaccine Type Options
                      const Text(
                        'Vaccine Type',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: predefinedVaccines.map((vacName) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(vacName),
                                selected: selectedVaccine == vacName,
                                selectedColor: AppTheme.primaryFixed,
                                onSelected: (val) {
                                  if (val) {
                                    setDialogState(
                                      () => selectedVaccine = vacName,
                                    );
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (selectedVaccine == 'Other') ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Custom Vaccine Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: otherNameController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. DHPP Booster',
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // 2. Optional batch number/manufacturer
                      const Text(
                        'Batch # / Manufacturer (Optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: lotNumberController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Lot #RB-4421, Zoetis',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3. Administration Date
                      const Text(
                        'Administration Date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: adminDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365 * 5),
                            ),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => adminDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_formatDate(adminDate)),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 4. Optional Next Administration Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Schedule Next Booster?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Switch(
                            value: scheduleNextBooster,
                            onChanged: (val) {
                              setDialogState(() => scheduleNextBooster = val);
                            },
                            activeThumbColor: AppTheme.primary,
                          ),
                        ],
                      ),
                      if (scheduleNextBooster) ...[
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: nextBoosterDate,
                              firstDate: adminDate,
                              lastDate: adminDate.add(
                                const Duration(days: 365 * 10),
                              ),
                            );
                            if (picked != null) {
                              setDialogState(() => nextBoosterDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(_formatDate(nextBoosterDate)),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ] else ...[
                      // 1. Medication name
                      const Text(
                        'Medication name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Apoquel, Heartworm pill',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. Dose
                      const Text(
                        'Dose',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: dosageController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 1 tablet, 2.5 ml, 1 pump',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3. Route
                      const Text(
                        'Route',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: medRoute,
                        items: const [
                          DropdownMenuItem(value: 'Oral', child: Text('Oral')),
                          DropdownMenuItem(
                            value: 'Topical (spot-on)',
                            child: Text('Topical (spot-on)'),
                          ),
                          DropdownMenuItem(
                            value: 'Injectable',
                            child: Text('Injectable'),
                          ),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => medRoute = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // 4. Frequency
                      const Text(
                        'Frequency',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: medFrequency,
                        items: const [
                          DropdownMenuItem(value: 'Every 8h', child: Text('Every 8h')),
                          DropdownMenuItem(value: 'Every 12h', child: Text('Every 12h')),
                          DropdownMenuItem(value: 'Every 24h', child: Text('Every 24h')),
                          DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                          DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                          DropdownMenuItem(value: 'One-time', child: Text('One-time')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => medFrequency = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // 5. Start date
                      const Text(
                        'Start date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: medStartDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 3),
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() => medStartDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_formatDate(medStartDate)),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 5.2 Administration time
                      const Text(
                        'Administration time',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: medStartTime,
                          );
                          if (picked != null) {
                            setDialogState(() => medStartTime = picked);
                          }
                        },
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(medStartTime.format(context)),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      // 5.5 End date (Optional)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'End date (Optional)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          if (medEndDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: AppTheme.error),
                              onPressed: () {
                                setDialogState(() => medEndDate = null);
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: medEndDate ?? medStartDate.add(const Duration(days: 7)),
                            firstDate: medStartDate,
                            lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                          );
                          if (picked != null) {
                            setDialogState(() => medEndDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(medEndDate != null ? _formatDate(medEndDate!) : 'No End Date selected'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 6. Reminder
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Reminder (notifications)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Switch(
                            value: medReminder,
                            onChanged: (val) {
                              setDialogState(() => medReminder = val);
                            },
                            activeThumbColor: AppTheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    String finalName = '';
                    String finalLot = '';
                    DateTime finalAdministered = DateTime.now();
                    DateTime finalNext = DateTime.now();

                    if (recordType == 'vaccine') {
                      if (selectedVaccine == 'Other') {
                        finalName = otherNameController.text.trim();
                      } else {
                        finalName = selectedVaccine;
                      }
                      finalLot = lotNumberController.text.trim();
                      finalAdministered = adminDate;
                      if (scheduleNextBooster) {
                        finalNext = nextBoosterDate;
                      } else {
                        // Far future date if not scheduled
                        finalNext = adminDate.add(
                          const Duration(days: 365 * 10),
                        );
                      }
                    } else {
                      finalName = nameController.text.trim();
                      finalAdministered = DateTime(
                        medStartDate.year,
                        medStartDate.month,
                        medStartDate.day,
                        medStartTime.hour,
                        medStartTime.minute,
                      );

                      // Calculate nextDate based on frequency
                      DateTime calculatedNext = finalAdministered;
                      if (medFrequency == 'Every 8h') {
                        calculatedNext = finalAdministered.add(const Duration(hours: 8));
                      } else if (medFrequency == 'Every 12h') {
                        calculatedNext = finalAdministered.add(const Duration(hours: 12));
                      } else if (medFrequency == 'Every 24h') {
                        calculatedNext = finalAdministered.add(const Duration(days: 1));
                      } else if (medFrequency == 'Weekly') {
                        calculatedNext = finalAdministered.add(const Duration(days: 7));
                      } else if (medFrequency == 'Monthly') {
                        calculatedNext = finalAdministered.add(const Duration(days: 30));
                      } else if (medFrequency == 'One-time') {
                        calculatedNext = finalAdministered;
                      }
                      finalNext = calculatedNext;

                      // Map frequency to category type
                      if (medFrequency == 'One-time') {
                        medCategory = 'as_needed';
                      } else {
                        medCategory = 'heartworm';
                      }
                    }

                    if (finalName.isNotEmpty) {
                      final newMed = Medication(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: finalName,
                        nextDoseDate: finalNext,
                        administeredDate: finalAdministered,
                        type: recordType == 'vaccine' ? 'vaccine' : medCategory,
                        lotNumber: finalLot,
                        dose: recordType == 'medication' ? dosageController.text.trim() : '',
                        route: recordType == 'medication' ? medRoute : '',
                        frequency: recordType == 'medication' ? medFrequency : '',
                        startDate: recordType == 'medication' ? finalAdministered : null,
                        endDate: recordType == 'medication' ? medEndDate : null,
                        remindersEnabled: recordType == 'medication' ? medReminder : false,
                      );
                      final updatedMeds = List<Medication>.from(
                        _pet.medications,
                      )..add(newMed);
                      final updatedPet = _pet.copyWith(
                        medications: updatedMeds,
                      );
                      context.read<PetBloc>().add(UpdatePet(updatedPet));
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Medication med) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Health Record?'),
        content: Text(
          'Are you sure you want to delete "${med.name}" from history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedMeds = _pet.medications
                  .where((m) => m.id != med.id)
                  .toList();
              final updatedPet = _pet.copyWith(medications: updatedMeds);
              context.read<PetBloc>().add(UpdatePet(updatedPet));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRenewVaccineDialog(BuildContext context, Medication med) {
    DateTime nextBooster = DateTime.now().add(const Duration(days: 365));
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Renew ${med.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select next booster due date:'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: nextBooster,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                  );
                  if (picked != null) {
                    setDialogState(() => nextBooster = picked);
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(_formatDate(nextBooster)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedMeds = _pet.medications.map((m) {
                  if (m.id == med.id) {
                    return m.copyWith(
                      nextDoseDate: nextBooster,
                      administeredDate: DateTime.now(),
                    );
                  }
                  return m;
                }).toList();
                final updatedPet = _pet.copyWith(medications: updatedMeds);
                context.read<PetBloc>().add(UpdatePet(updatedPet));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Renew'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final petState = context.watch<PetBloc>().state;
    if (petState is PetLoaded) {
      final updatedPet = petState.pets.firstWhere(
        (p) => p.id == _pet.id,
        orElse: () => _pet,
      );
      if (updatedPet.id == _pet.id) {
        _pet = updatedPet;
      }
    }

    final activeMeds = _pet.medications
        .where((m) => m.type != 'vaccine')
        .toList();
    final vaccines = _pet.medications
        .where((m) => m.type == 'vaccine')
        .toList();

    // Find the next upcoming booster (vaccines in future)
    Medication? upcomingBooster;
    final futureVaccines =
        vaccines.where((v) => v.nextDoseDate.isAfter(DateTime.now())).toList()
          ..sort((a, b) => a.nextDoseDate.compareTo(b.nextDoseDate));
    if (futureVaccines.isNotEmpty) {
      upcomingBooster = futureVaccines.first;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _pet.name,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.primary,
              ),
            ),
            const Text(
              'Health Records',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppTheme.secondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppTheme.primary),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('No new alerts')));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordDialog(context),
        backgroundColor: AppTheme.tertiary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add_moderator),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Medications Section
            Row(
              children: const [
                Icon(Icons.medication, color: AppTheme.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'Active Medications',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (activeMeds.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'No active medications logged.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeMeds.length,
                itemBuilder: (context, index) {
                  final med = activeMeds[index];
                  final isAsNeeded = med.type == 'as_needed';
                  final accentColor = isAsNeeded
                      ? AppTheme.tertiary
                      : AppTheme.primary;
                  final categoryLabel = isAsNeeded
                      ? 'As Needed'
                      : 'Daily Prescription';
                  final detailIcon = isAsNeeded
                      ? Icons.health_and_safety
                      : Icons.medication;
                  final badgeBg = isAsNeeded
                      ? AppTheme.tertiaryFixed
                      : AppTheme.primaryFixed;
                  final badgeText = isAsNeeded
                      ? AppTheme.onTertiaryFixedVariant
                      : AppTheme.onPrimaryFixedVariant;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    color: AppTheme.surfaceContainerLow,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border(
                          left: BorderSide(color: accentColor, width: 4),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    categoryLabel.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: accentColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    med.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  detailIcon,
                                  color: badgeText,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.scale,
                                size: 16,
                                color: AppTheme.secondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Dosage: ${med.dose.isNotEmpty ? med.dose : '1 Tablet'}${med.route.isNotEmpty ? ' (${med.route})' : ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.secondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.event_repeat,
                                size: 16,
                                color: AppTheme.secondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Frequency: ${med.frequency.isNotEmpty ? med.frequency : (isAsNeeded ? 'PRN' : 'Daily')}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.secondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: AppTheme.surfaceContainer),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Next due: ${med.nextDoseDate.day}/${med.nextDoseDate.month}/${med.nextDoseDate.year}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.secondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showDeleteConfirmDialog(context, med),
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: AppTheme.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),

            // Vaccination Section
            Row(
              children: const [
                Icon(Icons.vaccines, color: AppTheme.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'Vaccination Schedule',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Upcoming booster alert banner
                  if (upcomingBooster != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.primaryFixed.withValues(alpha: 0.3),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'UPCOMING BOOSTER',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                Text(
                                  upcomingBooster.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Due in ${upcomingBooster.nextDoseDate.difference(DateTime.now()).inDays} days',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppTheme.error,
                                ),
                              ),
                              Text(
                                '${upcomingBooster.nextDoseDate.day}/${upcomingBooster.nextDoseDate.month}/${upcomingBooster.nextDoseDate.year}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Table list of vaccines
                  if (vaccines.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No vaccines logged.',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 420,
                        child: Table(
                          columnWidths: const {
                            0: FixedColumnWidth(120.0),
                            1: FixedColumnWidth(100.0),
                            2: FixedColumnWidth(100.0),
                            3: FixedColumnWidth(100.0),
                          },
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          children: [
                            const TableRow(
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerLow,
                              ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    'Vaccine Type',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppTheme.secondary,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    'Date Given',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppTheme.secondary,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    'Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppTheme.secondary,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    'Action',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppTheme.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            ...vaccines.map((v) {
                              final isExpired = v.nextDoseDate.isBefore(
                                DateTime.now(),
                              );
                              final statusLabel = isExpired
                                  ? 'Expired'
                                  : 'Active';
                              final statusColor = isExpired
                                  ? AppTheme.secondaryContainer
                                  : AppTheme.primaryFixed;
                              final statusText = isExpired
                                  ? AppTheme.secondary
                                  : AppTheme.onPrimaryFixedVariant;
                              final statusIcon = isExpired
                                  ? Icons.history
                                  : Icons.check_circle;

                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          v.lotNumber.isNotEmpty
                                              ? v.lotNumber
                                              : 'N/A',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      v.administeredDate != null
                                          ? _formatDate(v.administeredDate!)
                                          : 'N/A',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              statusIcon,
                                              size: 10,
                                              color: statusText,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              statusLabel,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: statusText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () => isExpired
                                              ? _showRenewVaccineDialog(
                                                  context,
                                                  v,
                                                )
                                              : null,
                                          child: Text(
                                            isExpired ? 'Renew' : 'Active',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isExpired
                                                  ? AppTheme.tertiary
                                                  : AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => _showDeleteConfirmDialog(
                                            context,
                                            v,
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline,
                                            size: 16,
                                            color: AppTheme.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
