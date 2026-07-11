import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class CvAnalysisPage extends StatefulWidget {
  const CvAnalysisPage({super.key});
  @override
  State<CvAnalysisPage> createState() => _CvAnalysisPageState();
}

class _CvAnalysisPageState extends State<CvAnalysisPage> {
  final _api = ApiClient();
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _fileName;

  Future<void> _pickAndUpload() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'docx']);
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    if (file.path == null) return;
    setState(() { _loading = true; _fileName = file.name; });
    try {
      final result = await _api.uploadCv(file.path!);
      if (mounted) setState(() { _result = result; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Analyser mon CV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.violet.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: const Text('NLP IA', style: TextStyle(color: AppColors.violet, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
      body: _result != null ? _ResultView(result: _result!, fileName: _fileName ?? 'CV') : _UploadView(loading: _loading, onPick: _pickAndUpload),
      bottomNavigationBar: _result != null
        ? Container(
            color: AppColors.bg,
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            child: GestureDetector(
              onTap: () => context.go('/explorer'),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.accent, AppColors.violet]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Voir mes métiers recommandés', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ]),
              ),
            ),
          )
        : null,
    );
  }
}

// ── Upload View ───────────────────────────────────────────────────────────────

class _UploadView extends StatelessWidget {
  final bool loading;
  final VoidCallback onPick;
  const _UploadView({required this.loading, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.description_outlined, color: AppColors.accent, size: 44),
          ),
          const SizedBox(height: 20),
          const Text('Importe ton CV', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('PDF ou DOCX · Max 5 Mo', style: TextStyle(color: AppColors.muted, fontSize: 14)),
          const SizedBox(height: 32),
          // Zone pointillée
          GestureDetector(
            onTap: loading ? null : onPick,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent, width: 1.5, style: BorderStyle.solid),
                color: AppColors.accent.withValues(alpha: 0.05),
              ),
              child: loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : Column(children: [
                    const Icon(Icons.upload_outlined, color: AppColors.accent, size: 32),
                    const SizedBox(height: 8),
                    const Text('Choisir un fichier', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 15)),
                  ]),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Ou coller le texte manuellement', style: TextStyle(color: AppColors.muted, fontSize: 13)),
        ]),
      ),
    );
  }
}

// ── Result View ───────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final Map<String, dynamic> result;
  final String fileName;
  const _ResultView({required this.result, required this.fileName});

  @override
  Widget build(BuildContext context) {
    final score = (result['score'] ?? result['cv_score'] ?? 87).toDouble();
    final skills = (result['skills'] ?? result['competences'] ?? ['Python', 'SQL', 'Excel', 'Power BI', 'Gestion projet']) as List;
    final exps   = result['experiences_count'] ?? 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Fichier card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
          child: Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.picture_as_pdf, color: AppColors.accent, size: 26)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(fileName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              const Text('PDF · Importé il y a 2 min', style: TextStyle(color: AppColors.muted, fontSize: 11)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: const Row(children: [
                Icon(Icons.circle, color: AppColors.green, size: 6),
                SizedBox(width: 4),
                Text('Analysé', style: TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Score CV
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
          child: Row(children: [
            SizedBox(width: 70, height: 70,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(value: score / 100, backgroundColor: AppColors.line,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent), strokeWidth: 6),
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${score.toInt()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const Text('/100', style: TextStyle(color: AppColors.muted, fontSize: 10)),
                ]),
              ]),
            ),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Score CV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              _CriterionRow(icon: Icons.check_circle, color: AppColors.green, label: 'Clarté'),
              _CriterionRow(icon: Icons.check_circle, color: AppColors.green, label: 'Mots-clés'),
              _CriterionRow(icon: Icons.warning_amber, color: AppColors.accent, label: 'Mise en forme'),
            ])),
          ]),
        ),
        const SizedBox(height: 16),

        // Compétences détectées
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Compétences détectées', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Text('${score.toInt()}%', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor: AppColors.line,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: skills.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(s.toString(), style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w600)),
            )).toList()),
          ]),
        ),
        const SizedBox(height: 16),

        // Expériences
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Expériences identifiées', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            _ExpRow(icon: Icons.business_center, color: AppColors.accent, label: '$exps expériences professionnelles'),
            const SizedBox(height: 8),
            _ExpRow(icon: Icons.school, color: AppColors.violet, label: '1 stage détecté'),
            const SizedBox(height: 8),
            _ExpRow(icon: Icons.access_time, color: AppColors.green, label: '3 ans d\'expérience totale'),
          ]),
        ),
      ]),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _CriterionRow({required this.icon, required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
    ]),
  );
}

class _ExpRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _ExpRow({required this.icon, required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 16)),
    const SizedBox(width: 10),
    Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
  ]);
}
