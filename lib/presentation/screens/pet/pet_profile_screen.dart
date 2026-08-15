import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../logic/diary/diary_bloc.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/weight_log.dart';
import '../../../data/models/medication.dart';
import '../../../data/models/diary_entry.dart';
import '../../theme/app_theme.dart';

class PetProfileScreen extends StatefulWidget {
  final Pet pet;
  const PetProfileScreen({super.key, required this.pet});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Pet _pet;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pet = widget.pet;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddWeightDialog() {
    final weightController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log New Weight'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Weight (kg)',
                  prefixIcon: Icon(Icons.monitor_weight),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  hintText: 'Notes (e.g. Vet check, morning)',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final weightValue = double.tryParse(weightController.text);
                if (weightValue == null) return;

                final newLog = WeightLog(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  weight: weightValue,
                  date: DateTime.now(),
                  note: noteController.text.isEmpty
                      ? 'At Home'
                      : noteController.text,
                );

                final updatedHistory = List<WeightLog>.from(_pet.weightHistory)
                  ..insert(0, newLog);
                final updatedPet = _pet.copyWith(
                  weight: weightValue,
                  weightHistory: updatedHistory,
                );

                context.read<PetBloc>().add(UpdatePet(updatedPet));
                setState(() {
                  _pet = updatedPet;
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              child: const Text(
                'Save Log',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleMedication(Medication med) {
    final updatedMeds = _pet.medications.map((m) {
      if (m.id == med.id) {
        return Medication(
          id: m.id,
          name: m.name,
          nextDoseDate: m.nextDoseDate.add(const Duration(days: 30)),
          administeredDate: DateTime.now(),
          isCompleted: true,
          type: m.type,
        );
      }
      return m;
    }).toList();

    final updatedPet = _pet.copyWith(medications: updatedMeds);
    context.read<PetBloc>().add(UpdatePet(updatedPet));
    setState(() {
      _pet = updatedPet;
    });

    // Log to diary as well
    final diaryEntry = DiaryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      petId: _pet.id,
      title: 'Med Administered: ${med.name}',
      category: 'med',
      note: 'Dose marked completed.',
      timestamp: DateTime.now(),
    );
    context.read<DiaryBloc>().add(AddDiaryEntryEvent(diaryEntry));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Administered: ${med.name}'),
        backgroundColor: AppTheme.primary,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_pet.name}\'s Profile',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
            onPressed: () {
              // Confirm deletion dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Pet Profile?'),
                  content: Text(
                    'Are you sure you want to delete ${_pet.name}? This will clear all health and diary histories.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.read<PetBloc>().add(DeletePet(_pet.id));
                        Navigator.pop(context);
                        Navigator.pop(context); // Go back to dashboard
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Hero Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Stack(
                children: [
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: _pet.avatarUrl.startsWith('http')
                          ? Image.network(_pet.avatarUrl, fit: BoxFit.cover)
                          : Container(
                              color: AppTheme.primaryContainer,
                              child: const Icon(Icons.pets, size: 64),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _pet.name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_pet.breed} • ${_pet.ageString}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
            const SizedBox(height: 20),

            // Quick Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildStatCard('Age', _pet.ageString, Icons.cake),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Weight',
                    '${_pet.weight} kg',
                    Icons.monitor_weight,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Status',
                    _pet.status,
                    Icons.health_and_safety,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Photos Gallery
            const Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Photos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _pet.photos.length + 1,
                itemBuilder: (context, index) {
                  if (index == _pet.photos.length) {
                    return _buildAddPhotoButton(context);
                  }
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        _pet.photos[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Tabs navigation
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(
                4,
              ), // creates the gap around the white pill
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer, // light grey track
                borderRadius: BorderRadius.circular(999),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.zero,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                labelColor: AppTheme.primary, // green text for selected tab
                unselectedLabelColor:
                    AppTheme.onSurface, // dark grey/black for unselected
                labelStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                dividerColor: Colors.transparent, // removes default underline
                overlayColor: WidgetStateProperty.all(
                  Colors.transparent,
                ), // no ripple
                tabs: const [
                  Tab(text: 'Diary'),
                  Tab(text: 'Weight'),
                  Tab(text: 'Meds'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab View Body (bounded height)
            SizedBox(
              height: 400,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Diary logs of this specific pet
                  _buildDiaryTab(),
                  // Tab 2: Weight chart and logs
                  _buildWeightTab(),
                  // Tab 3: Medications status
                  _buildMedsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.primaryFixed.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaryTab() {
    return BlocBuilder<DiaryBloc, DiaryState>(
      builder: (context, state) {
        if (state is DiaryLoaded) {
          final petEntries = state.entries
              .where((e) => e.petId == _pet.id)
              .toList();
          if (petEntries.isEmpty) {
            return const Center(
              child: Text('No activity logs recorded for this pet.'),
            );
          }

          return ListView.builder(
            itemCount: petEntries.length,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemBuilder: (context, index) {
              final entry = petEntries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.primaryFixed,
                    child: Icon(Icons.notes, color: AppTheme.primary, size: 20),
                  ),
                  title: Text(
                    entry.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(entry.note),
                  trailing: Text(
                    '${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month - 1];
  }

  Widget _buildWeightTab() {
    final history = _pet.weightHistory;

    // Calculate last 6 months (oldest to newest)
    final now = DateTime.now();
    final last6Months = List.generate(6, (i) {
      return DateTime(now.year, now.month - (5 - i), 1);
    });

    // Group logs by month and average them
    final averages = last6Months.map((m) {
      final logs = history.where((log) =>
        log.date.year == m.year && log.date.month == m.month
      ).toList();
      if (logs.isEmpty) {
        return null;
      }
      final sum = logs.fold<double>(0.0, (val, log) => val + log.weight);
      return sum / logs.length;
    }).toList();

    // Scale calculation
    double finalMinW = 0.0;
    double finalMaxW = 10.0;
    double? foundMin;
    double? foundMax;
    for (final avg in averages) {
      if (avg != null) {
        if (foundMin == null || avg < foundMin) foundMin = avg;
        if (foundMax == null || avg > foundMax) foundMax = avg;
      }
    }

    if (foundMin != null && foundMax != null) {
      if (foundMin == foundMax) {
        finalMinW = foundMin - 1.0;
        finalMaxW = foundMax + 1.0;
      } else {
        final diff = foundMax - foundMin;
        finalMinW = foundMin - diff * 0.15;
        finalMaxW = foundMax + diff * 0.15;
        if (finalMinW < 0) finalMinW = 0.0;
      }
    }

    // Trend badge calculation
    String trendText = 'No data';
    bool showTrend = false;
    double trendDiff = 0.0;

    int latestDataIdx = -1;
    int prevDataIdx = -1;
    for (int i = 5; i >= 0; i--) {
      if (averages[i] != null) {
        if (latestDataIdx == -1) {
          latestDataIdx = i;
        } else if (prevDataIdx == -1) {
          prevDataIdx = i;
          break;
        }
      }
    }

    if (latestDataIdx != -1 && prevDataIdx != -1) {
      final w1 = averages[latestDataIdx]!;
      final w2 = averages[prevDataIdx]!;
      trendDiff = w1 - w2;
      final prefix = trendDiff >= 0 ? '+' : '';
      trendText = '$prefix${trendDiff.toStringAsFixed(1)}kg this month';
      showTrend = true;
    } else if (latestDataIdx != -1) {
      trendText = '0.0kg this month';
      showTrend = true;
    }

    final double chartMinW = finalMinW;
    final double chartMaxW = finalMaxW;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          // Weight trend card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.surfaceContainerLow),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: history.isEmpty
                ? const SizedBox(
                    height: 220,
                    child: Center(
                      child: Text(
                        'No weight logs recorded yet.',
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Weight\nTrend',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Last 6 months monitoring',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.secondary,
                                ),
                              ),
                            ],
                          ),
                          if (showTrend)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              decoration: BoxDecoration(
                                color: trendDiff >= 0
                                    ? const Color(0xFFE2F5E9)
                                    : const Color(0xFFFDE8E8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                trendText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: trendDiff >= 0
                                      ? const Color(0xFF386B52)
                                      : const Color(0xFF9B1C1C),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Graph area
                      SizedBox(
                        height: 150,
                        child: Stack(
                          children: [
                            // Horizontal grid lines
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(4, (index) => Container(
                                height: 1,
                                color: AppTheme.surfaceContainerLow,
                              )),
                            ),
                            // Bars and labels
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(6, (idx) {
                                    final m = last6Months[idx];
                                    final avg = averages[idx];
                                    final monthLabel = _getMonthName(m.month);
                                    final isLatestMonth = idx == 5;

                                    Widget barWidget;
                                    Widget weightTextWidget;

                                    if (avg != null) {
                                      final factor = (chartMinW == chartMaxW) ? 0.5 : (avg - chartMinW) / (chartMaxW - chartMinW);
                                      final clampedFactor = factor.clamp(0.0, 1.0);
                                      const double plotHeight = 90.0;
                                      final double barHeight = plotHeight * (0.15 + 0.7 * clampedFactor);

                                      weightTextWidget = Text(
                                        avg.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isLatestMonth ? FontWeight.bold : FontWeight.w500,
                                          color: isLatestMonth ? AppTheme.primary : AppTheme.secondary,
                                        ),
                                      );

                                      barWidget = SizedBox(
                                        height: 98,
                                        child: Stack(
                                          alignment: Alignment.bottomCenter,
                                          clipBehavior: Clip.none,
                                          children: [
                                            // Vertical line bar
                                            Container(
                                              width: isLatestMonth ? 5 : 3,
                                              height: barHeight,
                                              decoration: BoxDecoration(
                                                color: isLatestMonth
                                                    ? AppTheme.primary
                                                    : AppTheme.primary.withOpacity(0.4),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                            ),
                                            // Circular dot marker
                                            Positioned(
                                              bottom: barHeight - 4,
                                              child: Container(
                                                width: isLatestMonth ? 10 : 8,
                                                height: isLatestMonth ? 10 : 8,
                                                decoration: BoxDecoration(
                                                  color: isLatestMonth
                                                      ? AppTheme.primary
                                                      : AppTheme.primary.withOpacity(0.8),
                                                  shape: BoxShape.circle,
                                                  border: isLatestMonth
                                                      ? Border.all(
                                                          color: AppTheme.primary.withOpacity(0.2),
                                                          width: 3,
                                                          strokeAlign: BorderSide.strokeAlignOutside,
                                                        )
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      weightTextWidget = const Text(
                                        'N/A',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.secondary,
                                        ),
                                      );
                                      barWidget = const SizedBox(
                                        height: 98,
                                      );
                                    }

                                    return Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          weightTextWidget,
                                          const SizedBox(height: 6),
                                          barWidget,
                                          const SizedBox(height: 8),
                                          Text(
                                            monthLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isLatestMonth ? FontWeight.bold : FontWeight.w500,
                                              color: isLatestMonth ? AppTheme.onSurface : AppTheme.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weight History Logs',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              ElevatedButton.icon(
                onPressed: _showAddWeightDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Log', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Weight Logs List
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final log = history[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${log.date.day}/${log.date.month}/${log.date.year} - ${log.note}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${log.weight} kg',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedsTab() {
    final meds = _pet.medications;
    if (meds.isEmpty) {
      return const Center(
        child: Text('No medications or vaccine logs set up.'),
      );
    }

    return ListView.builder(
      itemCount: meds.length,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (context, index) {
        final med = meds[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.secondaryContainer,
              child: Icon(
                med.type == 'vaccine' ? Icons.vaccines : Icons.bug_report,
                color: AppTheme.secondary,
              ),
            ),
            title: Text(
              med.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Next due: ${med.nextDoseDate.day}/${med.nextDoseDate.month}/${med.nextDoseDate.year}',
            ),
            trailing: TextButton(
              onPressed: () => _toggleMedication(med),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              child: const Text('Administer'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddPhotoButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddPhotoDialog(context),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_a_photo_outlined, color: AppTheme.primary, size: 28),
            SizedBox(height: 6),
            Text(
              'Add Photo',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPhotoDialog(BuildContext context) {
    final urlController = TextEditingController(
      text:
          'https://lh3.googleusercontent.com/aida/AP1WRLtrgME_RmIjbhaKotM3yFpCT7DU6U1PWGClNijvL1udZ-MwwSE4sRJXIkOpdXG_cQrlHdzVHWgOScO25q_9O5XS5IYrq9YpSPzMMCfFUgQin2wChhfacReYAlFZmlABvz70D9BrOoYsd_UfBK1v2te37yMvk_LKQM0nfhOK_Smz_StRBkZ7xC7Mw-AfJwUe6IrQBGllmI1NtCd5O0NUnlXVtaS0dVA9d1RpHUon7HaYl-S_cZT-vjk0XIE',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Add New Photo',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Photo URL',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  hintText: 'Image network address',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newUrl = urlController.text.trim();
                if (newUrl.isNotEmpty) {
                  final updatedPhotos = List<String>.from(_pet.photos)
                    ..add(newUrl);
                  final updatedPet = _pet.copyWith(photos: updatedPhotos);
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
  }
}
