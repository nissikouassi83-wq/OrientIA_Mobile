import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _niveau;
  String? _domaine;

  static const _niveaux  = ['Licence', 'Master', 'BTS', 'DUT', 'Autre'];
  static const _domaines = ['Informatique', 'Gestion', 'Droit', 'Sciences', 'Autre'];

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _pass2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) context.go('/dashboard');
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message), backgroundColor: AppColors.red,
            ));
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(height: 3, decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.accent, AppColors.violet]))),
              const SizedBox(height: 32),

              // Logo
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 20)]),
                child: const Icon(Icons.psychology, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 10),
              RichText(text: const TextSpan(children: [
                TextSpan(text: 'Orient', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                TextSpan(text: 'IA',     style: TextStyle(color: AppColors.accent, fontSize: 22, fontWeight: FontWeight.bold)),
              ])),
              const SizedBox(height: 20),

              const Text('Créer mon compte', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Rejoins la communauté OrientIA CI 🇨🇮', style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 28),

              _Label('PRÉNOM & NOM'),
              const SizedBox(height: 8),
              _Field(controller: _nameCtrl, hint: 'Ex : Anne Nissi Kouassi', icon: Icons.person_outline),
              const SizedBox(height: 16),

              _Label('ADRESSE EMAIL'),
              const SizedBox(height: 8),
              _Field(controller: _emailCtrl, hint: 'anne@example.com', icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
              const SizedBox(height: 16),

              _Label('MOT DE PASSE'),
              const SizedBox(height: 8),
              _Field(controller: _passCtrl, hint: '••••••••', icon: Icons.lock_outline, obscure: _obscure1,
                suffix: IconButton(
                  icon: Icon(_obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.muted, size: 20),
                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                )),
              const SizedBox(height: 16),

              _Label('CONFIRMER MOT DE PASSE'),
              const SizedBox(height: 8),
              _Field(controller: _pass2Ctrl, hint: '••••••••', icon: Icons.lock_outline, obscure: _obscure2,
                suffix: IconButton(
                  icon: Icon(_obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.muted, size: 20),
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                )),
              const SizedBox(height: 20),

              _Label("NIVEAU D'ÉTUDES"),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(spacing: 8, children: _niveaux.map((n) => _Chip(
                  label: n, selected: _niveau == n,
                  onTap: () => setState(() => _niveau = n),
                )).toList()),
              ),
              const SizedBox(height: 20),

              _Label('DOMAINE'),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(spacing: 8, children: _domaines.map((d) => _Chip(
                  label: d, selected: _domaine == d, color: AppColors.violet,
                  onTap: () => setState(() => _domaine = d),
                )).toList()),
              ),
              const SizedBox(height: 32),

              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) => _OrangeButton(
                  label: 'Créer mon compte',
                  loading: state is AuthLoading,
                  onTap: () {
                    final parts = _nameCtrl.text.trim().split(' ');
                    final username = parts.isNotEmpty ? parts.first.toLowerCase() : 'user';
                    context.read<AuthBloc>().add(AuthRegisterRequested(
                      username,
                      _emailCtrl.text.trim(),
                      _passCtrl.text,
                      _pass2Ctrl.text,
                    ));
                  },
                ),
              ),
              const SizedBox(height: 20),

              Row(children: [
                Expanded(child: Divider(color: AppColors.line)),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OU', style: TextStyle(color: AppColors.muted, fontSize: 12))),
                Expanded(child: Divider(color: AppColors.line)),
              ]),
              const SizedBox(height: 16),

              Container(
                width: double.infinity, height: 54,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 20, height: 20, child: CustomPaint(painter: _GoogleLogoPainter())),
                  const SizedBox(width: 10),
                  const Text('Continuer avec Google', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                ]),
              ),
              const SizedBox(height: 20),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Déjà inscrit ? ', style: TextStyle(color: AppColors.muted)),
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: const Text('Se connecter', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboard;
  final bool obscure;
  final Widget? suffix;
  const _Field({required this.controller, required this.hint, required this.icon, this.keyboard, this.obscure = false, this.suffix});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller, keyboardType: keyboard, obscureText: obscure,
    style: const TextStyle(color: AppColors.ink, fontSize: 15),
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
      suffixIcon: suffix,
      filled: true, fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, this.color = AppColors.accent, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? color : AppColors.line),
      ),
      child: Text(label, style: TextStyle(
        color: selected ? Colors.white : AppColors.muted, fontSize: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      )),
    ),
  );
}

class _OrangeButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _OrangeButton({required this.label, required this.loading, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      width: double.infinity, height: 54,
      decoration: BoxDecoration(
        color: loading ? AppColors.line : AppColors.accent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: loading ? null : [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Center(child: loading
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
        : Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
    ),
  );
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final colors = [const Color(0xFF4285F4), const Color(0xFFEA4335), const Color(0xFFFBBC05), const Color(0xFF34A853)];
    for (int i = 0; i < 4; i++) {
      final paint = Paint()..color = colors[i]..style = PaintingStyle.stroke..strokeWidth = 4;
      canvas.drawArc(Rect.fromCircle(center: Offset(r, r), radius: r - 2),
        i * 3.1416 / 2, 3.1416 / 2, false, paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}
