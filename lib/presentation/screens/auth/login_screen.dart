import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../theme/app_theme.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            final cleanError = state.error.replaceAll('Exception: ', '').trim();
            setState(() {
              _errorMessage = cleanError;
              _isEmailLoading = false;
              _isGoogleLoading = false;
            });
            _showAuthErrorDialog(context, state.error);
          } else if (state is Authenticated || state is Unauthenticated) {
            setState(() {
              _isEmailLoading = false;
              _isGoogleLoading = false;
            });
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Header
                    const Icon(Icons.pets, size: 64, color: AppTheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Paws & Care',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nurturing pet health together.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Email Input
                    Text('Email Address', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
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
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password Input
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Password', style: theme.textTheme.labelLarge),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Login Button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isThisLoading =
                            _isEmailLoading && state is AuthLoading;
                        final isAnyLoading = state is AuthLoading;
                        return ElevatedButton(
                          onPressed: isAnyLoading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() {
                                      _errorMessage = null;
                                      _isEmailLoading = true;
                                      _isGoogleLoading = false;
                                    });
                                    context.read<AuthBloc>().add(
                                      LoginSubmitted(
                                        _emailController.text,
                                        _passwordController.text,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: isThisLoading
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
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Log In',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Google Sign-In Button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isThisLoading =
                            _isGoogleLoading && state is AuthLoading;
                        final isAnyLoading = state is AuthLoading;
                        return OutlinedButton(
                          onPressed: isAnyLoading
                              ? null
                              : () {
                                  setState(() {
                                    _errorMessage = null;
                                    _isGoogleLoading = true;
                                    _isEmailLoading = false;
                                  });
                                  context.read<AuthBloc>().add(
                                    GoogleLoginSubmitted(),
                                  );
                                },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: AppTheme.outlineVariant,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isThisLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      AppTheme.primary,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.network(
                                      'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg.png',
                                      height: 20,
                                      width: 20,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.g_mobiledata,
                                                color: AppTheme.primary,
                                                size: 24,
                                              ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Log In with Google',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                        );
                      },
                    ),

                    // Inline Error Banner below buttons
                    if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppTheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: AppTheme.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _errorMessage = null;
                                });
                              },
                              child: const Icon(
                                Icons.close_rounded,
                                color: AppTheme.error,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: AppTheme.secondaryContainer),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Not a member yet?',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.secondary,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: AppTheme.secondaryContainer),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Register Redirect Button
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Create Account',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAuthErrorDialog(BuildContext context, String error) {
    final cleanError = error.replaceAll('Exception: ', '').trim();
    final lower = cleanError.toLowerCase();

    final isConnectionError =
        lower.contains('connection refused') || lower.contains('network');
    final isWrongPassword =
        lower.contains('wrong password') ||
        lower.contains('incorrect password') ||
        lower.contains('wrong-password');
    final isUnverified =
        lower.contains('not verified') ||
        lower.contains('account not verified');
    final isAlreadyExists =
        lower.contains('already has an account') ||
        lower.contains('already exists') ||
        lower.contains('email-already-in-use');
    final isNotRegistered =
        !isWrongPassword &&
        !isUnverified &&
        !isConnectionError &&
        !isAlreadyExists;

    String title;
    IconData icon;
    Color iconColor;

    if (isConnectionError) {
      title = 'Connection Refused';
      icon = Icons.wifi_off_rounded;
      iconColor = AppTheme.error;
    } else if (isAlreadyExists) {
      title = 'This Email Already Has An Account';
      icon = Icons.account_circle_rounded;
      iconColor = AppTheme.primary;
    } else if (isUnverified) {
      title = 'Account Not Verified';
      icon = Icons.mark_email_unread_rounded;
      iconColor = Colors.orange;
    } else if (isWrongPassword) {
      title = 'Wrong Password';
      icon = Icons.lock_reset_rounded;
      iconColor = AppTheme.secondary;
    } else {
      title = 'Account Does Not Exist';
      icon = Icons.person_off_rounded;
      iconColor = AppTheme.error;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            cleanError,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            if (isUnverified) ...[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Sending verification email...',
                        ),
                      ),
                    );
                  } catch (_) {}
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Resend Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ] else if (isNotRegistered) ...[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Sign Up Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('OK'),
              ),
            ],
          ],
        );
      },
    );
  }
}
