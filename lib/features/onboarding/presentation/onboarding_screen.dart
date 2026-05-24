import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final pageController = PageController();
  int currentIndex = 0;

  final pages = const [
    _OnboardingPageData(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Welcome to Budget Home',
      subtitle:
          'Manage your income, expenses, bills, rent, loans, reports and alerts in one professional finance workspace.',
      color: Color(0xFF2563EB),
    ),
    _OnboardingPageData(
      icon: Icons.trending_up_outlined,
      title: 'Start with Income',
      subtitle:
          'Add your salary, business income, rent income, freelance payments or other income sources first.',
      color: Color(0xFF16A34A),
    ),
    _OnboardingPageData(
      icon: Icons.receipt_long_outlined,
      title: 'Track Expenses and Bills',
      subtitle:
          'Record daily expenses and manage bills with due dates, paid status, and reminder alerts.',
      color: Color(0xFFDC2626),
    ),
    _OnboardingPageData(
      icon: Icons.analytics_outlined,
      title: 'Understand Your Reports',
      subtitle:
          'Use reports and alerts to see inflow, expenses, pending payments, net balance and upcoming reminders.',
      color: Color(0xFF7C3AED),
    ),
  ];

  void finishOnboarding() {
    html.window.localStorage['budget_home_onboarding_seen'] = 'true';
    context.go('/app');
  }

  void nextPage() {
    if (currentIndex == pages.length - 1) {
      finishOnboarding();
      return;
    }

    pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void skip() {
    finishOnboarding();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = pages[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF111827),
                      Color(0xFF1E1B4B),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.22),
                      blurRadius: 36,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -80,
                      top: -80,
                      child: _GlowCircle(
                        size: 260,
                        color: page.color,
                      ),
                    ),
                    Positioned(
                      left: -90,
                      bottom: -110,
                      child: _GlowCircle(
                        size: 280,
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 22,
                                backgroundColor: Color(0x22FFFFFF),
                                child: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Budget Home',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: skip,
                                child: const Text(
                                  'Skip',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Expanded(
                            child: PageView.builder(
                              controller: pageController,
                              itemCount: pages.length,
                              onPageChanged: (index) {
                                setState(() {
                                  currentIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return _OnboardingPage(data: pages[index]);
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Row(
                                children: List.generate(
                                  pages.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    margin: const EdgeInsets.only(right: 8),
                                    width: currentIndex == index ? 28 : 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: currentIndex == index
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.28),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: nextPage,
                                icon: Icon(
                                  currentIndex == pages.length - 1
                                      ? Icons.check_circle_outline
                                      : Icons.arrow_forward,
                                ),
                                label: Text(
                                  currentIndex == pages.length - 1
                                      ? 'Start App'
                                      : 'Next',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: page.color,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
  });

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;

        final iconCard = Container(
          width: isWide ? 280 : 220,
          height: isWide ? 280 : 220,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(42),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
          ),
          child: Icon(
            data.icon,
            size: isWide ? 120 : 92,
            color: data.color,
          ),
        );

        final textBlock = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment:
              isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: data.color.withOpacity(0.25)),
              ),
              child: Text(
                'Step-by-step finance setup',
                style: TextStyle(
                  color: data.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              data.title,
              textAlign: isWide ? TextAlign.start : TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              data.subtitle,
              textAlign: isWide ? TextAlign.start : TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: textBlock),
              const SizedBox(width: 30),
              iconCard,
            ],
          );
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconCard,
            const SizedBox(height: 28),
            textBlock,
          ],
        );
      },
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.14),
        ),
      ),
    );
  }
}
