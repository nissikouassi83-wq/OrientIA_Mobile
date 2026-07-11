import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _username = '';
  String _email    = '';
  String get _initial => _username.isNotEmpty ? _username[0].toUpperCase() : 'U';

  static const _skills = ['Python', 'SQL', 'Django', 'Flutter', 'Git', 'React', 'JavaScript', 'Power BI'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await LocalStorage.getUserInfo();
    if (mounted) {
      setState(() {
        _username = info['username'] ?? '';
        _email    = info['email']    ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Header
          Row(children: [
            const Text('Mon profil',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(children: [
                Icon(Icons.edit_outlined, color: AppColors.muted, size: 14),
                SizedBox(width: 6),
                Text('Modifier', style: TextStyle(color: AppColors.muted, fontSize: 13)),
              ]),
            ),
          ]),
          const SizedBox(height: 24),

          // Avatar + infos
          Center(
            child: Column(children: [
              Stack(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 20)],
                    ),
                    child: Center(child: Text(_initial,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))),
                  ),
                  Positioned(bottom: 0, right: 0,
                    child: Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle, border: Border.all(color: AppColors.bg, width: 2)),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(_username.isNotEmpty ? _username.toUpperCase() : 'UTILISATEUR',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20)),
                child: const Text('LICENCE GÉNIE LOGICIEL · IIT',
                  style: TextStyle(color: AppColors.violet, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              if (_email.isNotEmpty)
                Text(_email, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 6),
              const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.location_on_outlined, color: AppColors.muted, size: 13),
                SizedBox(width: 4),
                Text('Abidjan, Côte d\'Ivoire 🇨🇮',
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // Score préparation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Score de préparation',
                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
                const Spacer(),
                const Text('78/100',
                  style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.78,
                  backgroundColor: AppColors.line,
                  valueColor: AlwaysStoppedAnimation(AppColors.accent),
                  minHeight: 6)),
              const SizedBox(height: 8),
              const Text('Continue à améliorer ton profil !',
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(children: [
            _StatBox(value: '12', label: 'Recommandations', icon: Icons.analytics, color: AppColors.accent),
            const SizedBox(width: 12),
            _StatBox(value: '4',  label: 'Candidatures',    icon: Icons.business_center, color: AppColors.violet),
            const SizedBox(width: 12),
            _StatBox(value: '3',  label: 'Tests IA',         icon: Icons.psychology, color: AppColors.green),
          ]),
          const SizedBox(height: 20),

          // Compétences
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Compétences',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                GestureDetector(
                  child: const Text('Modifier',
                    style: TextStyle(color: AppColors.accent, fontSize: 13))),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ..._skills.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3))),
                  child: Text(s, style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(20)),
                  child: const Text('+ Ajouter',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // Menu
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line)),
            child: Column(children: [
              _MenuItem(icon: Icons.description_outlined, color: AppColors.accent,   label: 'Mon CV',              onTap: () => context.push('/cv-analysis')),
              _Divider(),
              _MenuItem(icon: Icons.map_outlined,         color: AppColors.violet,   label: 'Mon plan de carrière', onTap: () => context.push('/roadmap')),
              _Divider(),
              _MenuItem(icon: Icons.notifications_outlined,color: AppColors.green,   label: 'Notifications',        onTap: () {}),
              _Divider(),
              _MenuItem(icon: Icons.settings_outlined,    color: AppColors.muted,    label: 'Paramètres',           onTap: () {}),
              _Divider(),
              _MenuItem(
                icon: Icons.logout, color: AppColors.red, label: 'Déconnexion',
                labelColor: AppColors.red,
                onTap: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatBox({required this.value, required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line)),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.color, required this.label, required this.onTap, this.labelColor});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 14),
        Text(label, style: TextStyle(
          color: labelColor ?? Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        const Spacer(),
        if (labelColor == null)
          const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
      ]),
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
    const Divider(height: 1, color: AppColors.line, indent: 66);
}
