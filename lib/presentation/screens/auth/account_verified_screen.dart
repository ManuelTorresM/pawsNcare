import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../theme/app_theme.dart';
import '../pet/add_pet_wizard.dart';

class AccountVerifiedScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;

  const AccountVerifiedScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  State<AccountVerifiedScreen> createState() => _AccountVerifiedScreenState();
}

class _AccountVerifiedScreenState extends State<AccountVerifiedScreen> {
  bool _shouldLaunchAddPet = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state;
    final textPrimary = isDark ? AppTheme.darkOnSurface : AppTheme.onSurface;
    final textSecondary = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.secondary;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            if (_shouldLaunchAddPet) {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AddPetWizard()));
            }
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 28.0,
              vertical: 24.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                // Success Badge with Double Pulse Circles
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryFixed.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: AppTheme.primary,
                        size: 52,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                Text(
                  'Account Verified!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Congratulations ${widget.name}! Your account has been verified and registered successfully. Welcome to Paws & Care.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
                const Spacer(),

                // Action Buttons
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return Column(
                      children: [
                        // Button 1: Add Your First Pet (Primary CTA)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _shouldLaunchAddPet = true;
                                    });
                                    context.read<AuthBloc>().add(
                                      LoginSubmitted(
                                        widget.email,
                                        widget.password,
                                      ),
                                    );
                                  },
                            icon: isLoading && _shouldLaunchAddPet
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.pets, size: 20),
                            label: Text(
                              isLoading && _shouldLaunchAddPet
                                  ? 'Signing in...'
                                  : 'Add Your First Pet',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Button 2: Go to Dashboard (Secondary CTA)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _shouldLaunchAddPet = false;
                                    });
                                    context.read<AuthBloc>().add(
                                      LoginSubmitted(
                                        widget.email,
                                        widget.password,
                                      ),
                                    );
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(
                                color: AppTheme.primary,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isLoading && !_shouldLaunchAddPet
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        AppTheme.primary,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Go to Dashboard',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
