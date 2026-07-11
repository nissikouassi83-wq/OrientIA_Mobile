import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class GapAnalysisPage extends StatefulWidget {
  const GapAnalysisPage({super.key});
  @override
  State<GapAnalysisPage> createState() => _GapAnalysisPageState();
}

class _GapAnalysisPageState extends State<GapAnalysisPage> {
  bool _loading = true;

  static const _mockGaps = [
    {
      'skill': 'Power BI',
      'mine': 2, 'required': 4,
      'type': 'critical',
      'course': 'Microsoft Power BI — Coursera',
      'duration': '4 semaines · ~25 000 FCFA',
    },
    {
      'skill': 'SQL Avancé',
      'mine': 3, 'required': 4,
      'type': 'moderate',
      'course': 'SQL pour Data Analysts — LinkedIn Learning',
      'duration': '3 semaines · Gratuit',
    },
    {
      'skill': 'Python',
      'mine': 4, 'required': 4,
      'type': 'ok',
      'course': '',
      'duration': '',
    },
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Gap Analysis',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          Text('Data Analyst',
            style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('IA',
              style: TextStyle(color: AppColors.violet, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Radar Chart ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(children: [
                    SizedBox(
                      height: 220,
                      child: CustomPaint(
                        painter: _RadarPainter(),
                        size: Size.infinite,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _Dot(color: AppColors.accent, label: 'Mon profil'),
                      const SizedBox(width: 24),
                      _Dot(color: const Color(0xFF60A5FA), label: 'Profil cible'),
                    ]),
                  ]),
                ),
                const SizedBox(height: 14),

                // ── Score global ─────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    const Expanded(
                      child: Text('Préparation globale\npour ce métier',
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                    ),
                    const SizedBox(width: 16),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('68%',
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 100,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(
                            value: 0.68,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),

                // ── Titre Gaps ───────────────────────────────────────────
                const Text('Analyse des gaps',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                ..._mockGaps.map((g) => _GapCard(gap: g)),
              ]),
            ),

      // ── Bouton bas ───────────────────────────────────────────────────
      bottomNavigationBar: Container(
        color: AppColors.bg,
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Générer mon plan de formation',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new, color: Colors.white, size: 16),
          ]),
        ),
      ),
    );
  }
}

// ── Dot légende ───────────────────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 12, height: 12,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
  ]);
}

// ── Gap Card ──────────────────────────────────────────────────────────────────

class _GapCard extends StatelessWidget {
  final Map<String, dynamic> gap;
  const _GapCard({required this.gap});

  @override
  Widget build(BuildContext context) {
    final type     = gap['type'] as String;
    final skill    = gap['skill'] as String;
    final mine     = gap['mine'] as int;
    final req      = gap['required'] as int;
    final course   = gap['course'] as String;
    final duration = gap['duration'] as String;

    final Color accent;
    final String badge;
    final IconData icon;

    switch (type) {
      case 'critical':
        accent = AppColors.red;
        badge  = 'GAP CRITIQUE';
        icon   = Icons.cancel_outlined;
      case 'moderate':
        accent = AppColors.accent;
        badge  = 'GAP MODÉRÉ';
        icon   = Icons.warning_amber_outlined;
      default:
        accent = AppColors.green;
        badge  = 'COMPÉTENCE OK';
        icon   = Icons.check_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Titre + badge
          Row(children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(skill,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badge,
                style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 10),

          // Barres niveaux
          Row(children: List.generate(5, (i) => Expanded(
            child: Container(
              height: 7,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: i < mine ? accent : AppColors.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ))),
          const SizedBox(height: 6),
          Row(children: [
            Text('Mon niveau  $mine/5', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            const Spacer(),
            Text('Requis $req/5', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ]),

          if (course.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.play_circle_outline, color: AppColors.muted, size: 15),
              const SizedBox(width: 6),
              Expanded(child: Text(course,
                style: const TextStyle(color: AppColors.muted, fontSize: 12))),
            ]),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 21),
              child: Text(duration,
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            ),
          ],
        ]),
      ),
    );
  }
}

// ── Radar Painter ─────────────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  static const _labels = ['SQL', 'Python', 'Power BI', 'Excel', 'Stats', 'Viz'];
  static const _myVals     = [0.75, 0.85, 0.40, 0.90, 0.50, 0.60];
  static const _targetVals = [0.90, 0.80, 0.70, 0.60, 0.75, 0.85];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = math.min(cx, cy) * 0.72;

    final gridPaint = Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final targetFill = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final targetStroke = Paint()
      ..color = const Color(0xFF60A5FA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final myFill = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    final myStroke = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    double ax(int i, double frac) =>
        cx + r * frac * math.cos((i * 60 - 90) * math.pi / 180);
    double ay(int i, double frac) =>
        cy + r * frac * math.sin((i * 60 - 90) * math.pi / 180);

    // Grilles concentriques
    for (final f in [0.25, 0.5, 0.75, 1.0]) {
      final path = Path();
      for (int i = 0; i < 6; i++) {
        i == 0 ? path.moveTo(ax(i, f), ay(i, f))
               : path.lineTo(ax(i, f), ay(i, f));
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Axes
    for (int i = 0; i < 6; i++) {
      canvas.drawLine(Offset(cx, cy), Offset(ax(i, 1), ay(i, 1)), gridPaint);
    }

    // Profil cible (bleu)
    final tp = Path();
    for (int i = 0; i < 6; i++) {
      i == 0 ? tp.moveTo(ax(i, _targetVals[i]), ay(i, _targetVals[i]))
             : tp.lineTo(ax(i, _targetVals[i]), ay(i, _targetVals[i]));
    }
    tp.close();
    canvas.drawPath(tp, targetFill);
    canvas.drawPath(tp, targetStroke);

    // Mon profil (orange)
    final mp = Path();
    for (int i = 0; i < 6; i++) {
      i == 0 ? mp.moveTo(ax(i, _myVals[i]), ay(i, _myVals[i]))
             : mp.lineTo(ax(i, _myVals[i]), ay(i, _myVals[i]));
    }
    mp.close();
    canvas.drawPath(mp, myFill);
    canvas.drawPath(mp, myStroke);

    // Labels
    final tp2 = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < 6; i++) {
      final lx = cx + (r + 20) * math.cos((i * 60 - 90) * math.pi / 180);
      final ly = cy + (r + 20) * math.sin((i * 60 - 90) * math.pi / 180);
      tp2.text = TextSpan(
        text: _labels[i],
        style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w500),
      );
      tp2.layout();
      tp2.paint(canvas, Offset(lx - tp2.width / 2, ly - tp2.height / 2));
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
