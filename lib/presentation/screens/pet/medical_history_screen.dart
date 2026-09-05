import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/medication.dart';
import '../../theme/app_theme.dart';
import '../../../core/services/local_media_service.dart';
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

  void _showDeleteConfirmDialog(BuildContext context, Medication med) {
    final isDark = context.read<ThemeCubit>().state;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove Vaccine Record?',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove "${med.name}" from official history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedMeds = _pet.medications
                  .where((m) => m.id != med.id)
                  .toList();
              final updatedPet = _pet.copyWith(medications: updatedMeds);
              context.read<PetBloc>().add(UpdatePet(updatedPet));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state;

    return BlocBuilder<PetBloc, PetState>(
      builder: (context, petState) {
        if (petState is PetLoaded) {
          final updatedPet = petState.pets.firstWhere(
            (p) => p.id == _pet.id || p.id == widget.pet.id,
            orElse: () => _pet,
          );
          _pet = updatedPet;
        }

        // Administered vaccines saved in history
        final administeredVaccines =
            _pet.medications
                .where(
                  (m) =>
                      m.type == 'vaccine' &&
                      m.isCompleted == true &&
                      m.isSavedToHistory == true,
                )
                .toList()
              ..sort((a, b) {
                final dateA = a.administeredDate ?? a.nextDoseDate;
                final dateB = b.administeredDate ?? b.nextDoseDate;
                return dateB.compareTo(dateA);
              });

        final latestVaccine = administeredVaccines.isNotEmpty
            ? administeredVaccines.first
            : null;

        return Scaffold(
          backgroundColor: isDark
              ? AppTheme.darkBackground
              : AppTheme.background,
          appBar: AppBar(
            title: const Text(
              'Vaccination History',
              style: TextStyle(
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
              IconButton(
                icon: const Icon(
                  Icons.medical_services_outlined,
                  color: AppTheme.primary,
                ),
                tooltip: 'Manage All Meds',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MedsVaccinesScreen(pet: _pet),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Clinical Veterinary Passport Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [AppTheme.darkSurface, const Color(0xFF2C2A28)]
                          : [AppTheme.primary, const Color(0xFF1E3A8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Pet Avatar with Shield Badge
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                backgroundImage: LocalMediaService.resolveImageProvider(
                                  _pet.avatarUrl,
                                ),
                                child: LocalMediaService.resolveImageProvider(_pet.avatarUrl) == null
                                     ? const Icon(
                                        Icons.pets,
                                        color: Colors.white,
                                        size: 28,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_pet.name}\'s Immunization Passport',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_pet.species} • ${_pet.breed.isNotEmpty ? _pet.breed : "Domestic"}',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'VET RECORD ID: #${_pet.id.substring(0, _pet.id.length > 8 ? 8 : _pet.id.length).toUpperCase()}',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 16),

                      // Passport Stat Badges Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildPassportStatItem(
                              label: 'Applied Vaccines',
                              value: '${administeredVaccines.length}',
                              icon: Icons.health_and_safety_outlined,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: Colors.white24,
                          ),
                          Expanded(
                            child: _buildPassportStatItem(
                              label: 'Last Applied',
                              value: latestVaccine?.administeredDate != null
                                  ? _formatDate(
                                      latestVaccine!.administeredDate!,
                                    )
                                  : (latestVaccine != null
                                        ? _formatDate(
                                            latestVaccine.nextDoseDate,
                                          )
                                        : 'None'),
                              icon: Icons.event_available_outlined,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: Colors.white24,
                          ),
                          Expanded(
                            child: _buildPassportStatItem(
                              label: 'Records',
                              value: 'Verified',
                              icon: Icons.shield_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Section Title
                Text(
                  'Administered Vaccines',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? AppTheme.darkOnSurface : AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Clinical Vaccine Cards List
                if (administeredVaccines.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurface
                          : AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF383634)
                            : AppTheme.surfaceContainer,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.vaccines_outlined,
                          size: 48,
                          color: AppTheme.secondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No administered vaccines recorded',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark
                                ? AppTheme.darkOnSurface
                                : AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Administered vaccine records will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.darkOnSurfaceVariant
                                : AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: administeredVaccines.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final vaccine = administeredVaccines[index];
                      return _buildClinicalVaccineCard(
                        context,
                        vaccine,
                        isDark,
                      );
                    },
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPassportStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildClinicalVaccineCard(
    BuildContext context,
    Medication v,
    bool isDark,
  ) {
    final isCompleted = v.isCompleted && v.isSavedToHistory;
    final isOverdue = v.nextDoseDate.isBefore(DateTime.now()) && !isCompleted;

    final String statusLabel;
    final Color statusBg;
    final Color statusText;
    final IconData statusIcon;

    if (isCompleted) {
      statusLabel = 'ADMINISTERED';
      statusBg = const Color(0xFFD1FAE5);
      statusText = const Color(0xFF065F46);
      statusIcon = Icons.check_circle;
    } else if (isOverdue) {
      statusLabel = 'OVERDUE';
      statusBg = isDark ? const Color(0xFF5C2B1D) : const Color(0xFFFDEDEC);
      statusText = isDark ? const Color(0xFFFFB4A3) : const Color(0xFFE74C3C);
      statusIcon = Icons.error;
    } else {
      statusLabel = 'SCHEDULED';
      statusBg = const Color(0xFFFEF3C7);
      statusText = const Color(0xFF92400E);
      statusIcon = Icons.event;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF383634)
              : AppTheme.surfaceContainerLow,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon + Vaccine Name + Status Pill
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryFixed.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.vaccines,
                    color: AppTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.name,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark
                              ? AppTheme.darkOnSurface
                              : AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          v.dose.isNotEmpty ? v.dose : '1st Dose / Booster',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppTheme.darkOnSurfaceVariant
                                : AppTheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
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
                          fontFamily: 'Inter',
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
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Clinical Details Grid
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MANUFACTURER / BATCH',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.darkOnSurfaceVariant
                              : AppTheme.secondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.science_outlined,
                            size: 14,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              v.lotNumber.isNotEmpty
                                  ? v.lotNumber
                                  : 'Standard Batch',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppTheme.darkOnSurface
                                    : AppTheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.administeredDate != null
                            ? 'DATE GIVEN'
                            : 'SCHEDULED DATE',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.darkOnSurfaceVariant
                              : AppTheme.secondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            v.administeredDate != null
                                ? _formatDate(v.administeredDate!)
                                : _formatDate(v.nextDoseDate),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.darkOnSurface
                                  : AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEXT BOOSTER DUE',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.darkOnSurfaceVariant
                              : AppTheme.secondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.event_repeat,
                            size: 14,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(v.nextDoseDate),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.darkOnSurface
                                  : AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showDeleteConfirmDialog(context, v),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppTheme.error,
                  ),
                  tooltip: 'Remove Record',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
