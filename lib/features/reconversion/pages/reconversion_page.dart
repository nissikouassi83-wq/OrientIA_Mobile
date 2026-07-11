import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class ReconversionPage extends StatefulWidget {
  const ReconversionPage({super.key});
  @override
  State<ReconversionPage> createState() => _ReconversionPageState();
}

class _ReconversionPageState extends State<ReconversionPage> {
  final _api      = ApiClient();
  final _fieldCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _results = [];

  static const _mockResults = [
    {'title': 'Chef de projet digital', 'compat': 78, 'duration': '~3 mois de formation', 'skills': ['Notion', 'Trello', 'Com. client'], 'color': 0xFF10B981},
    {'title': 'Community Manager',      'compat': 65, 'duration': '~2 mois de formation', 'skills': ['Canva', 'Meta Ads', 'Copywriting'], 'color': 0xFFF97316},
    {'title': 'UX Designer Junior',     'compat': 59, 'duration': '~4 mois de formation', 'skills': ['Figma', 'User research', 'Prototypage'], 'color': 0xFF8B5CF6},
  ];

  @override
  void dispose() {
    _fieldCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_fieldCtrl.text.isEmpty) return;
    setState(() { _loading = true; _results = []; });
    try {
      await _api.getReconversionOptions(currentField: _fieldCtrl.text, skills: _skillCtrl.text.split(',').map((s) => s.trim()).toList());
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() { _loading = false; _results = List<Map<String, dynamic>>.from(_mockResults); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Reconversion intelligente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text('Pistes en moins de 6 mois', style: TextStyle(color: AppColors.muted, fontSize: 11)),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: const Text('PHASE 1', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Formulaire
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('MA FILIÈRE / DIPLÔME ACTUEL', style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              TextField(
                controller: _fieldCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ex : Licence Droit, BTS Commerce...',
                  hintStyle: const TextStyle(color: AppColors.muted),
                  prefixIcon: const Icon(Icons.school_outlined, color: AppColors.muted, size: 18),
                  filled: true, fillColor: AppColors.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('MES COMPÉTENCES ACTUELLES', style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              TextField(
                controller: _skillCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ex : Rédaction, Excel, Gestion, Analyse...',
                  hintStyle: const TextStyle(color: AppColors.muted),
                  prefixIcon: const Icon(Icons.bolt, color: AppColors.muted, size: 18),
                  filled: true, fillColor: AppColors.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _search,
                  icon: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.bolt, size: 18),
                  label: const Text('Obtenir mes pistes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          if (_results.isNotEmpty) ...[
            Row(children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('${_results.length} pistes identifiées pour toi',
                style: const TextStyle(color: AppColors.green, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 12),
            ..._results.map((r) => _ResultCard(result: r)),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                child: const Text('Voir les métiers prometteurs du moment ↗',
                  style: TextStyle(color: AppColors.accent, fontSize: 13)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final compat = result['compat'] as int;
    final color  = Color(result['color'] as int);
    final skills = (result['skills'] as List).cast<String>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(result['title'] as String,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.access_time, color: AppColors.muted, size: 12),
              const SizedBox(width: 4),
              Text(result['duration'] as String, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ])),
          SizedBox(width: 52, height: 52,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: compat / 100, strokeWidth: 5,
                backgroundColor: AppColors.line,
                valueColor: AlwaysStoppedAnimation(color),
              ),
              Text('$compat%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: compat / 100, minHeight: 5,
            backgroundColor: AppColors.line,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 6, children: skills.map((s) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(20)),
          child: Text(s, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        )).toList()),
        const SizedBox(height: 10),
        GestureDetector(
          child: Container(
            width: double.infinity, height: 38,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: color)),
            child: Center(child: Text('Voir le détail', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600))),
          ),
        ),
      ]),
    );
  }
}
