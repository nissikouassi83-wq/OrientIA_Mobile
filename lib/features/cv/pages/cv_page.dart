import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class CvPage extends StatefulWidget {
  const CvPage({super.key});

  @override
  State<CvPage> createState() => _CvPageState();
}

class _CvPageState extends State<CvPage> {
  final _api = ApiClient();
  bool _uploading = false;
  Map<String, dynamic>? _result;
  String? _fileName;

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

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
    );
    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    setState(() { _uploading = true; _fileName = result.files.single.name; });

    try {
      final res = await _api.uploadCv(path);
      setState(() { _result = res; _uploading = false; });
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'analyse du CV')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.accent, AppColors.teal]),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 8)],
            ),
            child: const Icon(Icons.description_outlined, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('Mon CV'),
        ]),
      ),
      body: Stack(
        children: [
          Positioned(top: -40, right: -40,
            child: Container(width: 180, height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.06)))),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Zone d'upload
                GestureDetector(
                  onTap: _uploading ? null : _pickAndUpload,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _uploading
                            ? AppColors.accent
                            : AppColors.accent.withValues(alpha: 0.35),
                        width: _uploading ? 2 : 1.5,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _uploading
                            ? Container(
                                key: const ValueKey('loading'),
                                width: 64, height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: CircularProgressIndicator(
                                    color: AppColors.accent, strokeWidth: 3),
                                ),
                              )
                            : Container(
                                key: const ValueKey('icon'),
                                width: 64, height: 64,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.accent, AppColors.teal]),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.4),
                                    blurRadius: 20, spreadRadius: 2)],
                                ),
                                child: Icon(Icons.upload_file_outlined,
                                  color: Colors.white, size: 32),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _uploading ? 'Analyse en cours...' : 'Sélectionner votre CV',
                        style: TextStyle(
                          color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text('PDF ou DOCX acceptés',
                        style: TextStyle(color: AppColors.muted, fontSize: 13)),
                      if (_fileName != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.insert_drive_file_outlined,
                              color: AppColors.accent, size: 14),
                            const SizedBox(width: 6),
                            Text(_fileName!, style: TextStyle(
                              color: AppColors.accent, fontSize: 12)),
                          ]),
                        ),
                      ],
                    ]),
                  ),
                ),

                if (_result != null) ...[
                  const SizedBox(height: 28),
                  _ResultSection(result: _result!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultSection({required this.result});

  @override
  Widget build(BuildContext context) {
    final score = (result['preparation_score'] ?? 0).toDouble();
    final skills = (result['nlp_metadata']?['detected_skills'] as List<dynamic>?)?.cast<String>() ?? [];
    final diplomas = (result['nlp_metadata']?['diplomas'] as List<dynamic>?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Résultat de l\'analyse', style: TextStyle(
          color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.bold,
        )),
        const SizedBox(height: 16),

        // Score card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accent, AppColors.teal],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.35),
              blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Score de préparation',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                const SizedBox(height: 4),
                Text('${score.toInt()}/100', style: TextStyle(
                  color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold, height: 1.1)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 60, height: 60,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  strokeWidth: 5,
                ),
                Text('${score.toInt()}',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
            ),
          ]),
        ),

        if (skills.isNotEmpty) ...[
          const SizedBox(height: 22),
          _TagBlock(
            title: 'Compétences détectées',
            icon: Icons.bolt,
            items: skills,
            color: AppColors.success,
          ),
        ],

        if (diplomas.isNotEmpty) ...[
          const SizedBox(height: 16),
          _TagBlock(
            title: 'Diplômes détectés',
            icon: Icons.school_outlined,
            items: diplomas,
            color: AppColors.accent,
          ),
        ],
      ],
    );
  }
}

class _TagBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final Color color;
  const _TagBlock({required this.title, required this.icon, required this.items, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(
          color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 15)),
      ]),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: items.map((s) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(s, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
        )).toList(),
      ),
    ],
  );
}

