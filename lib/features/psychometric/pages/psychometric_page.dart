import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class PsychometricPage extends StatefulWidget {
  const PsychometricPage({super.key});

  @override
  State<PsychometricPage> createState() => _PsychometricPageState();
}

class _PsychometricPageState extends State<PsychometricPage> {
  final _api = ApiClient();

  // 'intro' | 'question' | 'completed' | 'error'
  String _state = 'intro';
  bool _loading = false;
  String? _error;

  String _sessionId = '';
  Map<String, dynamic>? _currentQuestion;
  int _questionNumber = 0;
  int _estimatedRemaining = 20;
  int? _selectedAnswer;
  DateTime? _questionStart;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _results;

  static Map<String, Color> get _dimensionColors => {
    'R': AppColors.accent,
    'I': const Color(0xFF7C3AED),
    'A': const Color(0xFFDB2777),
    'S': AppColors.teal,
    'E': const Color(0xFFD97706),
    'C': AppColors.muted,
  };

  static const _dimensionNames = {
    'R': 'Réaliste',
    'I': 'Investigatif',
    'A': 'Artistique',
    'S': 'Social',
    'E': 'Entrepreneur',
    'C': 'Conventionnel',
  };

  void _onTheme() { if (mounted) setState(() {}); }

  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_onTheme);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onTheme);
    super.dispose();
  }

  Future<void> _start(String type) async {
    setState(() { _loading = true; _error = null; });
    try {
      final session = await _api.startPsychometricSession(type);
      _sessionId = session['session_id'] as String;
      await _loadNextQuestion();
    } catch (e) {
      setState(() { _error = 'Erreur au démarrage. Vérifiez votre connexion.'; _state = 'error'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadNextQuestion() async {
    setState(() { _loading = true; _selectedAnswer = null; _questionStart = DateTime.now(); });
    try {
      final data = await _api.getAdaptiveQuestion(_sessionId);
      if (data['completed'] == true) {
        _profile = data['profile'] as Map<String, dynamic>?;
        await _loadResults();
        setState(() { _state = 'completed'; });
      } else {
        setState(() {
          _currentQuestion = data['question'] as Map<String, dynamic>?;
          _questionNumber = data['question_number'] as int? ?? _questionNumber + 1;
          _estimatedRemaining = data['estimated_remaining'] as int? ?? 10;
          _state = 'question';
        });
      }
    } catch (_) {
      setState(() { _error = 'Erreur de chargement de la question.'; _state = 'error'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit(int answer) async {
    if (_currentQuestion == null) return;
    setState(() => _loading = true);
    try {
      final elapsed = _questionStart != null
          ? DateTime.now().difference(_questionStart!).inMilliseconds / 1000.0
          : 5.0;
      await _api.submitPsychometricResponse(
        sessionId: _sessionId,
        questionId: _currentQuestion!['id'] as int,
        value: answer,
        responseTime: elapsed,
      );
      await _loadNextQuestion();
    } catch (_) {
      setState(() { _error = 'Erreur de soumission.'; _state = 'error'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadResults() async {
    try {
      _results = await _api.getPsychometricProfile();
    } catch (_) {}
  }

  Color _dimColor(String? dim) => _dimensionColors[dim] ?? AppColors.muted;
  String _dimName(String? dim) => _dimensionNames[dim] ?? (dim ?? '');

  double get _progress => _estimatedRemaining + _questionNumber == 0
      ? 0
      : _questionNumber / (_questionNumber + _estimatedRemaining);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF7C3AED), AppColors.accent]),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.4), blurRadius: 8)],
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          const Text('Test RIASEC+'),
        ]),
        leading: _state == 'question'
            ? IconButton(
                icon: Icon(Icons.close),
                onPressed: () => setState(() => _state = 'intro'),
              )
            : null,
      ),
      body: switch (_state) {
        'intro' => _IntroScreen(loading: _loading, onStart: _start),
        'question' => _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : _QuestionScreen(
                question: _currentQuestion,
                questionNumber: _questionNumber,
                estimatedRemaining: _estimatedRemaining,
                progress: _progress,
                selectedAnswer: _selectedAnswer,
                onSelect: (v) => setState(() => _selectedAnswer = v),
                onSubmit: _loading ? null : () => _submit(_selectedAnswer!),
                dimColor: _dimColor,
                dimName: _dimName,
              ),
        'completed' => _ResultsScreen(
            profile: _profile,
            results: _results,
            dimColor: _dimColor,
            dimName: _dimName,
            onDashboard: () => context.go('/dashboard'),
            onRetry: () => setState(() => _state = 'intro'),
          ),
        'error' => _ErrorScreen(
            message: _error ?? 'Une erreur est survenue',
            onRetry: () => setState(() => _state = 'intro'),
          ),
        _ => const SizedBox(),
      },
    );
  }
}

// ── Intro ──────────────────────────────────────────────────────────────────
class _IntroScreen extends StatelessWidget {
  final bool loading;
  final void Function(String) onStart;
  const _IntroScreen({required this.loading, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF7C3AED)]),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.psychology, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          Text('Évaluation Psychométrique\nAdaptative',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 12),
          Text(
              'Découvrez votre profil de personnalité professionnelle avec notre test RIASEC+ adapté par IA',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 15)),
          const SizedBox(height: 32),
          Row(
            children: const [
              Expanded(child: _FeatureCard(icon: Icons.bolt, label: 'Ultra-Rapide', desc: 'Moins de 5 minutes')),
              SizedBox(width: 12),
              Expanded(child: _FeatureCard(icon: Icons.gps_fixed, label: 'Précis', desc: 'IA adaptative')),
              SizedBox(width: 12),
              Expanded(child: _FeatureCard(icon: Icons.emoji_events_outlined, label: 'Résultats', desc: 'Personnalisés')),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: loading ? null : () => onStart('full'),
            child: loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Commencer l\'Évaluation Complète'),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: loading ? null : () => onStart('quick'),
                child: const Text('Rapide (10 min)', style: TextStyle(color: AppColors.accent)),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: loading ? null : () => onStart('focused'),
                child: const Text('Focalisé (5 min)', style: TextStyle(color: Color(0xFF7C3AED))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Basé sur le modèle RIASEC (Holland) avec améliorations par IA',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  const _FeatureCard({required this.icon, required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 13)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: AppColors.muted, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Question ───────────────────────────────────────────────────────────────
class _QuestionScreen extends StatelessWidget {
  final Map<String, dynamic>? question;
  final int questionNumber;
  final int estimatedRemaining;
  final double progress;
  final int? selectedAnswer;
  final void Function(int) onSelect;
  final VoidCallback? onSubmit;
  final Color Function(String?) dimColor;
  final String Function(String?) dimName;

  const _QuestionScreen({
    required this.question,
    required this.questionNumber,
    required this.estimatedRemaining,
    required this.progress,
    required this.selectedAnswer,
    required this.onSelect,
    required this.onSubmit,
    required this.dimColor,
    required this.dimName,
  });

  @override
  Widget build(BuildContext context) {
    if (question == null) return const Center(child: Text('Question indisponible'));
    final dim = question!['dimension'] as String?;
    final difficulty = question!['difficulty_level'] as int? ?? 3;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progression
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: dimColor(dim).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(dimName(dim),
                    style: TextStyle(color: dimColor(dim), fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              Text('Q$questionNumber  •  ~$estimatedRemaining restantes',
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.line,
              valueColor: AlwaysStoppedAnimation(dimColor(dim)),
            ),
          ),
          const SizedBox(height: 24),
          // Difficulté
          Row(
            children: List.generate(5, (i) => Container(
              width: 8, height: 8,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < difficulty ? dimColor(dim) : AppColors.line,
              ),
            )),
          ),
          const SizedBox(height: 16),
          // Texte de la question
          Text(question!['question_text'] as String? ?? '',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 24),
          // Options
          ...List.generate(5, (i) {
            final val = i + 1;
            final isSelected = selectedAnswer == val;
            return GestureDetector(
              onTap: () => onSelect(val),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? dimColor(dim).withValues(alpha: 0.08) : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? dimColor(dim) : AppColors.line,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? dimColor(dim) : AppColors.surface,
                        border: Border.all(color: isSelected ? dimColor(dim) : AppColors.line),
                      ),
                      child: Center(
                        child: Text('$val',
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.muted,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(_responseLabel(val),
                        style: TextStyle(
                          color: isSelected ? AppColors.ink : AppColors.muted,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        )),
                  ],
                ),
              ),
            );
          }),
          const Spacer(),
          ElevatedButton(
            onPressed: selectedAnswer != null ? onSubmit : null,
            child: const Text('Question suivante'),
          ),
        ],
      ),
    );
  }

  String _responseLabel(int v) => {
        1: 'Pas du tout d\'accord',
        2: 'Plutôt pas d\'accord',
        3: 'Neutre',
        4: 'Plutôt d\'accord',
        5: 'Totalement d\'accord',
      }[v] ??
      '$v';
}

// ── Results ────────────────────────────────────────────────────────────────
class _ResultsScreen extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? results;
  final Color Function(String?) dimColor;
  final String Function(String?) dimName;
  final VoidCallback onDashboard;
  final VoidCallback onRetry;

  const _ResultsScreen({
    required this.profile,
    required this.results,
    required this.dimColor,
    required this.dimName,
    required this.onDashboard,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final confidence = ((profile?['confidence_rating'] ?? 0) * 100).toInt();
    final dims = (profile?['top_dimensions'] as List?) ?? [];
    final analysis = results?['analysis'] as Map<String, dynamic>?;
    final careers = (results?['career_suggestions'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header succès
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.teal, Color(0xFF065F46)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text('Évaluation Complétée !',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Confiance : $confidence%',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Scores RIASEC
          if (dims.isNotEmpty) ...[
            Text('Scores RIASEC+',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 14),
            ...dims.map((d) {
              final dim = d as Map<String, dynamic>;
              final score = (dim['score'] as num? ?? 0).toDouble();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dimColor(dim['dimension'] as String?),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      child: Text(dim['name'] as String? ?? dimName(dim['dimension'] as String?),
                          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          minHeight: 8,
                          backgroundColor: AppColors.line,
                          valueColor: AlwaysStoppedAnimation(dimColor(dim['dimension'] as String?)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${score.toInt()}%',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, fontSize: 13)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
          ],

          // Forces
          if (analysis?['strengths'] != null) ...[
            Text('Forces Principales',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 10),
            ...(analysis!['strengths'] as List).map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.teal, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s.toString(), style: TextStyle(color: AppColors.ink))),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
          ],

          // Recommandations de carrière
          if (careers.isNotEmpty) ...[
            Text('Recommandations de Carrière',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: careers.map((c) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Text(c.toString(),
                        style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w500)),
                  )).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Actions
          ElevatedButton(
            onPressed: onDashboard,
            child: const Text('Voir mon Tableau de Bord'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Refaire le Test'),
          ),
        ],
      ),
    );
  }
}

// ── Error ──────────────────────────────────────────────────────────────────
class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 64),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('Retour au début')),
          ],
        ),
      ),
    );
  }
}

