import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/medication.dart';
import '../../theme/app_theme.dart';
import 'medical_history_screen.dart';

class MedsVaccinesScreen extends StatefulWidget {
  final Pet pet;
  final bool openAddDialog;
  const MedsVaccinesScreen({
    super.key,
    required this.pet,
    this.openAddDialog = false,
  });

  @override
  State<MedsVaccinesScreen> createState() => _MedsVaccinesScreenState();
}

class _MedsVaccinesScreenState extends State<MedsVaccinesScreen> {
  late Pet _pet;
  bool _isFabExpanded = false;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
    if (widget.openAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddOptionsModal(context);
      });
    }
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

  void _showDeleteConfirmDialog(BuildContext context, Medication med) {
    final parentContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Record'),
        content: Text('Are you sure you want to delete ${med.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedMeds = _pet.medications
                  .where((m) => m.id != med.id)
                  .toList();
              final updatedPet = _pet.copyWith(medications: updatedMeds);
              parentContext.read<PetBloc>().add(UpdatePet(updatedPet));
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditRecordDialog(BuildContext context, Medication item) {
    final parentContext = context;
    final isVaccine = item.type == 'vaccine';

    if (isVaccine) {
      final predefinedVaccines = [
        'Rabies',
        'Leptospirosis',
        'Bordetella',
        'DHPP',
        'FVRCP',
        'Other',
      ];
      String selectedVaccine = predefinedVaccines.contains(item.name)
          ? item.name
          : 'Other';
      final nameController = TextEditingController(
        text: selectedVaccine == 'Other' ? item.name : '',
      );

      // Parse lot info
      String initMfr = '';
      String initBatch = '';
      if (item.lotNumber.contains('(Batch #')) {
        final parts = item.lotNumber.split('(Batch #');
        initMfr = parts[0].trim();
        initBatch = parts[1].replaceAll(')', '').trim();
      } else if (item.lotNumber.startsWith('Batch #')) {
        initBatch = item.lotNumber.replaceAll('Batch #', '').trim();
      } else {
        initMfr = item.lotNumber.trim();
      }

      final manufacturerController = TextEditingController(text: initMfr);
      final batchController = TextEditingController(text: initBatch);

      final predefinedDoses = [
        '1st Dose',
        'Booster / Reinforcement',
        'Annual',
        'Other',
      ];
      String selectedDoseNumber = predefinedDoses.contains(item.dose)
          ? item.dose
          : 'Other';
      final customDoseController = TextEditingController(
        text: selectedDoseNumber == 'Other' ? item.dose : '',
      );

      String dateType = item.isCompleted ? 'Administered' : 'Scheduled';
      DateTime selectedDate = item.administeredDate ?? item.nextDoseDate;

      showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final isOtherVaccine = selectedVaccine == 'Other';
              final isOtherDose = selectedDoseNumber == 'Other';

              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  'Edit Vaccine',
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
                      // 1. Name
                      const Text(
                        'Vaccine Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: selectedVaccine,
                        items: predefinedVaccines
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedVaccine = val);
                          }
                        },
                      ),
                      if (isOtherVaccine) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            hintText: 'Enter vaccine name...',
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // 2. Manufacturer / Laboratory (Optional)
                      const Text(
                        'Manufacturer / Laboratory (Optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: manufacturerController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Zoetis, Merck, Boehringer',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3. Batch Number (Optional)
                      const Text(
                        'Batch Number (Optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: batchController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. B-987654',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 4. Number of Dose (1st, reinforcement, annual, etc)
                      const Text(
                        'Dose Number / Type',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: selectedDoseNumber,
                        items: predefinedDoses
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedDoseNumber = val);
                          }
                        },
                      ),
                      if (isOtherDose) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: customDoseController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. 3rd Dose, Booster #2...',
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Date Mode Selection
                      const Text(
                        'Date Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text(
                              'Administered',
                              style: TextStyle(fontSize: 11),
                            ),
                            selected: dateType == 'Administered',
                            selectedColor: AppTheme.primaryFixed,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  dateType = 'Administered';
                                  selectedDate = DateTime.now();
                                });
                              }
                            },
                          ),
                          ChoiceChip(
                            label: const Text(
                              'Re-schedule Date',
                              style: TextStyle(fontSize: 11),
                            ),
                            selected: dateType == 'Scheduled',
                            selectedColor: AppTheme.primaryFixed,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  dateType = 'Scheduled';
                                  selectedDate = DateTime.now().add(
                                    const Duration(days: 7),
                                  );
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Date Picker Button
                      Text(
                        dateType == 'Administered'
                            ? 'Administration Date'
                            : 'Re-schedule Date',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: selectedDate,
                            firstDate: dateType == 'Administered'
                                ? DateTime.now().subtract(
                                    const Duration(days: 365 * 10),
                                  )
                                : DateTime.now().subtract(
                                    const Duration(days: 365 * 2),
                                  ),
                            lastDate: dateType == 'Administered'
                                ? DateTime.now()
                                : DateTime.now().add(
                                    const Duration(days: 365 * 3),
                                  ),
                          );
                          if (!dialogContext.mounted) return;
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_formatDate(selectedDate)),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final vaccineName = isOtherVaccine
                          ? nameController.text.trim()
                          : selectedVaccine;
                      final doseLabel = isOtherDose
                          ? customDoseController.text.trim()
                          : selectedDoseNumber;

                      if (vaccineName.isNotEmpty) {
                        final mfrText = manufacturerController.text.trim();
                        final batchText = batchController.text.trim();

                        String lotInfo = '';
                        if (mfrText.isNotEmpty && batchText.isNotEmpty) {
                          lotInfo = '$mfrText (Batch #$batchText)';
                        } else if (batchText.isNotEmpty) {
                          lotInfo = 'Batch #$batchText';
                        } else if (mfrText.isNotEmpty) {
                          lotInfo = mfrText;
                        }

                        final isAlreadyAdministered =
                            dateType == 'Administered';

                        final updatedVaccine = item.copyWith(
                          name: vaccineName,
                          dose: doseLabel.isNotEmpty ? doseLabel : '1st Dose',
                          frequency: doseLabel.isNotEmpty
                              ? doseLabel
                              : 'Annual',
                          startDate: selectedDate,
                          nextDoseDate: isAlreadyAdministered
                              ? selectedDate.add(const Duration(days: 365))
                              : selectedDate,
                          administeredDate: isAlreadyAdministered
                              ? selectedDate
                              : null,
                          lotNumber: lotInfo,
                          isCompleted: isAlreadyAdministered,
                        );

                        final updatedMeds = _pet.medications
                            .map((m) => m.id == item.id ? updatedVaccine : m)
                            .toList();
                        final updatedPet = _pet.copyWith(
                          medications: updatedMeds,
                        );
                        parentContext.read<PetBloc>().add(
                          UpdatePet(updatedPet),
                        );
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              );
            },
          );
        },
      );
      return;
    }

    // Medication edit dialog
    String initialAmount = '1';
    String initialUnit = 'Tablet';
    if (item.dose.isNotEmpty) {
      final parts = item.dose.split(' ');
      if (parts.length >= 2) {
        initialAmount = parts[0];
        initialUnit = parts.sublist(1).join(' ');
      } else if (parts.isNotEmpty) {
        initialAmount = parts[0];
      }
    }

    final nameController = TextEditingController(text: item.name);
    final doseAmountController = TextEditingController(text: initialAmount);

    String doseUnit = ['Tablet', 'mg', 'ml', 'Other'].contains(initialUnit)
        ? initialUnit
        : 'Other';
    String frequency = item.frequency.isNotEmpty ? item.frequency : 'Every 24h';
    DateTime startDate = item.startDate ?? item.nextDoseDate;
    DateTime? endDate = item.endDate;
    bool reminder = item.remindersEnabled;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Edit Medication',
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
                      'Medication Name',
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
                            decoration: const InputDecoration(hintText: '1'),
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
                              DropdownMenuItem(value: 'mg', child: Text('mg')),
                              DropdownMenuItem(value: 'ml', child: Text('ml')),
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
                      initialValue: frequency,
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
                          setDialogState(() => frequency = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Re-schedule / Start Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: startDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 3),
                          ),
                        );
                        if (!dialogContext.mounted) return;
                        if (picked != null) {
                          setDialogState(() => startDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_formatDate(startDate)),
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
                          'End Date (Optional)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        if (endDate != null)
                          IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 16,
                              color: AppTheme.error,
                            ),
                            onPressed: () {
                              setDialogState(() => endDate = null);
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
                          context: dialogContext,
                          initialDate:
                              endDate ?? startDate.add(const Duration(days: 7)),
                          firstDate: startDate,
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 3),
                          ),
                        );
                        if (!dialogContext.mounted) return;
                        if (picked != null) {
                          setDialogState(() => endDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        endDate != null
                            ? _formatDate(endDate!)
                            : 'No End Date selected',
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
                          'Reminders & Notifications',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Switch(
                          value: reminder,
                          onChanged: (val) {
                            setDialogState(() => reminder = val);
                          },
                          activeThumbColor: AppTheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final nameText = nameController.text.trim();
                    if (nameText.isNotEmpty) {
                      final finalDoseStr =
                          '${doseAmountController.text.trim()} $doseUnit'
                              .trim();

                      final updatedMed = item.copyWith(
                        name: nameText,
                        dose: finalDoseStr,
                        frequency: frequency,
                        startDate: startDate,
                        endDate: endDate,
                        remindersEnabled: reminder,
                      );

                      final updatedMeds = _pet.medications
                          .map((m) => m.id == item.id ? updatedMed : m)
                          .toList();
                      final updatedPet = _pet.copyWith(
                        medications: updatedMeds,
                      );
                      parentContext.read<PetBloc>().add(UpdatePet(updatedPet));
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddMedicationDialog(BuildContext context) {
    final parentContext = context;
    final nameController = TextEditingController();
    final doseAmountController = TextEditingController(text: '1');
    String doseUnit = 'Tablet';
    String frequency = 'Every 24h';
    DateTime startDate = DateTime.now();
    DateTime? endDate;
    bool reminder = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Add Medication',
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
                    // 1. Medication Name
                    const Text(
                      'Medication Name',
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

                    // 2. Dose: text input + Unit (tablet, mg, ml, other)
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
                              DropdownMenuItem(value: 'mg', child: Text('mg')),
                              DropdownMenuItem(value: 'ml', child: Text('ml')),
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

                    // 3. Frequency
                    const Text(
                      'Frequency',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: frequency,
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
                          setDialogState(() => frequency = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // 4. Start date
                    const Text(
                      'Start Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: startDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 3),
                          ),
                        );
                        if (!dialogContext.mounted) return;
                        if (picked != null) {
                          setDialogState(() => startDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_formatDate(startDate)),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 5. End date (optional)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'End Date (Optional)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        if (endDate != null)
                          IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 16,
                              color: AppTheme.error,
                            ),
                            onPressed: () {
                              setDialogState(() => endDate = null);
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
                          context: dialogContext,
                          initialDate:
                              endDate ?? startDate.add(const Duration(days: 7)),
                          firstDate: startDate,
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 3),
                          ),
                        );
                        if (!dialogContext.mounted) return;
                        if (picked != null) {
                          setDialogState(() => endDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        endDate != null
                            ? _formatDate(endDate!)
                            : 'No End Date selected',
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 6. Reminder (Notifications) on/off
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reminders & Notifications',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Notify when dose is due',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: reminder,
                          onChanged: (val) {
                            setDialogState(() => reminder = val);
                          },
                          activeThumbColor: AppTheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final medName = nameController.text.trim();
                    if (medName.isNotEmpty) {
                      final doseAmountText =
                          doseAmountController.text.trim().isNotEmpty
                          ? doseAmountController.text.trim()
                          : '1';
                      final finalDoseStr = '$doseAmountText $doseUnit';

                      DateTime calculatedNext = startDate;
                      if (frequency == 'Every 8h') {
                        calculatedNext = startDate.add(
                          const Duration(hours: 8),
                        );
                      } else if (frequency == 'Every 12h') {
                        calculatedNext = startDate.add(
                          const Duration(hours: 12),
                        );
                      } else if (frequency == 'Every 24h') {
                        calculatedNext = startDate.add(const Duration(days: 1));
                      } else if (frequency == 'Weekly') {
                        calculatedNext = startDate.add(const Duration(days: 7));
                      } else if (frequency == 'Monthly') {
                        calculatedNext = startDate.add(
                          const Duration(days: 30),
                        );
                      }

                      final newMed = Medication(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: medName,
                        dose: finalDoseStr,
                        frequency: frequency,
                        startDate: startDate,
                        endDate: endDate,
                        nextDoseDate: calculatedNext,
                        administeredDate: startDate,
                        type: frequency == 'One-time'
                            ? 'as_needed'
                            : 'heartworm',
                        remindersEnabled: reminder,
                        hasStartTime: false,
                      );

                      final updatedMeds = List<Medication>.from(
                        _pet.medications,
                      )..add(newMed);
                      final updatedPet = _pet.copyWith(
                        medications: updatedMeds,
                      );
                      parentContext.read<PetBloc>().add(UpdatePet(updatedPet));
                      Navigator.of(dialogContext).pop();
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

  void _showAddVaccineDialog(BuildContext context) {
    final parentContext = context;
    final nameController = TextEditingController();
    final manufacturerController = TextEditingController();
    final batchController = TextEditingController();
    final customDoseController = TextEditingController();
    String dateType = 'Administered'; // 'Administered' or 'Scheduled'
    DateTime selectedDate = DateTime.now();

    final predefinedVaccines = [
      'Rabies',
      'Leptospirosis',
      'Bordetella',
      'DHPP',
      'FVRCP',
      'Other',
    ];
    String selectedVaccine = 'Rabies';

    final predefinedDoses = [
      '1st Dose',
      'Booster / Reinforcement',
      'Annual',
      'Other',
    ];
    String selectedDoseNumber = '1st Dose';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final isOtherVaccine = selectedVaccine == 'Other';
            final isOtherDose = selectedDoseNumber == 'Other';

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Add Vaccine',
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
                    // 1. Name
                    const Text(
                      'Vaccine Name',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: selectedVaccine,
                      items: predefinedVaccines
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedVaccine = val);
                        }
                      },
                    ),
                    if (isOtherVaccine) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter vaccine name...',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // 2. Manufacturer / Laboratory (Optional)
                    const Text(
                      'Manufacturer / Laboratory (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: manufacturerController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Zoetis, Merck, Boehringer',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. Batch Number (Optional)
                    const Text(
                      'Batch Number (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: batchController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. B-987654',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 4. Number of Dose (1st, reinforcement, annual, etc)
                    const Text(
                      'Dose Number / Type',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDoseNumber,
                      items: predefinedDoses
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedDoseNumber = val);
                        }
                      },
                    ),
                    if (isOtherDose) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: customDoseController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 2nd Dose, Booster #2...',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Date Mode Selection
                    const Text(
                      'Date Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text(
                            'Administered',
                            style: TextStyle(fontSize: 11),
                          ),
                          selected: dateType == 'Administered',
                          selectedColor: AppTheme.primaryFixed,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                dateType = 'Administered';
                                selectedDate = DateTime.now();
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text(
                            'Schedule Date',
                            style: TextStyle(fontSize: 11),
                          ),
                          selected: dateType == 'Scheduled',
                          selectedColor: AppTheme.primaryFixed,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                dateType = 'Scheduled';
                                selectedDate = DateTime.now().add(
                                  const Duration(days: 7),
                                );
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Date Picker Button
                    Text(
                      dateType == 'Administered'
                          ? 'Administration Date'
                          : 'Schedule Date',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDate,
                          firstDate: dateType == 'Administered'
                              ? DateTime.now().subtract(
                                  const Duration(days: 365 * 10),
                                )
                              : DateTime.now(),
                          lastDate: dateType == 'Administered'
                              ? DateTime.now()
                              : DateTime.now().add(
                                  const Duration(days: 365 * 3),
                                ),
                        );
                        if (!dialogContext.mounted) return;
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_formatDate(selectedDate)),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final vaccineName = isOtherVaccine
                        ? nameController.text.trim()
                        : selectedVaccine;
                    final doseLabel = isOtherDose
                        ? customDoseController.text.trim()
                        : selectedDoseNumber;

                    if (vaccineName.isNotEmpty) {
                      final mfrText = manufacturerController.text.trim();
                      final batchText = batchController.text.trim();

                      String lotInfo = '';
                      if (mfrText.isNotEmpty && batchText.isNotEmpty) {
                        lotInfo = '$mfrText (#$batchText)';
                      } else if (batchText.isNotEmpty) {
                        lotInfo = '#$batchText';
                      } else if (mfrText.isNotEmpty) {
                        lotInfo = mfrText;
                      }

                      final isAlreadyAdministered = dateType == 'Administered';

                      final newVaccine = Medication(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: vaccineName,
                        dose: doseLabel.isNotEmpty ? doseLabel : '1st Dose',
                        frequency: doseLabel.isNotEmpty ? doseLabel : 'Annual',
                        startDate: selectedDate,
                        nextDoseDate: isAlreadyAdministered
                            ? selectedDate.add(const Duration(days: 365))
                            : selectedDate,
                        administeredDate: isAlreadyAdministered
                            ? selectedDate
                            : null,
                        type: 'vaccine',
                        lotNumber: lotInfo,
                        isCompleted: isAlreadyAdministered,
                        remindersEnabled: true,
                        hasStartTime: false,
                      );

                      final updatedMeds = List<Medication>.from(
                        _pet.medications,
                      )..add(newVaccine);
                      final updatedPet = _pet.copyWith(
                        medications: updatedMeds,
                      );
                      parentContext.read<PetBloc>().add(UpdatePet(updatedPet));
                      Navigator.of(dialogContext).pop();
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

  // Keep: new_element
  void _showAddOptionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add New Entry',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddMedicationDialog(context);
                      },
                      icon: const Icon(Icons.medication),
                      label: const Text('+ Medication'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryFixed,
                        foregroundColor: AppTheme.onPrimaryFixedVariant,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddVaccineDialog(context);
                      },
                      icon: const Icon(Icons.vaccines),
                      label: const Text('+ Vaccine'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
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

        final activeMeds =
            _pet.medications.where((m) => m.type != 'vaccine').toList()
              ..sort((a, b) => a.nextDoseDate.compareTo(b.nextDoseDate));

        final vaccines =
            _pet.medications
                .where((m) => m.type == 'vaccine' && !m.isSavedToHistory)
                .toList()
              ..sort((a, b) {
                final dateA = a.administeredDate ?? a.nextDoseDate;
                final dateB = b.administeredDate ?? b.nextDoseDate;
                return dateA.compareTo(dateB);
              });

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
                icon: const Icon(
                  Icons.notifications_none,
                  color: AppTheme.primary,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new alerts')),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_isFabExpanded) ...[
                FloatingActionButton.extended(
                  heroTag: 'fab_medication',
                  onPressed: () {
                    setState(() => _isFabExpanded = false);
                    _showAddMedicationDialog(context);
                  },
                  backgroundColor: AppTheme.primaryFixed,
                  foregroundColor: AppTheme.onPrimaryFixedVariant,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  icon: const Icon(Icons.medication),
                  label: const Text('+ Medication'),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'fab_vaccine',
                  onPressed: () {
                    setState(() => _isFabExpanded = false);
                    _showAddVaccineDialog(context);
                  },
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  icon: const Icon(Icons.vaccines),
                  label: const Text('+ Vaccine'),
                ),
                const SizedBox(height: 12),
              ],
              FloatingActionButton(
                heroTag: 'fab_main',
                onPressed: () {
                  setState(() => _isFabExpanded = !_isFabExpanded);
                },
                backgroundColor: AppTheme.tertiary,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(_isFabExpanded ? Icons.close : Icons.add_moderator),
              ),
            ],
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    med.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
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
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    if (med.dosesToday >= med.maxDosesToday) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'All daily doses for ${med.name} completed for today!',
                                          ),
                                          backgroundColor: AppTheme.primary,
                                        ),
                                      );
                                      return;
                                    }

                                    final newDosesToday = (med.dosesToday + 1)
                                        .clamp(0, med.maxDosesToday);
                                    final updatedMed = med.copyWith(
                                      dosesAdministeredToday: newDosesToday,
                                      administeredDate: DateTime.now(),
                                    );
                                    final updatedMeds = _pet.medications
                                        .map(
                                          (m) =>
                                              m.id == med.id ? updatedMed : m,
                                        )
                                        .toList();
                                    final updatedPet = _pet.copyWith(
                                      medications: updatedMeds,
                                    );
                                    context.read<PetBloc>().add(
                                      UpdatePet(updatedPet),
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${med.name} dose administered ($newDosesToday/${med.maxDosesToday})',
                                        ),
                                        backgroundColor: AppTheme.primary,
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    med.dosesToday >= med.maxDosesToday
                                        ? Icons.check_circle
                                        : Icons.medication_liquid,
                                    size: 16,
                                  ),
                                  label: Text(
                                    med.dosesToday >= med.maxDosesToday
                                        ? 'Daily dose completed (${med.maxDosesToday}/${med.maxDosesToday})'
                                        : 'Administrate daily dose(s) (${med.dosesToday}/${med.maxDosesToday})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        med.dosesToday >= med.maxDosesToday
                                        ? AppTheme.secondary
                                        : AppTheme.primary,
                                    side: BorderSide(
                                      color: med.dosesToday >= med.maxDosesToday
                                          ? AppTheme.outlineVariant
                                          : AppTheme.primary,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(
                                height: 1,
                                color: AppTheme.surfaceContainer,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Period: ${_formatDate(med.startDate ?? med.nextDoseDate)} - ${med.endDate != null ? _formatDate(med.endDate!) : 'Ongoing'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.secondary,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () =>
                                            _showEditRecordDialog(context, med),
                                        child: const Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () => _showDeleteConfirmDialog(
                                          context,
                                          med,
                                        ),
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

                // Vaccine Cards List
                if (vaccines.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
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
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: vaccines.length,
                    itemBuilder: (context, index) {
                      final v = vaccines[index];
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

                      final accentColor = statusText;

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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    v.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          statusIcon,
                                          size: 12,
                                          color: statusText,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusLabel,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: statusText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    isCompleted
                                        ? Icons.event_available
                                        : Icons.event,
                                    size: 16,
                                    color: AppTheme.secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      isCompleted
                                          ? 'Date Given: ${v.administeredDate != null ? _formatDate(v.administeredDate!) : _formatDate(v.nextDoseDate)}'
                                          : 'Schedule Date: ${_formatDate(v.nextDoseDate)}',
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
                                    Icons.qr_code_2,
                                    size: 16,
                                    color: AppTheme.secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Lot / Batch #: ${v.lotNumber.isNotEmpty ? v.lotNumber : 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.secondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (isCompleted) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      final alreadySaved = v.isSavedToHistory;
                                      if (!alreadySaved) {
                                        final updatedMed = v.copyWith(
                                          isSavedToHistory: true,
                                        );
                                        final updatedMeds = _pet.medications
                                            .map(
                                              (m) =>
                                                  m.id == v.id ? updatedMed : m,
                                            )
                                            .toList();
                                        final updatedPet = _pet.copyWith(
                                          medications: updatedMeds,
                                        );
                                        context.read<PetBloc>().add(
                                          UpdatePet(updatedPet),
                                        );
                                      }

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            alreadySaved
                                                ? '${v.name} is in Vaccination History'
                                                : '${v.name} saved to Vaccination History',
                                          ),
                                          backgroundColor: AppTheme.primary,
                                        ),
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              MedicalHistoryScreen(pet: _pet),
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      v.isSavedToHistory
                                          ? Icons.bookmark_added
                                          : Icons.bookmark_add_outlined,
                                      size: 16,
                                    ),
                                    label: Text(
                                      v.isSavedToHistory
                                          ? 'View in Vaccination History'
                                          : 'Save to Vaccination History',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: v.isSavedToHistory
                                          ? AppTheme.secondary
                                          : AppTheme.primary,
                                      side: BorderSide(
                                        color: v.isSavedToHistory
                                            ? AppTheme.outlineVariant
                                            : AppTheme.primary,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              const Divider(
                                height: 1,
                                color: AppTheme.surfaceContainer,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        _showEditRecordDialog(context, v),
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () =>
                                        _showDeleteConfirmDialog(context, v),
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
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }
}
