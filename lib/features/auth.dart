import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
export 'account_auth.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../core/premium.dart';
import '../core/motion.dart';
import '../services/app_controller.dart';
import 'widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int page = 0;
  bool finishing = false;
  final name = TextEditingController();
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> finish() async {
    if (finishing) return;
    setState(() => finishing = true);
    final app = ref.read(appProvider);
    await app.setSettings({
      'onboarded': true,
      if (name.text.trim().isNotEmpty) 'name': name.text.trim(),
    });
    if (!mounted) return;
    if (app.error == null) {
      context.go('/welcome');
    } else {
      setState(() => finishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    const titles = [
      'Take Care Today for a Healthier Tomorrow',
      'Smart Reminders',
      'Better Health Every Day',
    ];
    const descriptions = [
      'Daryeel helps you remember your medicines easily.',
      'Get timely alerts and never miss a dose.',
      'Track your progress and build healthy habits.',
    ];
    return Scaffold(
      body: SafeArea(
        child: PageBody(
          key: ValueKey(page),
          children: [
            Row(
              children: [
                const Icon(Icons.spa_rounded, color: careTeal),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Daryeel',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      color: careTeal,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: finishing ? null : finish,
                  child: const LocalizedText('Skip'),
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: DropdownButton<String>(
                value: app.language,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'so', child: Text('Soomaali')),
                  DropdownMenuItem(value: 'ar', child: Text('العربية')),
                ],
                onChanged: finishing
                    ? null
                    : (v) => app.setSettings({'language': v}),
              ),
            ),
            OnboardingArtwork(page: page),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: motionDuration(context, 320),
              child: Column(
                key: ValueKey(page),
                children: [
                  LocalizedText(
                    titles[page],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LocalizedText(
                    descriptions[page],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Semantics(
                  selected: i == page,
                  child: IconButton(
                    tooltip: '${tr(context, 'Page')} ${i + 1}',
                    onPressed: finishing
                        ? null
                        : () => setState(() => page = i),
                    icon: AnimatedContainer(
                      duration: motionDuration(context, 240),
                      width: i == page ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == page ? purple : const Color(0xFFD0C8EC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (page == 2) ...[
              TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: tr(context, 'Your name'),
                ),
              ),
              const SizedBox(height: 14),
            ],
            CareButton(
              positive: page == 2,
              onPressed: finishing
                  ? null
                  : page < 2
                  ? () => setState(() => page++)
                  : finish,
              child: LocalizedText(
                finishing
                    ? 'Saving…'
                    : page < 2
                    ? 'Next'
                    : 'Get Started',
              ),
            ),
            if (app.error != null) LocalizedText(app.error!),
          ],
        ),
      ),
    );
  }
}
