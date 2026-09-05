import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:flutter/services.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../../data/repositories/firebase_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/photo_source_bottom_sheet.dart';
import '../../../core/services/local_media_service.dart';

class ProfileDetailsScreen extends StatefulWidget {
  final String name;
  final String email;

  const ProfileDetailsScreen({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  static const String _phoneKey = 'pawsncare_user_phone';
  static const String _emergencyKey = 'pawsncare_user_emergency';
  static const String _addressKey = 'pawsncare_user_address';
  static const String _avatarKey = 'pawsncare_user_avatar_path';

  String? _avatarPath;
  String _userCode = '';

  late final List<Country> _verifiedCountries = () {
    return countries.map((c) {
      if (c.code == 'IT') {
        return const Country(
          name: "Italy",
          nameTranslations: {"en": "Italy", "it": "Italia", "es": "Italia"},
          flag: "🇮🇹",
          code: "IT",
          dialCode: "39",
          minLength: 9,
          maxLength: 10,
        );
      }
      if (c.code == 'CH') {
        return const Country(
          name: "Switzerland",
          nameTranslations: {"en": "Switzerland"},
          flag: "🇨🇭",
          code: "CH",
          dialCode: "41",
          minLength: 9,
          maxLength: 12,
        );
      }
      return c;
    }).toList();
  }();

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _emergencyController;
  late TextEditingController _addressController;

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController();
    _emergencyController = TextEditingController();
    _addressController = TextEditingController();
    _loadExtraProfileData();
  }

  Future<void> _loadExtraProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(_phoneKey);
    final emergency = prefs.getString(_emergencyKey);
    final address = prefs.getString(_addressKey);
    final avatar = prefs.getString(_avatarKey);
    String userCode = '10000001';
    try {
      userCode = await FirebaseRepository().getCurrentUserCode();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _userCode = userCode;
      if (avatar != null && avatar.isNotEmpty) {
        _avatarPath = avatar;
      }
      if (phone != null && phone.isNotEmpty) {
        _phoneController.text = phone;
      }
      if (emergency != null && emergency.isNotEmpty) {
        _emergencyController.text = emergency;
      }
      if (address != null && address.isNotEmpty) {
        _addressController.text = address;
      }
    });
  }

  Future<void> _pickAvatarPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _avatarPath = picked.path;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_avatarKey, picked.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
    }
  }

  Future<void> _showPhotoSourceModal() async {
    final source = await PhotoSourceBottomSheet.show(
      context,
      title: 'Update Profile Photo',
    );
    if (source != null) {
      _pickAvatarPhoto(source);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final newName = _nameController.text.trim();
    context.read<AuthBloc>().add(UserNameUpdated(newName));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneKey, _phoneController.text.trim());
    await prefs.setString(_emergencyKey, _emergencyController.text.trim());
    await prefs.setString(_addressKey, _addressController.text.trim());
    if (_avatarPath != null && _avatarPath!.isNotEmpty) {
      await prefs.setString(_avatarKey, _avatarPath!);
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Personal profile updated successfully!'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  Future<bool> _showUnsavedChangesDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkOnSurface : AppTheme.onSurface;
    final textSecondary = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.secondary;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.error,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Unsaved Changes',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'You have unsaved changes in your personal profile. If you leave now, your progress will be lost.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Keep Editing',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: AppTheme.secondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Discard & Leave',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state;
    final textPrimary = isDark ? AppTheme.darkOnSurface : AppTheme.onSurface;
    final textSecondary = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.secondary;
    final cardBg = isDark
        ? AppTheme.darkSurface
        : AppTheme.surfaceContainerLowest;
    final primaryColor = isDark ? AppTheme.primaryFixedDim : AppTheme.primary;

    return PopScope(
      canPop: !_isEditing,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _showUnsavedChangesDialog();
        if (shouldLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: primaryColor),
            onPressed: () async {
              if (_isEditing) {
                final shouldLeave = await _showUnsavedChangesDialog();
                if (shouldLeave && context.mounted) {
                  Navigator.of(context).pop();
                }
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            'Personal Profile',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: textPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isEditing ? Icons.close : Icons.edit,
                color: primaryColor,
              ),
              onPressed: () async {
                if (_isEditing) {
                  final shouldLeave = await _showUnsavedChangesDialog();
                  if (shouldLeave) {
                    setState(() {
                      _isEditing = false;
                      _loadExtraProfileData();
                    });
                  }
                } else {
                  setState(() {
                    _isEditing = true;
                  });
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Avatar Header
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _isEditing ? _showPhotoSourceModal : null,
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: AppTheme.primaryContainer,
                            backgroundImage: LocalMediaService.resolveImageProvider(
                              _avatarPath,
                              fallbackAsset: 'assets/avatars/dog.png',
                            ),
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppTheme.primary,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                onPressed: _showPhotoSourceModal,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nameController.text,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _emailController.text,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                  if (_userCode.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _userCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Personal User Code copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryFixed,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.key_rounded,
                              size: 14,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Code: $_userCode',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: AppTheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Personal Details Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PERSONAL DETAILS',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.0,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Alias
                        _buildDetailField(
                          label: 'Alias',
                          controller: _nameController,
                          icon: Icons.person_outline,
                          enabled: _isEditing,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email Address (Account Sign-In)
                        _buildDetailField(
                          label: 'Email Address (Account Sign-In)',
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          enabled: false,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 16),

                        // Phone Number with Country Flag & Code Picker
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phone Number',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            IntlPhoneField(
                              controller: _phoneController,
                              enabled: _isEditing,
                              countries: _verifiedCountries,
                              initialCountryCode: 'US',
                              dropdownIconPosition: IconPosition.trailing,
                              dropdownTextStyle: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Phone Number',
                                hintStyle: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: textSecondary.withValues(alpha: 0.5),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? AppTheme.darkBackground
                                    : AppTheme.surfaceContainerLow,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF383634)
                                        : AppTheme.outlineVariant,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF383634)
                                        : AppTheme.outlineVariant,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primary,
                                    width: 2,
                                  ),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Emergency Contact
                        _buildDetailField(
                          label: 'Emergency Vet / Contact',
                          controller: _emergencyController,
                          icon: Icons.contact_phone_outlined,
                          hintText: 'Vet Phone / Name',
                          enabled: _isEditing,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 16),

                        // Address / Location
                        _buildDetailField(
                          label: 'Address / Location',
                          controller: _addressController,
                          icon: Icons.location_on_outlined,
                          hintText: 'Street, City, State/Province, Country',
                          enabled: _isEditing,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Changes Button (Visible when editing)
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: textSecondary.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
            filled: true,
            fillColor: isDark
                ? AppTheme.darkBackground
                : AppTheme.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF383634)
                    : AppTheme.outlineVariant,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
