import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/repository_selector.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../theme/app_theme.dart';
import 'verify_account_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  // Real-time validations
  bool _hasLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _passwordsMatch = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    if (!_isFormValid || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = await RepositorySelector().getActiveRepository();
      await repo.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifyAccountScreen(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      var errorMsg = e.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
      if (errorMsg.contains('email-already-in-use') ||
          errorMsg.toLowerCase().contains('email already')) {
        errorMsg = 'This email already has an account.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _validatePassword() {
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    setState(() {
      _hasLength = pass.length >= 8;
      _hasUppercase = pass.contains(RegExp(r'[A-Z]'));
      _hasNumber = pass.contains(RegExp(r'[0-9]'));
      _passwordsMatch = pass.isNotEmpty && pass == confirm;
    });
  }

  bool get _isFormValid {
    return _hasLength &&
        _hasUppercase &&
        _hasNumber &&
        _passwordsMatch &&
        _agreedToTerms &&
        _nameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty;
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Terms & Privacy'),
          content: const SingleChildScrollView(
            child: Text(
              'By using Paws & Care, you are agreeing to our standards of care and data protection. We ensure your pet\'s information remains secure and is used solely to improve their health journey.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _agreedToTerms = true;
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              child: const Text('Agree', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            // Dismiss screens to dashboard
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (state is AuthFailure) {
            var rawStr = state.error.replaceAll(RegExp(r'^Exception:\s*'), '');
            if (rawStr.contains('email-already-in-use') ||
                rawStr.toLowerCase().contains('email already')) {
              rawStr = 'This email already has an account.';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(rawStr),
                backgroundColor: AppTheme.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Join Paws & Care',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start managing your pet\'s health with professional ease and warmth.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name Input
                  Text('Full Name', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'John Doe',
                      prefixIcon: Icon(Icons.person, color: AppTheme.secondary),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Input
                  Text('Email Address', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'name@example.com',
                      prefixIcon: Icon(
                        Icons.alternate_email,
                        color: AppTheme.secondary,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password fields in a row on desktop/tablet, column on mobile
                  Text('Password', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: AppTheme.secondary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppTheme.secondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Confirm Password', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(
                        Icons.verified_user,
                        color: AppTheme.secondary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppTheme.secondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Requirements Checklist Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.surfaceContainerHighest,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password requirements:',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildRequirementItem('8+ characters', _hasLength),
                        const SizedBox(height: 4),
                        _buildRequirementItem(
                          'One uppercase letter',
                          _hasUppercase,
                        ),
                        const SizedBox(height: 4),
                        _buildRequirementItem('One number', _hasNumber),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Matching Indicator Label
                  if (_confirmPasswordController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        _passwordsMatch
                            ? 'Passwords match'
                            : 'Passwords do not match',
                        style: TextStyle(
                          fontSize: 12,
                          color: _passwordsMatch
                              ? AppTheme.primary
                              : AppTheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Terms Checklist
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          activeColor: AppTheme.primary,
                          onChanged: (val) {
                            setState(() {
                              _agreedToTerms = val ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: _showTermsDialog,
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                              ),
                              children: const [
                                TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Service and Privacy Policy',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit CTA
                  ElevatedButton(
                    onPressed: (_isFormValid && !_isSubmitting)
                        ? _handleCreateAccount
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.primary.withValues(
                        alpha: 0.4,
                      ),
                      disabledForegroundColor: Colors.white.withValues(
                        alpha: 0.8,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Create Account',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: AppTheme.outlineVariant),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'OR',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: AppTheme.outlineVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sign up with Google Button
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(GoogleRegisterSubmitted());
                    },
                    icon: Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg.png',
                      height: 20,
                      width: 20,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.g_mobiledata,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                    label: const Text(
                      'Create with Google',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isMet ? AppTheme.primary : AppTheme.secondary,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isMet ? AppTheme.primary : AppTheme.secondary,
            decoration: isMet ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }
}
