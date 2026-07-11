import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class CareersPage extends StatefulWidget {
  const CareersPage({super.key});
  @override
  State<CareersPage> createState() => _CareersPageState();
}

class _CareersPageState extends State<CareersPage> {
  final _api = ApiClient();
  List<dynamic> _jobs = [];
  bool _loading = true;
  String _filter = 'Tous';

  static const _filters = ['Tous', 'Tech', 'Finance', 'BTP', 'Santé', 'Agritech'];

  static const _mockJobs = [
    {
      'title': 'Data Analyst',
      'sector': 'Data & Analytics',
      'location': 'Abidjan CI',
      'salary': '450 000 – 700 000 FCFA/mois',
      'score': 94,
      'scoreColor': 0xFF10B981,
      'skills': ['SQL', 'Python', 'Power BI'],
      'badges': ['RECRUTEMENT MASSIF', 'TÉLÉTRAVAIL'],
      'badgeColors': [0xFFEF4444, 0xFF3B82F6],
      'barColor': 0xFF10B981,
    },
    {
      'title': 'Chef de projet IT',
      'sector': 'Management',
      'location': 'Orange CI',
      'salary': '600 000 – 900 000 FCFA/mois',
      'score': 88,
      'scoreColor': 0xFFF97316,
      'skills': ['Agile', 'Jira', 'PMP'],
      'badges': ['EN CROISSANCE 📈'],
      'badgeColors': [0xFFF97316],
      'barColor': 0xFFF97316,
    },
    {
      'title': 'Développeur No-Code',
      'sector': 'Tech & Numérique',
      'location': 'Remote',
      'salary': '420 000 – 650 000 FCFA/mois',
      'score': 81,
      'scoreColor': 0xFF8B5CF6,
      'skills': ['Bubble', 'Webflow', 'UX'],
      'badges': ['NOUVEAU MÉTIER', 'TÉLÉTRAVAIL'],
      'badgeColors': [0xFF8B5CF6, 0xFF3B82F6],
      'barColor': 0xFF8B5CF6,
    },
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final recs = await _api.getRecommendations();
      if (mounted && recs.isNotEmpty) {
        setState(() { _jobs = recs; _loading = false; });
        return;
      }
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() { _jobs = _mockJobs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // AppBar
          Container(
            color: AppColors.bg,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 12),
            child: Row(children: [
              const Text('Métiers pour toi',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
                child: const Icon(Icons.tune, color: AppColors.muted, size: 20)),
            ]),
          ),

          // Filtres chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final active = _filter == _filters[i];
                return GestureDetector(
                  onTap: () => setState(() => _filter = _filters[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AppColors.accent : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? AppColors.accent : AppColors.line)),
                    child: Text(_filters[i], style: TextStyle(
                      color: active ? Colors.white : AppColors.muted,
                      fontSize: 13, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Sous-titre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(alignment: Alignment.centerLeft,
              child: Text('${_jobs.length} métiers correspondent à ton profil',
                style: const TextStyle(color: AppColors.muted, fontSize: 12))),
          ),
          const SizedBox(height: 12),

          // Liste
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: _jobs.length,
                  itemBuilder: (_, i) => _JobCard(job: _jobs[i] as Map<String, dynamic>),
                ),
          ),
        ],
      ),

      // FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.search, color: Colors.white),
        label: const Text('Affiner les résultats',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final score      = job['score'] as int? ?? (job['matching_score'] as num?)?.toInt() ?? 0;
    final scoreColor = Color(job['scoreColor'] as int? ?? 0xFFF97316);
    final barColor   = Color(job['barColor']   as int? ?? 0xFFF97316);
    final title      = job['title']    as String? ?? job['job']?['title'] ?? 'Métier';
    final sector     = job['sector']   as String? ?? '';
    final location   = job['location'] as String? ?? '';
    final salary     = job['salary']   as String? ?? '';
    final skills     = (job['skills']  as List? ?? []).cast<String>();
    final badges     = (job['badges']  as List? ?? []).cast<String>();
    final badgeColors= (job['badgeColors'] as List? ?? []).map((c) => Color(c as int)).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20)),
              child: Text('$score/100',
                style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 12))),
          ]),
        ),
        if (sector.isNotEmpty || location.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 0),
            child: Row(children: [
              const Icon(Icons.location_on_outlined, color: AppColors.muted, size: 13),
              const SizedBox(width: 3),
              Text('$sector · $location',
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ),
        if (salary.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 0),
            child: Row(children: [
              const Icon(Icons.attach_money, color: AppColors.green, size: 14),
              const SizedBox(width: 2),
              Text(salary,
                style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),

        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: AppColors.line,
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 5)),
        ),

        // Skills
        if (skills.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Wrap(spacing: 6, children: skills.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(20)),
              child: Text(s, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            )).toList()),
          ),

        // Badges
        if (badges.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(spacing: 6, children: List.generate(badges.length, (i) {
              final c = i < badgeColors.length ? badgeColors[i] : AppColors.accent;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6)),
                child: Text(badges[i], style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)));
            })),
          ),

        // Bouton
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity, height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scoreColor)),
            child: Center(child: Text('Voir le détail',
              style: TextStyle(color: scoreColor, fontWeight: FontWeight.w600, fontSize: 13))),
          ),
        ),
      ]),
    );
  }
}
