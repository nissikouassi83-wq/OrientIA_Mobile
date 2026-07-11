import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _api = ApiClient();
  int _step = 0;
  bool _saving = false;
  final Map<int, String> _answers = {};

  static const _categories = [
    'Environnement de travail',
    'Intérêts professionnels',
    'Style de travail',
    'Compétences clés',
    'Objectifs de carrière',
  ];

  static const _questions = [
    {
      'cat': 0,
      'q': 'Dans quel environnement te sens-tu le plus à l\'aise ?',
      'options': [
        {'icon': '🔧', 'text': 'Travailler avec mes mains, construire, réparer'},
        {'icon': '🔬', 'text': 'Analyser, chercher, résoudre des problèmes complexes'},
        {'icon': '🎨', 'text': 'Créer, imaginer, innover librement'},
        {'icon': '👥', 'text': 'Aider, enseigner, accompagner les autres'},
      ],
    },
    {
      'cat': 1,
      'q': 'Quel type d\'activité te motive le plus au quotidien ?',
      'options': [
        {'icon': '💻', 'text': 'Travailler sur des outils et machines'},
        {'icon': '📊', 'text': 'Analyser des données et faire des recherches'},
        {'icon': '🎭', 'text': 'Créer du contenu artistique ou culturel'},
        {'icon': '🤝', 'text': 'Diriger ou convaincre des personnes'},
      ],
    },
    {
      'cat': 2,
      'q': 'Comment préfères-tu organiser ton travail ?',
      'options': [
        {'icon': '📋', 'text': 'Suivre des procédures et règles établies'},
        {'icon': '🔍', 'text': 'Explorer et tester de nouvelles approches'},
        {'icon': '🎯', 'text': 'Fixer mes propres objectifs et méthodes'},
        {'icon': '💬', 'text': 'Collaborer et échanger en équipe'},
      ],
    },
    {
      'cat': 3,
      'q': 'Quelle est ta principale force professionnelle ?',
      'options': [
        {'icon': '⚙️', 'text': 'La précision et le sens du détail'},
        {'icon': '🧠', 'text': 'L\'analyse et la résolution de problèmes'},
        {'icon': '✨', 'text': 'La créativité et l\'innovation'},
        {'icon': '🗣️', 'text': 'La communication et l\'empathie'},
      ],
    },
    {
      'cat': 4,
      'q': 'Quel est ton objectif de carrière principal ?',
      'options': [
        {'icon': '🏗️', 'text': 'Construire ou créer des choses concrètes'},
        {'icon': '📈', 'text': 'Découvrir et innover dans un domaine'},
        {'icon': '🎪', 'text': 'M\'exprimer et influencer la culture'},
        {'icon': '🌟', 'text': 'Avoir un impact social positif'},
      ],
    },
  ];

  void _select(String opt) => setState(() => _answers[_step] = opt);

  void _next() {
    if (_step < _questions.length - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await _api.updateProfile({'riasec_answers': _answers.values.toList()});
    } catch (_) {}
    if (mounted) {
      setState(() => _saving = false);
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final q        = _questions[_step];
    final catIdx   = q['cat'] as int;
    final catLabel = _categories[catIdx];
    final opts     = (q['options'] as List).cast<Map<String, dynamic>>();
    final total    = _questions.length;
    final pct      = ((_step + 1) / total * 100).toInt();
    final selected = _answers[_step];
    final hasAnswer = selected != null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [

          // ── AppBar custom ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: _step > 0
                  ? () => setState(() => _step--)
                  : () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20)),
                child: const Text('NOUVEAU',
                  style: TextStyle(color: AppColors.violet, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text('${_step + 1} / $total',
                style: const TextStyle(color: AppColors.muted, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.line)),
                  child: const Icon(Icons.close, color: AppColors.muted, size: 16)),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Titre + info ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Test de personnalité professionnelle',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('$total questions · ~8 minutes',
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 14),

          // ── Progress bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              ClipRRect(borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (_step + 1) / total,
                  minHeight: 6,
                  backgroundColor: AppColors.line,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent))),
              const SizedBox(height: 6),
              Row(children: [
                Text('Question ${_step + 1} sur $total',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                const Spacer(),
                Text('$pct%',
                  style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Question + options ─────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Catégorie badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      child: Center(child: Text('${_step + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))),
                    const SizedBox(width: 8),
                    Text(catLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                  ]),
                ),
                const SizedBox(height: 16),

                // Question
                Text(q['q'] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.4)),
                const SizedBox(height: 20),

                // Options
                ...opts.map((opt) {
                  final isSelected = selected == opt['text'];
                  return GestureDetector(
                    onTap: () => _select(opt['text'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                          ? AppColors.accent.withValues(alpha: 0.1)
                          : AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : AppColors.line,
                          width: isSelected ? 1.5 : 1)),
                      child: Row(children: [
                        Text(opt['icon'] as String, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 14),
                        Expanded(child: Text(opt['text'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.muted,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
                        if (isSelected)
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                            child: const Icon(Icons.check, color: Colors.white, size: 13)),
                      ]),
                    ),
                  );
                }),

                const SizedBox(height: 16),
                // Temps estimé
                Row(children: [
                  const Icon(Icons.access_time, color: AppColors.muted, size: 14),
                  const SizedBox(width: 6),
                  const Text('Temps estimé restant · ~5 min',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(width: 10),
                  ...List.generate(10, (i) => Container(
                    width: 8, height: 8, margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      color: i <= _step ? AppColors.accent : AppColors.line,
                      shape: BoxShape.circle))),
                ]),
                const SizedBox(height: 80),
              ]),
            ),
          ),

          // ── Bouton Suivant ─────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 12),
            child: GestureDetector(
              onTap: hasAnswer && !_saving ? _next : null,
              child: Container(
                width: double.infinity, height: 54,
                decoration: BoxDecoration(
                  color: hasAnswer ? AppColors.accent : AppColors.line,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: hasAnswer ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))] : null),
                child: Center(child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_step < total - 1 ? 'Suivant' : 'Terminer',
                        style: TextStyle(
                          color: hasAnswer ? Colors.white : AppColors.muted,
                          fontSize: 16, fontWeight: FontWeight.bold)),
                      if (hasAnswer) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward, color: hasAnswer ? Colors.white : AppColors.muted, size: 18),
                      ],
                    ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
