import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';

/// Onboarding screen with fun facts carousel
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  static const String _onboardingCompleteKey = 'onboarding_complete';

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  /// Check if user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  /// Mark onboarding as complete
  static Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Triply Stays',
      subtitle: 'Your gateway to Lebanon\'s hidden gems',
      fact: 'Lebanon is home to over 5,000 years of history, with ancient ruins, vibrant cities, and breathtaking coastlines waiting to be explored!',
      emoji: '🇱🇧',
      gradientColors: [Color(0xFFFF9500), Color(0xFFFB8500)],
      imageUrl: 'https://images.unsplash.com/photo-1579606032821-4e6161c81571?w=800',
    ),
    OnboardingPage(
      title: 'Mountain Escapes',
      subtitle: 'From snow-capped peaks to cedar forests',
      fact: 'Did you know? The famous Cedars of God forest is over 6,000 years old and inspired the ancient Phoenicians to build their legendary ships!',
      emoji: '🏔️',
      gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
      imageUrl: 'https://images.unsplash.com/photo-1564769662533-4f00a87b4056?w=800',
    ),
    OnboardingPage(
      title: 'Mediterranean Magic',
      subtitle: 'Crystal clear waters & stunning beaches',
      fact: 'Lebanon\'s coastline stretches 225 km along the Mediterranean, with secret coves, beach clubs, and ancient fishing villages!',
      emoji: '🏖️',
      gradientColors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
    ),
    OnboardingPage(
      title: 'Authentic Experiences',
      subtitle: 'Stay with locals, live like a local',
      fact: 'Lebanese hospitality is legendary! From homemade breakfast spreads to insider tips, our hosts make every stay unforgettable.',
      emoji: '🏡',
      gradientColors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800',
    ),
    OnboardingPage(
      title: 'Ready to Explore?',
      subtitle: 'Your perfect stay is just a tap away',
      fact: 'Join thousands of travelers who\'ve discovered Lebanon\'s best-kept secrets through Triply Stays!',
      emoji: '🦊',
      gradientColors: [Color(0xFFFF6B00), Color(0xFFFB8500)],
      imageUrl: null, // Will use fox logo
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < _pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    await OnboardingScreen.markOnboardingComplete();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page View
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return _buildPage(_pages[index], index == _pages.length - 1);
            },
          ),

          // Skip button (top right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: _currentPage < _pages.length - 1
                ? TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Page indicators and navigation (bottom)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Page indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => GestureDetector(
                      onTap: () => _goToPage(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Back button
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _goToPage(_currentPage - 1),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else
                        const Expanded(child: SizedBox()),

                      const SizedBox(width: 16),

                      // Next/Get Started button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _currentPage < _pages.length - 1
                              ? () => _goToPage(_currentPage + 1)
                              : _completeOnboarding,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _pages[_currentPage].gradientColors[0],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
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
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, bool isLastPage) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: page.gradientColors,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Image or emoji
              Expanded(
                flex: 3,
                child: Center(
                  child: isLastPage
                      ? _buildFoxLogo()
                      : _buildImageCard(page),
                ),
              ),

              // Content
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Emoji
                    Text(
                      page.emoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      page.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      page.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Fun fact card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '💡',
                            style: TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              page.fact,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.95),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Space for buttons
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(OnboardingPage page) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: page.imageUrl != null
            ? Image.network(
                page.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.white.withOpacity(0.1),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white.withOpacity(0.1),
                    child: Center(
                      child: Text(
                        page.emoji,
                        style: const TextStyle(fontSize: 80),
                      ),
                    ),
                  );
                },
              )
            : Container(
                color: Colors.white.withOpacity(0.1),
                child: Center(
                  child: Text(
                    page.emoji,
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFoxLogo() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Image.asset(
            'assets/images/logo/fox-icon.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// Data class for onboarding pages
class OnboardingPage {
  final String title;
  final String subtitle;
  final String fact;
  final String emoji;
  final List<Color> gradientColors;
  final String? imageUrl;

  const OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.fact,
    required this.emoji,
    required this.gradientColors,
    this.imageUrl,
  });
}
