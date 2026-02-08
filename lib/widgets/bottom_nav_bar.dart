import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';

/// Reusable bottom navigation bar widget
class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.backgroundEnd,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                route: '/home',
              ),
              _buildNavItem(
                context: context,
                icon: Icons.school_rounded,
                label: 'Courses',
                index: 1,
                route: '/courses',
              ),
              _buildCenterUploadButton(context),
              _buildNavItem(
                context: context,
                icon: Icons.search_rounded,
                label: 'Resources',
                index: 3,
                route: '/resource-finder',
              ),
              _buildNavItem(
                context: context,
                icon: Icons.settings_rounded,
                label: 'Settings',
                index: 4,
                route: '/settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required String route,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          // Pop until we reach home or the desired route
          Navigator.popUntil(
            context,
            (route) => route.settings.name == '/' || route.isFirst,
          );
          if (route != '/home') {
            Navigator.pushNamed(context, route);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppConstants.primaryColor
                  : AppConstants.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppConstants.primaryColor
                    : AppConstants.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterUploadButton(BuildContext context) {
    final isSelected = currentIndex == 2;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          // Pop to home first, then push upload
          Navigator.popUntil(
            context,
            (route) => route.settings.name == '/' || route.isFirst,
          );
          Navigator.pushNamed(context, '/upload');
        }
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [AppConstants.primaryColor, AppConstants.secondaryColor]
                : [
                    AppConstants.primaryColor.withValues(alpha: 0.7),
                    AppConstants.secondaryColor.withValues(alpha: 0.7),
                  ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppConstants.primaryColor.withValues(alpha: 0.5)
                  : AppConstants.primaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.upload_file_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
