import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
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
              content: Text(state.message),
              backgroundColor: AppColors.red,
            ));
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gradient top line
              Container(height: 3, decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.accent, AppColors.violet]),
              )),
              const SizedBox(height: 40),

              // Logo
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 24)]),
                child: const Icon(Icons.psychology, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 14),
              RichText(text: const TextSpan(children: [
                TextSpan(text: 'Orient', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                TextSpan(text: 'IA',     style: TextStyle(color: AppColors.accent, fontSize: 26, fontWeight: FontWeight.bold)),
              ])),
              const SizedBox(height: 32),

              // Titre
              const Text('Bon retour', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Connecte-toi pour continuer ton parcours', style: TextStyle(color: AppColors.muted, fontSize: 14)),
              const SizedBox(height: 36),

              // Email
              _FieldLabel('ADRESSE EMAIL'),
              const SizedBox(height: 8),
              _Field(
                controller: _emailCtrl,
                hint: 'anne@example.com',
                icon: Icons.email_outlined,
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Password
              Row(children: [
                const Expanded(child: _FieldLabel('MOT DE PASSE')),
                GestureDetector(
                  onTap: () {},
                  child: const Text('Mot de passe oublié ?', style: TextStyle(color: AppColors.accent, fontSize: 13)),
                ),
              ]),
              const SizedBox(height: 8),
              _Field(
                controller: _passwordCtrl,
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.muted, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 32),

              // Bouton connecter
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) => _OrangeButton(
                  label: 'Se connecter',
                  loading: state is AuthLoading,
                  onTap: () => context.read<AuthBloc>().add(
                    AuthLoginRequested(_emailCtrl.text.trim(), _passwordCtrl.text),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Divider OU
              Row(children: [
                Expanded(child: Divider(color: AppColors.line)),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OU continuer avec', style: TextStyle(color: AppColors.muted, fontSize: 12))),
                Expanded(child: Divider(color: AppColors.line)),
              ]),
              const SizedBox(height: 16),

              // Google
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) => _GoogleButton(
                  loading: state is AuthLoading,
                  onTap: () => context.read<AuthBloc>().add(AuthGoogleRequested()),
                ),
              ),
              const SizedBox(height: 28),

              // Inscription
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("Pas encore de compte ? ", style: TextStyle(color: AppColors.muted)),
                GestureDetector(
                  onTap: () => context.go('/register'),
                  child: const Text("S'inscrire", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 32),
              const Text('Ancré en Côte d\'Ivoire 🇨🇮', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets locaux ────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8));
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
    controller: controller,
    keyboardType: keyboard,
    obscureText: obscure,
    style: const TextStyle(color: AppColors.ink, fontSize: 15),
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
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

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _GoogleButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      width: double.infinity, height: 54,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: loading
        ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(width: 20, height: 20, child: CustomPaint(painter: _GoogleLogoPainter())),
            const SizedBox(width: 10),
            const Text('Continuer avec Google', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
          ]),
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
