import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _api = ApiClient();
  Map<String, dynamic>? _data;
  List<dynamic> _recs = [];
  bool _loading = true;
  String _username = '';
  String get _initial => _username.isNotEmpty ? _username[0].toUpperCase() : 'U';

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final info = await LocalStorage.getUserInfo();
    if (mounted) setState(() => _username = info['username'] ?? '');
  }

  Future<void> _loadData() async {
    final cached    = await LocalStorage.getCachedDashboard();
    final cachedRec = await LocalStorage.getCachedRecommendations();
    if (cached    != null) setState(() { _data = cached;  _loading = false; });
    if (cachedRec != null) setState(() => _recs = cachedRec);
    try {
      final d = await _api.getDashboard();
      final r = await _api.getRecommendations();
      await LocalStorage.cacheDashboard(d);
      await LocalStorage.cacheRecommendations(r);
      if (mounted) setState(() { _data = d; _recs = r; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProfileSheet(
        username: _username,
        onLogout: () {
          Navigator.pop(context);
          context.read<AuthBloc>().add(AuthLogoutRequested());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = (_data?['preparation_score'] ?? 0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.accent,
        backgroundColor: AppColors.card,
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.bg,
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 16),
                child: Row(
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Bonjour', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                      Text(_username.isNotEmpty ? _username : 'Utilisateur',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ]),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: AppColors.muted),
                      onPressed: () {},
                    ),
                    GestureDetector(
                      onTap: _showProfile,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
                        child: Center(child: Text(_initial,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(delegate: SliverChildListDelegate([

                // Score Card gradient
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('SCORE DE PRÉPARATION', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                      const SizedBox(height: 6),
                      RichText(text: TextSpan(children: [
                        TextSpan(text: '${score.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
                        const TextSpan(text: ' /100', style: TextStyle(color: Colors.white60, fontSize: 20, fontWeight: FontWeight.w500)),
                      ])),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Tu es prêt à ${score.toInt()}% pour le marché de l\'emploi',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => context.push('/gap-analysis'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('Améliorer', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                          ]),
                        ),
                      ),
                    ])),
                    const SizedBox(width: 16),
                    Stack(alignment: Alignment.center, children: [
                      SizedBox(width: 70, height: 70,
                        child: CircularProgressIndicator(
                          value: score / 100,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                          strokeWidth: 6,
                        ),
                      ),
                      Text('${score.toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 24),

                // Recommandations du jour
                _SectionHeader(title: 'Recommandations du jour', onSeeAll: () => context.go('/explorer')),
                const SizedBox(height: 12),
                if (_loading)
                  _ShimmerCard()
                else if (_recs.isEmpty)
                  _EmptyRec()
                else
                  ..._recs.take(2).map((r) => _RecCard(rec: r)),
                const SizedBox(height: 24),

                // Modules IA
                _SectionHeader(title: 'Modules IA'),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _ModuleCard(icon: Icons.document_scanner, label: 'Analyser mon CV',      color: AppColors.accent, onTap: () => context.push('/cv-analysis')),
                    _ModuleCard(icon: Icons.business_center,  label: 'Métiers prometteurs',  color: AppColors.violet, onTap: () => context.go('/explorer')),
                    _ModuleCard(icon: Icons.analytics,        label: 'Gap Analysis',          color: AppColors.green,  onTap: () => context.push('/gap-analysis')),
                    _ModuleCard(icon: Icons.transform,        label: 'Reconversion',          color: const Color(0xFF3B82F6), onTap: () => context.push('/reconversion')),
                  ],
                ),
                const SizedBox(height: 80),
              ])),
            ),
          ],
        ),
      ),

      // FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/onboarding'),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.bolt, color: Colors.white),
        label: const Text('Action rapide', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
    const Spacer(),
    if (onSeeAll != null)
      GestureDetector(
        onTap: onSeeAll,
        child: const Text('Voir tout ↗', style: TextStyle(color: AppColors.accent, fontSize: 13)),
      ),
  ]);
}

class _RecCard extends StatelessWidget {
  final dynamic rec;
  const _RecCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    final score   = (rec['matching_score'] ?? 0).toDouble();
    final job     = rec['job'] ?? rec;
    final title   = job['title'] ?? 'Métier';
    final sector  = job['sector'] ?? '';
    final location = job['location'] ?? job['city'] ?? 'Abidjan CI';
    final skills  = (job['skills'] as List? ?? []).cast<String>();
    final badge   = score >= 90 ? 'TRÈS DEMANDÉ' : score >= 80 ? 'EN CROISSANCE' : null;
    final badgeColor = score >= 90 ? AppColors.green : AppColors.accent;
    final scoreColor = score >= 90 ? AppColors.green : score >= 80 ? AppColors.accent : AppColors.violet;

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
          Expanded(child: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20)),
            child: Text('${score.toInt()}/100',
              style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ]),
        if (sector.isNotEmpty || location.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on_outlined, color: AppColors.muted, size: 13),
            const SizedBox(width: 3),
            Text('$sector · $location',
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ]),
        ],
        const SizedBox(height: 10),
        // Progress bar gradient
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: AppColors.line,
            valueColor: AlwaysStoppedAnimation(scoreColor),
            minHeight: 5,
          ),
        ),
        if (skills.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, children: skills.take(3).map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(20)),
            child: Text(s, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          )).toList()),
        ],
        if (badge != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6)),
            child: Text(badge,
              style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ]),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ModuleCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500, height: 1.3)),
      ]),
    ),
  );
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 80, margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
  );
}

class _EmptyRec extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
    child: Column(children: [
      Icon(Icons.upload_file_outlined, color: AppColors.muted, size: 36),
      const SizedBox(height: 10),
      const Text('Uploadez votre CV pour des recommandations IA',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted, fontSize: 13)),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
          child: const Text('Analyser mon CV', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ),
    ]),
  );
}

class _ProfileSheet extends StatelessWidget {
  final String username;
  final VoidCallback onLogout;
  const _ProfileSheet({required this.username, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        Container(
          width: 68, height: 68,
          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
          child: Center(child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28))),
        ),
        const SizedBox(height: 12),
        Text(username, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ),
      ]),
    );
  }
}
