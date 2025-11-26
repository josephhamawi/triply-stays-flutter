import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Social sign in button for Google and Apple authentication
class SocialSignInButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const SocialSignInButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  });

  /// Google sign in button factory
  factory SocialSignInButton.google({
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SocialSignInButton(
      label: 'Continue with Google',
      icon: Image.asset(
        'assets/icons/google.png',
        width: 24,
        height: 24,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.g_mobiledata, size: 24);
        },
      ),
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: Colors.white,
      textColor: AppColors.textPrimary,
      borderColor: AppColors.borderLight,
    );
  }

  /// Apple sign in button factory
  factory SocialSignInButton.apple({
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SocialSignInButton(
      label: 'Continue with Apple',
      icon: const Icon(Icons.apple, size: 24, color: Colors.white),
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: Colors.black,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.white,
          foregroundColor: textColor ?? AppColors.textPrimary,
          side: BorderSide(color: borderColor ?? AppColors.borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? AppColors.textPrimary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Divider with "or" text
class OrDivider extends StatelessWidget {
  final String text;

  const OrDivider({
    super.key,
    this.text = 'or',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.borderLight),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.borderLight),
        ),
      ],
    );
  }
}
