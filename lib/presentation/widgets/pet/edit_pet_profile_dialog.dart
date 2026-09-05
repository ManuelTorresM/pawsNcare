import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/pet.dart';
import '../../theme/app_theme.dart';
import '../base_form_dialog.dart';
import '../photo_source_bottom_sheet.dart';

class EditPetProfileDialog extends StatefulWidget {
  final Pet pet;
  final ValueChanged<Pet> onSave;
  final Widget Function(
    String path, {
    required double width,
    required double height,
    required double iconSize,
  }) buildPetImageWidget;

  const EditPetProfileDialog({
    super.key,
    required this.pet,
    required this.onSave,
    required this.buildPetImageWidget,
  });

  static Future<void> show(
    BuildContext context, {
    required Pet pet,
    required ValueChanged<Pet> onSave,
    required Widget Function(
      String path, {
      required double width,
      required double height,
      required double iconSize,
    }) buildPetImageWidget,
  }) {
    return showDialog(
      context: context,
      builder: (_) => EditPetProfileDialog(
        pet: pet,
        onSave: onSave,
        buildPetImageWidget: buildPetImageWidget,
      ),
    );
  }

  @override
  State<EditPetProfileDialog> createState() => _EditPetProfileDialogState();
}

class _EditPetProfileDialogState extends State<EditPetProfileDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _breedCtrl;
  late String _selectedAvatarUrl;
  late String _selectedGender;
  late String _selectedNeutered;
  late DateTime _selectedBirthDate;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.pet.name);
    _breedCtrl = TextEditingController(text: widget.pet.breed);
    _selectedAvatarUrl = widget.pet.avatarUrl;
    _selectedGender = widget.pet.gender;
    _selectedNeutered = widget.pet.neutered;
    _selectedBirthDate = widget.pet.birthDate;
    _selectedStatus =
        ['HEALTHY', 'CONCERNING', 'EMERGENCY'].contains(widget.pet.status)
            ? widget.pet.status
            : 'HEALTHY';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    super.dispose();
  }

  Widget _buildOptionChip(
    String value,
    IconData? icon,
    String currentValue,
    ValueChanged<String> onChanged,
  ) {
    final isSelected = currentValue.toLowerCase() == value.toLowerCase();
    return OutlinedButton(
      onPressed: () => onChanged(value),
      style: OutlinedButton.styleFrom(
        backgroundColor:
            isSelected ? AppTheme.primary : AppTheme.surfaceContainerLow,
        foregroundColor: isSelected ? Colors.white : AppTheme.secondary,
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceContainer,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.secondary,
              size: 16,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseFormDialog(
      icon: Icons.pets,
      title: 'Edit Companion Profile',
      subtitle: 'Update basic details & photo',
      primaryButtonText: 'Save',
      primaryButtonIcon: Icons.check,
      onPrimaryPressed: () {
        final newName = _nameCtrl.text.trim();
        if (newName.isNotEmpty) {
          final updated = widget.pet.copyWith(
            name: newName,
            avatarUrl: _selectedAvatarUrl,
            breed: _breedCtrl.text.trim(),
            gender: _selectedGender,
            neutered: _selectedNeutered,
            birthDate: _selectedBirthDate,
            status: _selectedStatus,
          );
          widget.onSave(updated);
          Navigator.pop(context);
        }
      },
      children: [
        // Interactive Pet Profile Photo Button
        Center(
          child: GestureDetector(
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final source = await PhotoSourceBottomSheet.show(
                context,
                title: 'Change Pet Photo',
              );
              if (source == null || !mounted) return;
              try {
                final picker = ImagePicker();
                final file = await picker.pickImage(source: source);
                if (file != null && mounted) {
                  setState(() {
                    _selectedAvatarUrl = file.path;
                  });
                }
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Error selecting image: $e')),
                );
              }
            },
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryFixed,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(48),
                    child: widget.buildPetImageWidget(
                      _selectedAvatarUrl,
                      width: 96,
                      height: 96,
                      iconSize: 32,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Pet Name
        const Text(
          'Pet Name',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            hintText: 'e.g. Luna',
            filled: true,
            fillColor: AppTheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Breed
        const Text(
          'Breed',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _breedCtrl,
          decoration: InputDecoration(
            hintText: 'Search or enter breed...',
            filled: true,
            fillColor: AppTheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Gender
        const Text(
          'Gender',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildOptionChip(
                'Male',
                Icons.male,
                _selectedGender,
                (v) => setState(() => _selectedGender = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildOptionChip(
                'Female',
                Icons.female,
                _selectedGender,
                (v) => setState(() => _selectedGender = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Neutered / Spayed
        const Text(
          'Neutered / Spayed',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildOptionChip(
                'Yes',
                null,
                _selectedNeutered,
                (v) => setState(() => _selectedNeutered = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildOptionChip(
                'No',
                null,
                _selectedNeutered,
                (v) => setState(() => _selectedNeutered = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Health Status
        const Text(
          'Health Status',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildOptionChip(
                'HEALTHY',
                Icons.check_circle_outline,
                _selectedStatus,
                (v) => setState(() => _selectedStatus = v),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildOptionChip(
                'CONCERNING',
                Icons.warning_amber_rounded,
                _selectedStatus,
                (v) => setState(() => _selectedStatus = v),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildOptionChip(
                'EMERGENCY',
                Icons.error_outline,
                _selectedStatus,
                (v) => setState(() => _selectedStatus = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Date of Birth
        const Text(
          'Date of Birth',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedBirthDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() => _selectedBirthDate = date);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedBirthDate.day}/${_selectedBirthDate.month}/${_selectedBirthDate.year}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
