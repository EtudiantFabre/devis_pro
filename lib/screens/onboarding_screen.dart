import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'main_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: const [
                  _OnboardSlide(
                    title: 'Mode Hors Ligne',
                    description: 'Créez et gérez vos devis sans Internet. Vos données restent sur votre appareil.',
                    icon: Icons.offline_bolt,
                  ),
                  _OnboardSlide(
                    title: 'Export PDF & Partage',
                    description: 'Générez des PDF professionnels et partagez-les par email ou messagerie.',
                    icon: Icons.picture_as_pdf,
                  ),
                  _OnboardSlide(
                    title: 'Premium à venir',
                    description: 'Synchronisation cloud, analytics avancées, templates… restez à l\'écoute !',
                    icon: Icons.star,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Passer'),
                  ),
                  const Spacer(),
                  Row(
                    children: List.generate(3, (i) => _Dot(active: i == _index)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      if (_index < 2) {
                        _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                      } else {
                        _finish();
                      }
                    },
                    child: Text(_index < 2 ? 'Suivant' : 'Commencer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardSlide extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  const _OnboardSlide({required this.title, required this.description, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 72, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: active ? 20 : 8,
      decoration: BoxDecoration(
        color: active ? AppTheme.primaryColor : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}


