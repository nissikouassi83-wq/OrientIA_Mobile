import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

// ── Entry point : Splash → Onboarding ────────────────────────────────────────

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  late AnimationController _loadCtrl;
  late Animation<double> _loadAnim;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _loadCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _loadAnim = CurvedAnimation(parent: _loadCtrl, curve: Curves.easeInOut);
    _loadCtrl.forward().then((_) {
      if (mounted) setState(() => _showOnboarding = true);
    });
  }

  @override
  void dispose() {
    _loadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) return const _OnboardingFlow();
    return _SplashScreen(progress: _loadAnim);
  }
}

// ── Splash ────────────────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  final Animation<double> progress;
  const _SplashScreen({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const Spacer(flex: 3),
          // Logo
          Center(
            child: Column(
              children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.45), blurRadius: 32)],
                  ),
                  child: const Icon(Icons.psychology, color: Colors.white, size: 52),
                ),
                const SizedBox(height: 22),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(text: 'Orient', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                      TextSpan(text: 'IA',     style: TextStyle(color: AppColors.accent, fontSize: 36, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Ton avenir commence ici', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text("Trouve ton métier idéal avec l'IA", style: TextStyle(color: AppColors.muted, fontSize: 14)),
              ],
            ),
          ),
          const Spacer(flex: 3),
          // Barre de chargement gradient
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AnimatedBuilder(
              animation: progress,
              builder: (_, __) => Stack(
                children: [
                  Container(height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4))),
                  FractionallySizedBox(
                    widthFactor: progress.value,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.accent, AppColors.violet]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Côte d\'Ivoire 🇨🇮', style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Onboarding Flow ───────────────────────────────────────────────────────────

class _OnboardingFlow extends StatefulWidget {
  const _OnboardingFlow();
  @override
  State<_OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<_OnboardingFlow> {
  final _ctrl = PageController();
  int _page = 0;

  void _next(BuildContext context) {
    if (_page < 2) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      context.go('/register');
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          PageView(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _page = i),
            children: const [_Slide1(), _Slide2(), _Slide3()],
          ),
          // Bouton Passer
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: GestureDetector(
              onTap: () => context.go('/register'),
              child: const Text('Passer', style: TextStyle(color: AppColors.muted, fontSize: 15)),
            ),
          ),
          // Dots + bouton bas
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              color: AppColors.bg,
              padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? AppColors.accent : AppColors.line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 20),
                  // Bouton principal
                  if (_page < 2)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => _next(context),
                        child: const Text('Suivant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.accent, AppColors.violet]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ElevatedButton(
                          onPressed: () => context.go('/register'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                          child: const Text('Commencer gratuitement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: const Text('Se connecter', style: TextStyle(color: AppColors.muted, fontSize: 15)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide 1 — Analyse CV ──────────────────────────────────────────────────────

class _Slide1 extends StatelessWidget {
  const _Slide1();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 220),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Illustration CV mock
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 260, height: 180,
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.line)),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle), child: const Icon(Icons.person, color: Colors.white, size: 26)),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(width: 100, height: 10, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(5))),
                        const SizedBox(height: 6),
                        Container(width: 70, height: 8, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4))),
                      ]),
                    ]),
                    const SizedBox(height: 14),
                    Container(width: double.infinity, height: 8, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 6),
                    Container(width: 200, height: 8, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 6),
                    Container(width: 180, height: 8, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 12),
                    Row(children: ['Python','SQL','Excel'].map((s) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                      child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    )).toList()),
                  ],
                ),
              ),
              Positioned(top: -16, right: -20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(20)),
                  child: const Row(children: [Icon(Icons.bolt, color: Colors.white, size: 14), SizedBox(width: 4), Text('Compétences extraites', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))]),
                ),
              ),
              Positioned(bottom: -16, left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.violet, borderRadius: BorderRadius.circular(20)),
                  child: const Row(children: [Icon(Icons.school, color: Colors.white, size: 14), SizedBox(width: 4), Text('Diplôme détecté', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          const Text('Analyse ton CV en\nsecondes', textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.3)),
          const SizedBox(height: 14),
          const Text("Notre IA extrait tes compétences, diplômes et expériences automatiquement.",
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.5)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Slide 2 — Métiers ─────────────────────────────────────────────────────────

class _Slide2 extends StatelessWidget {
  const _Slide2();
  static const _jobs = [
    {'title': 'Data Analyst',       'icon': Icons.analytics,       'pct': '94%', 'color': AppColors.green},
    {'title': 'Chef de projet IT',  'icon': Icons.business_center, 'pct': '88%', 'color': AppColors.accent},
    {'title': 'Dev No-Code',        'icon': Icons.settings,        'pct': '81%', 'color': AppColors.violet},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 220),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Radar mock
          Container(
            width: 160, height: 160,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.line, width: 1)),
            child: CustomPaint(painter: _RadarMockPainter()),
          ),
          const SizedBox(height: 8),
          Text('Data  Finance  Marketing  Design  Droit  Tech',
            style: TextStyle(color: AppColors.muted.withValues(alpha: 0.5), fontSize: 11)),
          const SizedBox(height: 16),
          const Text('Découvre les métiers faits\npour toi', textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.3)),
          const SizedBox(height: 8),
          const Text('Matching vectoriel avec 100+ métiers du marché ivoirien et africain.',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.5)),
          const SizedBox(height: 20),
          ..._jobs.map((j) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
            child: Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: (j['color'] as Color).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(j['icon'] as IconData, color: j['color'] as Color, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(j['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
              Text(j['pct'] as String, style: TextStyle(color: j['color'] as Color, fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _RadarMockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.42;

    final gridPaint = Paint()..color = AppColors.line..style = PaintingStyle.stroke..strokeWidth = 1;
    final fillOrange = Paint()..color = AppColors.accent.withValues(alpha: 0.35)..style = PaintingStyle.fill;
    final strokeOrange = Paint()..color = AppColors.accent..style = PaintingStyle.stroke..strokeWidth = 2;
    final fillViolet = Paint()..color = AppColors.violet.withValues(alpha: 0.25)..style = PaintingStyle.fill;

    // Grid hexagons
    for (final f in [0.33, 0.66, 1.0]) {
      final path = Path();
      for (int i = 0; i < 6; i++) {
        final angle = (i * 60 - 90) * 3.1416 / 180;
        final x = cx + r * f * cos(angle);
        final y = cy + r * f * sin(angle);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Filled areas
    final vals1 = [0.8, 0.6, 0.9, 0.5, 0.7, 0.65];
    final vals2 = [0.5, 0.9, 0.4, 0.8, 0.3, 0.7];
    _drawArea(canvas, cx, cy, r, vals1, fillViolet, null);
    _drawArea(canvas, cx, cy, r, vals2, fillOrange, strokeOrange);
  }

  void _drawArea(Canvas canvas, double cx, double cy, double r, List<double> vals, Paint fill, Paint? stroke) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * 3.1416 / 180;
      final x = cx + r * vals[i] * cos(angle);
      final y = cy + r * vals[i] * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, fill);
    if (stroke != null) canvas.drawPath(path, stroke);
  }

  double cos(double rad) => _cos(rad);
  double sin(double rad) => _sin(rad);

  double _cos(double rad) {
    double r = rad % (2 * 3.1416);
    double x = 1 - r * r / 2 + r * r * r * r / 24;
    return x.clamp(-1.0, 1.0);
  }

  double _sin(double rad) {
    double r = rad % (2 * 3.1416);
    double x = r - r * r * r / 6 + r * r * r * r * r / 120;
    return x.clamp(-1.0, 1.0);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Slide 3 — Coach IA ───────────────────────────────────────────────────────

class _Slide3 extends StatelessWidget {
  const _Slide3();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 260),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Chat preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.line)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                    child: const Icon(Icons.psychology, color: Colors.white, size: 20)),
                  const SizedBox(width: 10),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Coach OrientIA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('● En ligne', style: TextStyle(color: AppColors.green, fontSize: 11)),
                  ]),
                  const Spacer(),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.violet.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Text('XAI', style: TextStyle(color: AppColors.violet, fontSize: 11, fontWeight: FontWeight.bold))),
                ]),
                const SizedBox(height: 12),
                const Text('Bonjour ! Comment puis-je t\'aider aujourd\'hui ?', style: TextStyle(color: Colors.white, fontSize: 13)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
                  child: const Text('Je veux préparer un entretien Data Analyst', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(height: 8),
                const Text('Super ! Voici les 3 points clés pour Orange CI...', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                const SizedBox(height: 8),
                Row(children: List.generate(3, (_) => Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(color: AppColors.muted, shape: BoxShape.circle)))),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('Un coach IA disponible\n24h/24', textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.3)),
          const SizedBox(height: 14),
          const Text("Simule des entretiens, reçois des conseils, prépare ta reconversion.",
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.5)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
