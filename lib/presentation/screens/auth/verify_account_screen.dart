import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/repository_selector.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../theme/app_theme.dart';
import 'account_verified_screen.dart';

class VerifyAccountScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;

  const VerifyAccountScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen> {
  bool _isCheckingStatus = false;
  bool _isResending = false;
  int _resendCountdown = 30;
  Timer? _timer;
  Timer? _verificationCheckTimer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startAutoVerificationCheck();
  }

  void _startAutoVerificationCheck() {
    _verificationCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkVerificationStatus(silent: true);
    });
  }

  Future<void> _checkVerificationStatus({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isCheckingStatus = true;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;
        if (refreshedUser != null && refreshedUser.emailVerified) {
          _verificationCheckTimer?.cancel();
          if (!mounted) return;
          _navigateToSuccess();
          return;
        }
      }
    } catch (_) {}

    if (!silent && mounted) {
      setState(() {
        _isCheckingStatus = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email not verified yet. Please check your inbox and click the verification link.',
          ),
          backgroundColor: AppTheme.secondary,
        ),
      );
    }
  }

  void _navigateToSuccess() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AccountVerifiedScreen(
          name: widget.name,
          email: widget.email,
          password: widget.password,
        ),
      ),
    );
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
    });

    String statusMessage;
    Color statusColor = AppTheme.primary;

    try {
      final dbSource = await RepositorySelector.getDbSource();
      if (dbSource != 'firebase') {
        statusMessage =
            'App is in MOCK mode. Go to Settings > Database Storage and select "Firebase Firestore Database" to send real emails.';
        statusColor = AppTheme.secondary;
      } else {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.sendEmailVerification();
          statusMessage =
              'Verification email sent to ${widget.email}! Please check your Inbox and Spam folder.';
        } else {
          statusMessage = 'No active Firebase session. Creating session...';
          final repo = await RepositorySelector().getActiveRepository();
          await repo.sendEmailVerification();
          statusMessage =
              'Verification email sent to ${widget.email}! Check Spam/Junk folder.';
        }
      }
    } catch (e) {
      statusMessage = 'Firebase Error: ${e.toString()}';
      statusColor = AppTheme.error;
    }

    _startTimer();

    if (!mounted) return;
    setState(() {
      _isResending = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(statusMessage),
        backgroundColor: statusColor,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  void _startTimer() {
    _resendCountdown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _resendCountdown--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _verificationCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state;
    final textPrimary = isDark ? AppTheme.darkOnSurface : AppTheme.onSurface;
    final textSecondary = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.secondary;
    final primaryColor = isDark ? AppTheme.primaryFixedDim : AppTheme.primary;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Email Badge
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    size: 46,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Verify Your Email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: textSecondary,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                      text: 'We\'ve sent a verification link to\n',
                    ),
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const TextSpan(
                      text:
                          '.\nPlease open your email inbox and click the verification link to activate your account.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Auto-check Live Status Indicator Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(primaryColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Checking verification status automatically...',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Email Delivery Checklist Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurface
                      : AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF383634)
                        : AppTheme.surfaceContainerHighest,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.mark_email_unread_outlined,
                          size: 16,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'HAVEN\'T RECEIVED THE EMAIL?',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildTipItem(
                      '1. Check your Spam / Junk folder.',
                      textSecondary,
                    ),
                    const SizedBox(height: 6),
                    _buildTipItem(
                      '2. Tap "Resend Email" below to request a new link.',
                      textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Primary Action Button
              ElevatedButton.icon(
                onPressed: _isCheckingStatus
                    ? null
                    : () => _checkVerificationStatus(silent: false),
                icon: const Icon(
                  Icons.mark_email_read,
                  color: Colors.white,
                  size: 20,
                ),
                label: _isCheckingStatus
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'I\'ve Verified My Email',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 24),

              // Resend Timer Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t receive the email? ',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: _resendCountdown == 0
                        ? _resendVerificationEmail
                        : null,
                    child: Text(
                      _resendCountdown > 0
                          ? 'Resend in ${_resendCountdown}s'
                          : 'Resend Email',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _resendCountdown == 0
                            ? primaryColor
                            : textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String text, Color textColor) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        color: textColor,
        height: 1.4,
      ),
    );
  }
}
