import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';
import 'package:due/screens/home_screen.dart';

/// Onboarding screen to introduce the app to new users
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < AppConstants.onboardingTitles.length - 1) {
      _pageController.nextPage(
        duration: AppConstants.animationDurationMedium,
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skipOnboarding() {
    _finishOnboarding();
  }

  void _finishOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppConstants.backgroundStart, AppConstants.backgroundEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: AppConstants.onboardingTitles.length,
                  itemBuilder: (context, index) {
                    return _buildOnboardingPage(
                      icon: AppConstants.onboardingIcons[index],
                      title: AppConstants.onboardingTitles[index],
                      description: AppConstants.onboardingDescriptions[index],
                    );
                  },
                ),
              ),
              // Page indicator and navigation
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                child: Column(
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        AppConstants.onboardingTitles.length,
                        (index) => _buildPageIndicator(index == _currentPage),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingL),
                    // Navigation button
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppConstants.primaryColor,
                            AppConstants.secondaryColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusM,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.primaryColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusM,
                            ),
                          ),
                        ),
                        child: Text(
                          _currentPage ==
                                  AppConstants.onboardingTitles.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.8, end: 1.0),
            duration: AppConstants.animationDurationLong,
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.spacingXL),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppConstants.primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryColor.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 80, color: AppConstants.primaryColor),
                ),
              );
            },
          ),
          const SizedBox(height: AppConstants.spacingXL),
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingM),
          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppConstants.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: AppConstants.animationDurationShort,
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingXS),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppConstants.primaryColor : AppConstants.glassBorder,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppConstants.primaryColor.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
    );
  }
}
