import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';

/// Glassy Info banner widget for displaying messages
class InfoBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? accentColor;

  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppConstants.primaryColor;

    return GlassContainer(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      borderColor: color.withOpacity(0.3),
      color: color.withOpacity(0.1), // Very subtle tint
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppConstants.textPrimary, // White text for dark mode
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Success banner
class SuccessBanner extends StatelessWidget {
  final String message;

  const SuccessBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return InfoBanner(
      message: message,
      icon: Icons.check_circle_outline,
      accentColor: AppConstants.successColor,
    );
  }
}

/// Warning banner
class WarningBanner extends StatelessWidget {
  final String message;

  const WarningBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return InfoBanner(
      message: message,
      icon: Icons.warning_amber_rounded,
      accentColor: AppConstants.warningColor,
    );
  }
}

/// Error banner
class ErrorBanner extends StatelessWidget {
  final String message;

  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return InfoBanner(
      message: message,
      icon: Icons.error_outline,
      accentColor: AppConstants.errorColor,
    );
  }
}
