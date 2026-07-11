import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class RoadmapPage extends StatefulWidget {
  const RoadmapPage({super.key});
  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage> {
  final _api = ApiClient();
  Map<String, dynamic>? _plan;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.getCareerPlan();
      if (mounted) setState(() { _plan = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final obj = (_plan?['objectif_principal'] as Map?) ?? {};
    final steps = (_plan?['etapes'] as List?) ?? _fallbackSteps;
    final titre = (obj['titre'] as String?) ?? 'Data Analyst Senior — Orange CI';
    final mois  = (obj['mois_restants'] as num?)?.toInt() ?? 18;
    final prog  = (obj['progression'] as num?)?.toDouble() ?? 68.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mon plan de carrière',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          Text('Suivi personnalisé · Mis à jour aujourd\'hui',
            style: TextStyle(color: AppColors.muted, fontSize: 11)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.muted),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
        : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Objectif principal
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20)),
                  child: const Text('OBJECTIF PRINCIPAL',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Text(titre,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Progression vers l\'objectif',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 6),
                    ClipRRect(borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: prog / 100,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        minHeight: 5)),
                  ])),
                  const SizedBox(width: 16),
                  Column(children: [
                    Text('${prog.toInt()}%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('→ ${(obj['score_objectif'] as num?)?.toInt() ?? 90}%',
                      style: const TextStyle(color: Colors.white60, fontSize: 11)),
                  ]),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10)),
                    child: Column(children: [
                      Text('$mois',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      const Text('mois', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    ]),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 24),

            const Text('Étapes du plan',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Timeline
            ...List.generate(steps.length, (i) => _TimelineStep(
              step: steps[i] as Map<String, dynamic>,
              isLast: i == steps.length - 1,
            )),
          ]),
        ),

      bottomNavigationBar: Container(
        color: AppColors.bg,
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent),
            color: AppColors.accent.withValues(alpha: 0.08)),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Ajouter une étape',
              style: TextStyle(color: AppColors.accent, fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }

  static const _fallbackSteps = [
    {'label': 'Analyser mon profil initial', 'status': 'done', 'detail': 'Complétée · 15 janv. 2026', 'progress': 1.0},
    {'label': 'Formation SQL Avancé', 'status': 'current', 'detail': 'En cours · 2/4 semaines', 'progress': 0.5, 'badge': 'EN COURS'},
    {'label': 'Certification Power BI', 'status': 'upcoming', 'detail': 'À venir · 1 mois', 'progress': 0.0},
    {'label': 'Stage ou projet Data', 'status': 'upcoming', 'detail': 'À planifier · 2–3 mois', 'progress': 0.0},
    {'label': 'Candidature Data Analyst', 'status': 'goal', 'detail': 'Objectif final · Janvier 2027', 'progress': 0.0, 'badge': 'OBJECTIF'},
  ];
}

class _TimelineStep extends StatelessWidget {
  final Map<String, dynamic> step;
  final bool isLast;
  const _TimelineStep({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final status   = step['status'] as String? ?? 'upcoming';
    final label    = step['label'] as String? ?? '';
    final detail   = step['detail'] as String? ?? '';
    final progress = (step['progress'] as num?)?.toDouble() ?? 0.0;
    final badge    = step['badge'] as String?;

    final Color lineColor;
    final Color iconBg;
    final IconData icon;

    switch (status) {
      case 'done':
        lineColor = AppColors.green;
        iconBg    = AppColors.green;
        icon      = Icons.check;
      case 'current':
        lineColor = AppColors.accent;
        iconBg    = AppColors.accent;
        icon      = Icons.description_outlined;
      case 'goal':
        lineColor = AppColors.accent;
        iconBg    = AppColors.accent.withValues(alpha: 0.15);
        icon      = Icons.flag_outlined;
      default:
        lineColor = AppColors.line;
        iconBg    = AppColors.card;
        icon      = Icons.radio_button_unchecked;
    }

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle,
              border: Border.all(color: lineColor,
                width: status == 'upcoming' || status == 'goal' ? 1.5 : 0)),
            child: Icon(icon,
              color: status == 'done' || status == 'current' ? Colors.white : lineColor,
              size: 18)),
          if (!isLast)
            Expanded(child: Container(
              width: 2,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: lineColor, borderRadius: BorderRadius.circular(1)))),
        ]),
        const SizedBox(width: 16),

        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(label,
                  style: TextStyle(
                    color: status == 'upcoming' ? AppColors.muted : Colors.white,
                    fontWeight: FontWeight.w600, fontSize: 14))),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (status == 'goal' ? AppColors.accent : AppColors.green).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6)),
                    child: Text(badge,
                      style: TextStyle(
                        color: status == 'goal' ? AppColors.accent : AppColors.green,
                        fontSize: 10, fontWeight: FontWeight.bold))),
                ],
                if (status == 'done')
                  const Icon(Icons.check_circle, color: AppColors.green, size: 18),
              ]),
              const SizedBox(height: 4),
              Text(detail, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              if (progress > 0 && progress < 1) ...[
                const SizedBox(height: 8),
                Text('${(progress * 100).toInt()}%',
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress, minHeight: 5,
                    backgroundColor: AppColors.line,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent))),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}
