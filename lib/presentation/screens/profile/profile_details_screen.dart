import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../theme/app_theme.dart';

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

  String _completePhoneNumber = '';

  late final List<Country> _sanitizedCountries = () {
    final list = countries.where((c) => c.code != 'IT').toList();
    list.add(
      const Country(
        name: "Italy",
        nameTranslations: {"en": "Italy", "it": "Italia", "es": "Italia"},
        flag: "🇮🇹",
        code: "IT",
        dialCode: "39",
        minLength: 9,
        maxLength: 10,
      ),
    );
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
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

    if (!mounted) return;
    setState(() {
      if (phone != null && phone.isNotEmpty) {
        _phoneController.text = phone;
        _completePhoneNumber = phone;
      }
      if (emergency != null && emergency.isNotEmpty) {
        _emergencyController.text = emergency;
      }
      if (address != null && address.isNotEmpty) {
        _addressController.text = address;
      }
    });
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
    final phoneToSave = _completePhoneNumber.isNotEmpty
        ? _completePhoneNumber
        : _phoneController.text.trim();
    await prefs.setString(_phoneKey, phoneToSave);
    await prefs.setString(_emergencyKey, _emergencyController.text.trim());
    await prefs.setString(_addressKey, _addressController.text.trim());

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

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
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
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Avatar Header
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: AppTheme.primaryContainer,
                        backgroundImage: const NetworkImage(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuBVmzVQ6tXgL8wUyrhW01rg5PG8buMnmSCeWMY5Q1uxZFHHOCyaK3SQnW91Iju-_SLGZ-9CuaIGrS3Hk-0dnEQhbAOyfT_wpUfVn74Vd1plaCxaNvuu9qBmlt-96BkGXCYnXvaT9O2WnRIPn90-pPE4vXP9wnRt5UXGlwTyTOLwu7B9LrGZG0-mAunb-B-ZZJshFbabnpKyiLiXFpU7uyIJoqkJJSOLAL60eu-0kC_dKa2bZG8rLZkb_qUQkB8WkVKomI0nv9xMm4o',
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
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Change photo tapped'),
                                  ),
                                );
                              },
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
                const SizedBox(height: 28),

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

                      // Full Name
                      _buildDetailField(
                        label: 'Full Name',
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
                        icon: Icons.lock_outline,
                        enabled: false,
                        isDark: isDark,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 16),

                      // Phone Number with IntlPhoneField (Country Flag Picker)
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
                            countries: _sanitizedCountries,
                            initialCountryCode: 'IT',
                            onChanged: (phone) {
                              _completePhoneNumber = phone.completeNumber;
                            },
                            dropdownIconPosition: IconPosition.trailing,
                            dropdownTextStyle: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: textPrimary,
                            ),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: '320 123 4567',
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
                        hintText: 'Vet Phone',
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
                        hintText: 'Location',
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
