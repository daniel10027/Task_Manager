import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:liquid_swipe/liquid_swipe.dart';

import '../../core/storage/onboarding_prefs.dart';
import '../../theme/app_spacing.dart';
import '../auth/login_screen.dart';

class _OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color background;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.background,
  });
}

const _pages = [
  _OnboardingPage(
    title: 'Organisez tout, simplement',
    description: 'Créez, classez et suivez toutes vos tâches en un seul endroit, avec une interface pensée pour aller vite.',
    icon: Icons.checklist_rounded,
    background: Color(0xFF5B5BF5),
  ),
  _OnboardingPage(
    title: 'Toujours disponible, même hors ligne',
    description: 'Continuez à travailler sans connexion : vos actions se synchronisent automatiquement dès que le réseau revient.',
    icon: Icons.wifi_off_rounded,
    background: Color(0xFF2563EB),
  ),
  _OnboardingPage(
    title: 'Restez concentré sur l\'essentiel',
    description: 'Filtrez par statut, recherchez instantanément, et gardez une vue claire de votre avancement.',
    icon: Icons.rocket_launch_rounded,
    background: Color(0xFF16A34A),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = LiquidController();
  int _page = 0;

  Future<void> _finish() async {
    await OnboardingPrefs.markSeen();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      body: Stack(
        children: [
          LiquidSwipe(
            pages: [for (final page in _pages) _OnboardingPageView(page: page)],
            liquidController: _controller,
            enableLoop: false,
            enableSideReveal: true,
            waveType: WaveType.liquidReveal,
            onPageChangeCallback: (index) => setState(() => _page = index),
          ),
          Positioned(
            top: AppSpacing.lg,
            right: AppSpacing.lg,
            child: SafeArea(
              child: TextButton(
                onPressed: _finish,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Passer'),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.xxl,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: i == _page ? 24 : 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: i == _page ? 1 : 0.5,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child:
                          FilledButton(
                                onPressed: _finish,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: _pages.last.background,
                                ),
                                child: const Text('Commencer'),
                              )
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .scale(
                                begin: const Offset(0.9, 0.9),
                                end: const Offset(1, 1),
                              ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: page.background,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(page.icon, size: 56, color: Colors.white),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1)),
          const SizedBox(height: AppSpacing.xl),
          Text(
                page.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              )
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: AppSpacing.md),
          Text(
                page.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
              )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}
