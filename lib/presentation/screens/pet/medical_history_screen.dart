import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/medication.dart';
import '../../theme/app_theme.dart';
import 'meds_vaccines_screen.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final Pet pet;
  const MedicalHistoryScreen({super.key, required this.pet});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
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

  // ignore: unused_element
  void _showAddRecordDialog(BuildContext context) {
    final nameController = TextEditingController();
    final otherNameController = TextEditingController();
    final lotNumberController = TextEditingController();
    final doseAmountController = TextEditingController(text: '1');
    String doseUnit = 'Tablet';
    String recordType =
        'vaccine'; // Default to vaccine on Medical History screen
    String medCategory = 'heartworm';

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

    String medRoute = 'Oral';
    String medFrequency = 'Every 24h';
    DateTime medStartDate = DateTime.now();
    TimeOfDay? medStartTime;
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
                          label: const Text('Vaccine'),
                          selected: recordType == 'vaccine',
                          selectedColor: AppTheme.primaryFixed,
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() => recordType = 'vaccine');
                            }
                          },
                        ),
                        const SizedBox(width: 8),
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
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (recordType == 'vaccine') ...[
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
                          if (!context.mounted) return;
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
                            if (!context.mounted) return;
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

                      const Text(
                        'Dose',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: doseAmountController,
                              keyboardType: doseUnit == 'Tablet'
                                  ? TextInputType.text
                                  : const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              decoration: InputDecoration(
                                hintText: doseUnit == 'Tablet' ? '1' : '0.5',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              initialValue: doseUnit,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Tablet',
                                  child: Text('Tablet'),
                                ),
                                DropdownMenuItem(
                                  value: 'mg',
                                  child: Text('mg'),
                                ),
                                DropdownMenuItem(
                                  value: 'ml',
                                  child: Text('ml'),
                                ),
                                DropdownMenuItem(
                                  value: 'Other',
                                  child: Text('Other'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => doseUnit = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doseUnit == 'Tablet'
                            ? 'Format example: 1 or 1/2'
                            : (doseUnit == 'Other'
                                  ? 'Custom doses like puffs, times, etc.'
                                  : 'Format example: 0.5'),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 12),

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
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => medRoute = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

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
                          DropdownMenuItem(
                            value: 'Every 8h',
                            child: Text('Every 8h'),
                          ),
                          DropdownMenuItem(
                            value: 'Every 12h',
                            child: Text('Every 12h'),
                          ),
                          DropdownMenuItem(
                            value: 'Every 24h',
                            child: Text('Every 24h'),
                          ),
                          DropdownMenuItem(
                            value: 'Weekly',
                            child: Text('Weekly'),
                          ),
                          DropdownMenuItem(
                            value: 'Monthly',
                            child: Text('Monthly'),
                          ),
                          DropdownMenuItem(
                            value: 'One-time',
                            child: Text('One-time'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => medFrequency = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

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
                          if (!context.mounted) return;
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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Administration time (Optional)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          if (medStartTime != null)
                            IconButton(
                              icon: const Icon(
                                Icons.clear,
                                size: 16,
                                color: AppTheme.error,
                              ),
                              onPressed: () {
                                setDialogState(() => medStartTime = null);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: medStartTime ?? TimeOfDay.now(),
                          );
                          if (!context.mounted) return;
                          if (picked != null) {
                            setDialogState(() => medStartTime = picked);
                          }
                        },
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(
                          medStartTime != null
                              ? medStartTime!.format(context)
                              : 'No Start Time selected',
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

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
                              icon: const Icon(
                                Icons.clear,
                                size: 16,
                                color: AppTheme.error,
                              ),
                              onPressed: () {
                                setDialogState(() => medEndDate = null);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                medEndDate ??
                                medStartDate.add(const Duration(days: 7)),
                            firstDate: medStartDate,
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 3),
                            ),
                          );
                          if (!context.mounted) return;
                          if (picked != null) {
                            setDialogState(() => medEndDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          medEndDate != null
                              ? _formatDate(medEndDate!)
                              : 'No End Date selected',
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
                        medStartTime?.hour ?? 0,
                        medStartTime?.minute ?? 0,
                      );

                      DateTime calculatedNext = finalAdministered;
                      if (medFrequency == 'Every 8h') {
                        calculatedNext = finalAdministered.add(
                          const Duration(hours: 8),
                        );
                      } else if (medFrequency == 'Every 12h') {
                        calculatedNext = finalAdministered.add(
                          const Duration(hours: 12),
                        );
                      } else if (medFrequency == 'Every 24h') {
                        calculatedNext = finalAdministered.add(
                          const Duration(days: 1),
                        );
                      } else if (medFrequency == 'Weekly') {
                        calculatedNext = finalAdministered.add(
                          const Duration(days: 7),
                        );
                      } else if (medFrequency == 'Monthly') {
                        calculatedNext = finalAdministered.add(
                          const Duration(days: 30),
                        );
                      } else if (medFrequency == 'One-time') {
                        calculatedNext = finalAdministered;
                      }
                      finalNext = calculatedNext;

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
                        dose: recordType == 'medication'
                            ? '${doseAmountController.text.trim().isNotEmpty ? doseAmountController.text.trim() : '1'} $doseUnit'
                            : '',
                        route: recordType == 'medication' ? medRoute : '',
                        frequency: recordType == 'medication'
                            ? medFrequency
                            : '',
                        startDate: recordType == 'medication'
                            ? finalAdministered
                            : null,
                        endDate: recordType == 'medication' ? medEndDate : null,
                        remindersEnabled: recordType == 'medication'
                            ? medReminder
                            : false,
                        hasStartTime: recordType == 'medication'
                            ? medStartTime != null
                            : true,
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
    ).then((_) {
      nameController.dispose();
      otherNameController.dispose();
      lotNumberController.dispose();
      doseAmountController.dispose();
    });
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PetBloc, PetState>(
      builder: (context, petState) {
        if (petState is PetLoaded) {
          final updatedPet = petState.pets.firstWhere(
            (p) => p.id == _pet.id || p.id == widget.pet.id,
            orElse: () => _pet,
          );
          _pet = updatedPet;
        }

        final vaccines =
            _pet.medications
                .where((m) => m.type == 'vaccine' && m.isSavedToHistory == true)
                .toList()
              ..sort((a, b) {
                final dateA = a.administeredDate ?? a.nextDoseDate;
                final dateB = b.administeredDate ?? b.nextDoseDate;
                return dateB.compareTo(dateA);
              });

        // Find the next upcoming booster (vaccines in future)
        Medication? upcomingBooster;
        for (final v in vaccines) {
          if (v.nextDoseDate.isAfter(DateTime.now())) {
            if (upcomingBooster == null ||
                v.nextDoseDate.isBefore(upcomingBooster.nextDoseDate)) {
              upcomingBooster = v;
            }
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${_pet.name}\'s Medical History',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MedsVaccinesScreen(pet: _pet),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Record'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
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
                const SizedBox(height: 16),

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
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2.2),
                            1: FlexColumnWidth(1.6),
                            2: FlexColumnWidth(2.2),
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
                              ],
                            ),
                            ...vaccines.map((v) {
                              final isExpired =
                                  v.nextDoseDate.isBefore(DateTime.now()) &&
                                  !v.isCompleted;
                              final isCompleted = v.isCompleted;

                              final String statusLabel;
                              final Color statusColor;
                              final Color statusText;
                              final IconData statusIcon;

                              if (isCompleted) {
                                statusLabel = 'Administered';
                                statusColor = AppTheme.primaryFixed;
                                statusText = AppTheme.onPrimaryFixedVariant;
                                statusIcon = Icons.check_circle;
                              } else if (isExpired) {
                                statusLabel = 'Overdue';
                                statusColor = const Color(0xFFFFDAD6);
                                statusText = const Color(0xFF410002);
                                statusIcon = Icons.error_outline;
                              } else {
                                statusLabel = 'Scheduled';
                                statusColor = const Color(0xFFFEF08A);
                                statusText = const Color(0xFF854D0E);
                                statusIcon = Icons.event;
                              }

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
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
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
                                        GestureDetector(
                                          onTap: () => _showDeleteConfirmDialog(
                                            context,
                                            v,
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
