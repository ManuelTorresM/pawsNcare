import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/accent_left_card.dart';
import '../../../data/models/diary_entry.dart';
import '../../../data/models/medication.dart';

class TestPlaygroundScreen extends StatefulWidget {
  const TestPlaygroundScreen({super.key});

  @override
  State<TestPlaygroundScreen> createState() => _TestPlaygroundScreenState();
}

class _TestPlaygroundScreenState extends State<TestPlaygroundScreen> {
  String _selectedSeverity = 'SEVERE';
  String _selectedMedStatus = 'Active';

  late DiaryEntry _sampleDiaryEntry;
  late Medication _sampleMedication;
  late Medication _sampleVaccine;

  @override
  void initState() {
    super.initState();
    _updateSampleModels();
  }

  void _updateSampleModels() {
    _sampleDiaryEntry = DiaryEntry(
      id: 'test_diary_1',
      petId: 'pet_1',
      title: 'Post-walk Lethargy & Cough',
      note:
          'Pet showed mild discomfort during the morning walk. Refused dry kibble afterwards, but drank plenty of water.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      category: 'vet',
      severity: _selectedSeverity,
    );

    _sampleMedication = Medication(
      id: 'test_med_1',
      name: 'Amoxicillin Antibiotic 250mg',
      dose: '1 Tablet',
      route: 'Oral',
      frequency: 'Every 12 Hours',
      type: _selectedMedStatus == 'PRN' ? 'as_needed' : 'routine',
      nextDoseDate: DateTime.now().add(const Duration(hours: 4)),
      dosesAdministeredToday: _selectedMedStatus == 'Done Today' ? 2 : 1,
      startDate: DateTime.now().subtract(const Duration(days: 3)),
      endDate: DateTime.now().add(const Duration(days: 7)),
    );

    _sampleVaccine = Medication(
      id: 'test_vac_1',
      name: 'Rabies Booster Vaccine',
      dose: '1 ml',
      type: 'vaccine',
      nextDoseDate: DateTime.now().add(const Duration(days: 14)),
      lotNumber: 'RAB-2026-X902',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileBg = isDark
        ? AppTheme.surfaceContainer
        : AppTheme.surfaceContainerLow;
    final textPrimary = isDark ? Colors.white : AppTheme.onSurface;
    final textSecondary = isDark ? Colors.white70 : AppTheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'UI Component Testing Screen',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Controls section
            const Text(
              '🧪 Interactive Test Controls',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceContainer),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Diary Severity Filter:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['NORMAL', 'MILD', 'UNUSUAL', 'CONCERNING', 'EMERGENCY'].map((sev) {
                      final isSel = _selectedSeverity == sev;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(sev),
                          selected: isSel,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedSeverity = sev;
                                _updateSampleModels();
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Medication & Vaccine Status Filter:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Administered', 'Overdue', 'Scheduled', 'Active']
                        .map((st) {
                          final isSel = _selectedMedStatus == st;
                          return ChoiceChip(
                            label: Text(st),
                            selected: isSel,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedMedStatus = st;
                                  _updateSampleModels();
                                });
                              }
                            },
                          );
                        })
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // SECTION 1: DIARY CARD
            Row(
              children: const [
                Icon(Icons.book, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  '1. Diary Record Card',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTestDiaryCard(
              _sampleDiaryEntry,
              isDark,
              tileBg,
              textPrimary,
              textSecondary,
            ),

            const SizedBox(height: 28),

            // SECTION 2: MEDS AND VACCINES CARDS
            Row(
              children: const [
                Icon(Icons.medication, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  '2. Meds & Vaccine Card',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTestMedicationCard(_sampleMedication, isDark, tileBg),
            const SizedBox(height: 12),
            _buildTestVaccineCard(_sampleVaccine, isDark, tileBg),

            const SizedBox(height: 28),

            // SECTION 3: EMPTY ACCENT CARD
            Row(
              children: const [
                Icon(Icons.crop_square, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  '3. Blank / Empty Accent Card Structure',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AccentLeftCard(
              accentColor: AppTheme.primary,
              backgroundColor: tileBg,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Empty Card Tapped!')),
                );
              },
              child: const SizedBox(
                height: 80,
                child: Center(
                  child: Text(
                    'Empty Card Container (Custom Content Placeholder)',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestDiaryCard(
    DiaryEntry entry,
    bool isDark,
    Color tileBg,
    Color textPrimary,
    Color textSecondary,
  ) {
    Color badgeColor;
    Color badgeText;
    switch (entry.severity.toUpperCase()) {
      case 'EMERGENCY':
      case 'SEVERE':
        badgeColor = isDark ? AppTheme.statusOverdueDarkBg : AppTheme.statusOverdueBg;
        badgeText = isDark ? AppTheme.statusOverdueDark : AppTheme.statusOverdue;
        break;
      case 'CONCERNING':
        badgeColor = isDark ? AppTheme.statusConcerningDarkBg : AppTheme.statusConcerningBg;
        badgeText = isDark ? AppTheme.statusConcerningDark : AppTheme.statusConcerning;
        break;
      case 'UNUSUAL':
      case 'MODERATE':
        badgeColor = isDark ? AppTheme.statusScheduledDarkBg : AppTheme.statusScheduledBg;
        badgeText = isDark ? AppTheme.statusScheduledDark : AppTheme.statusScheduled;
        break;
      case 'MILD':
        badgeColor = isDark ? AppTheme.statusMildDarkBg : AppTheme.statusMildBg;
        badgeText = isDark ? AppTheme.statusMildDark : AppTheme.statusMild;
        break;
      case 'NORMAL':
      default:
        badgeColor = isDark ? AppTheme.statusAdministeredDarkBg : AppTheme.statusAdministeredBg;
        badgeText = isDark ? AppTheme.statusAdministeredDark : AppTheme.statusAdministered;
        break;
    }

    return AccentLeftCard(
      accentColor: badgeText,
      backgroundColor: tileBg,
      margin: EdgeInsets.zero,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test Diary Card tapped!')),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Today, 02:30 PM',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Luna',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.severity,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.title,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry.note,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E4E30) : AppTheme.primaryFixed,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_hospital,
                  size: 14,
                  color: isDark
                      ? AppTheme.primaryFixedDim
                      : AppTheme.onPrimaryFixedVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Symptom (Vet Visit)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppTheme.primaryFixedDim
                        : AppTheme.onPrimaryFixedVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestMedicationCard(Medication med, bool isDark, Color tileBg) {
    final isCompletedToday = med.dosesToday >= med.maxDosesToday;

    final String statusLabel;
    final Color badgeBg;
    final Color badgeText;
    final IconData detailIcon;

    if (_selectedMedStatus == 'Administered') {
      statusLabel = 'Administered';
      badgeBg = isDark ? const Color(0xFF1B382B) : const Color(0xFFE6F4EA);
      badgeText = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
      detailIcon = Icons.check_circle;
    } else if (_selectedMedStatus == 'Overdue') {
      statusLabel = 'Overdue 2d';
      badgeBg = isDark ? const Color(0xFF5C2B1D) : const Color(0xFFFDEDEC);
      badgeText = isDark ? const Color(0xFFFFB4A3) : const Color(0xFFE74C3C);
      detailIcon = Icons.warning_amber_rounded;
    } else if (_selectedMedStatus == 'Scheduled') {
      statusLabel = 'Scheduled';
      badgeBg = isDark ? const Color(0xFF523B17) : const Color(0xFFFEF9E7);
      badgeText = isDark ? const Color(0xFFFFD580) : const Color(0xFFF39C12);
      detailIcon = Icons.event;
    } else {
      statusLabel = 'Active';
      badgeBg = isDark ? const Color(0xFF1D3B5C) : const Color(0xFFEBF5FB);
      badgeText = isDark ? const Color(0xFF90CAF9) : const Color(0xFF5D9CEC);
      detailIcon = Icons.medication;
    }

    final accentColor = badgeText;

    return AccentLeftCard(
      accentColor: accentColor,
      backgroundColor: tileBg,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                med.name,
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
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(detailIcon, size: 12, color: badgeText),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeText,
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
              const Icon(Icons.scale, size: 16, color: AppTheme.secondary),
              const SizedBox(width: 6),
              Text(
                'Dosage: ${med.dose} (${med.route})',
                style: const TextStyle(fontSize: 12, color: AppTheme.secondary),
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
              Text(
                'Frequency: ${med.frequency}',
                style: const TextStyle(fontSize: 12, color: AppTheme.secondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Administered dose for ${med.name}')),
                );
              },
              icon: Icon(
                isCompletedToday ? Icons.check_circle : Icons.medication_liquid,
                size: 16,
              ),
              label: Text(
                isCompletedToday
                    ? 'Daily dose completed (${med.maxDosesToday}/${med.maxDosesToday})'
                    : 'Administrate daily dose(s) (${med.dosesToday}/${med.maxDosesToday})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.surfaceContainer),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Period: Aug 15 - Aug 25',
                style: TextStyle(fontSize: 12, color: AppTheme.secondary),
              ),
              Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                  SizedBox(width: 12),
                  Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestVaccineCard(Medication vaccine, bool isDark, Color tileBg) {
    final String statusLabel;
    final Color statusColor;
    final Color statusText;
    final IconData statusIcon;

    if (_selectedMedStatus == 'Administered') {
      statusLabel = 'Administered';
      statusColor = isDark ? const Color(0xFF1B382B) : const Color(0xFFE6F4EA);
      statusText = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
      statusIcon = Icons.check_circle;
    } else if (_selectedMedStatus == 'Overdue') {
      statusLabel = 'Overdue 5d';
      statusColor = isDark ? const Color(0xFF5C2B1D) : const Color(0xFFFDEDEC);
      statusText = isDark ? const Color(0xFFFFB4A3) : const Color(0xFFE74C3C);
      statusIcon = Icons.warning_amber_rounded;
    } else if (_selectedMedStatus == 'Active') {
      statusLabel = 'Active';
      statusColor = isDark ? const Color(0xFF1D3B5C) : const Color(0xFFEBF5FB);
      statusText = isDark ? const Color(0xFF90CAF9) : const Color(0xFF5D9CEC);
      statusIcon = Icons.medication;
    } else {
      statusLabel = 'Scheduled';
      statusColor = isDark ? const Color(0xFF523B17) : const Color(0xFFFEF9E7);
      statusText = isDark ? const Color(0xFFFFD580) : const Color(0xFFF39C12);
      statusIcon = Icons.event;
    }

    return AccentLeftCard(
      accentColor: statusText,
      backgroundColor: tileBg,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                vaccine.name,
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
                    Icon(statusIcon, size: 12, color: statusText),
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
            children: const [
              Icon(Icons.event, size: 16, color: AppTheme.secondary),
              SizedBox(width: 6),
              Text(
                'Schedule Date: Sep 12, 2026',
                style: TextStyle(fontSize: 12, color: AppTheme.secondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.qr_code_2, size: 16, color: AppTheme.secondary),
              const SizedBox(width: 6),
              Text(
                'Lot / Batch #: ${vaccine.lotNumber}',
                style: const TextStyle(fontSize: 12, color: AppTheme.secondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.surfaceContainer),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
              SizedBox(width: 12),
              Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
            ],
          ),
        ],
      ),
    );
  }
}
