import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class CoachPage extends StatefulWidget {
  const CoachPage({super.key});

  @override
  State<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends State<CoachPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  void _onTheme() { if (mounted) setState(() {}); }

  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_onTheme);
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onTheme);
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accent, AppColors.teal]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 10)],
              ),
              child: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Coach IA'),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.accent,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: 'Coach IA'),
            Tab(text: "Plan d'action"),
            Tab(text: 'Coach humain'),
            Tab(text: 'Suivi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _ChatTab(),
          _ActionPlanTab(),
          _HumanCoachTab(),
          _SuiviTab(),
        ],
      ),
    );
  }
}

// ── Tab 1: Chat ───────────────────────────────────────────────────────────────

class _ChatTab extends StatefulWidget {
  const _ChatTab();
  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final _api = ApiClient();
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final msgs = await _api.getCoachMessages();
      setState(() {
        _messages.addAll(msgs.map((m) => {
          'role': m['role'] as String,
          'content': m['content'] as String,
        }));
      });
      _scrollToBottom();
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    setState(() { _messages.add({'role': 'user', 'content': text}); _sending = true; });
    _scrollToBottom();
    try {
      final res = await _api.sendCoachMessage(text);
      setState(() => _messages.add({'role': 'assistant', 'content': res['assistant_content'] ?? '...'}));
    } catch (_) {
      setState(() => _messages.add({'role': 'assistant', 'content': 'Service temporairement indisponible.'}));
    } finally {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _WelcomeHint(onSuggestion: (s) { _ctrl.text = s; _send(); })
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _messages.length) return _TypingBubble();
                    final msg = _messages[i];
                    return _MessageBubble(role: msg['role']!, content: msg['content']!);
                  },
                ),
        ),
        _InputBar(ctrl: _ctrl, onSend: _send, sending: _sending),
      ],
    );
  }
}

// ── Tab 2: Plan d'action ──────────────────────────────────────────────────────

class _ActionPlanTab extends StatefulWidget {
  const _ActionPlanTab();
  @override
  State<_ActionPlanTab> createState() => _ActionPlanTabState();
}

class _ActionPlanTabState extends State<_ActionPlanTab> {
  final _api = ApiClient();
  Map<String, dynamic>? _plan;
  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getCoachActionPlan();
      if (mounted) setState(() { _plan = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _plan = null; _loading = false; });
    }
  }

  Future<void> _create() async {
    setState(() => _creating = true);
    try {
      final data = await _api.createCoachActionPlan({
        'title': 'Mon plan d\'action',
        'description': 'Plan généré automatiquement',
      });
      if (mounted) setState(() { _plan = data; _creating = false; });
    } catch (_) {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.accent));

    if (_plan == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.checklist_rtl, size: 36, color: AppColors.accent),
              ),
              const SizedBox(height: 20),
              Text("Aucun plan d'action", style: TextStyle(
                color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Créez votre premier plan d'action personnalisé.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.5)),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _creating ? null : _create,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: _creating ? null : const LinearGradient(colors: [AppColors.accent, AppColors.teal]),
                    color: _creating ? AppColors.muted.withValues(alpha: 0.3) : null,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _creating ? null : [
                      BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: _creating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Créer mon plan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final steps = (_plan!['steps'] as List<dynamic>?) ?? [];
    final program = _plan!['program'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.checklist_rtl, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_plan!['title'] ?? "Plan d'action",
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                ]),
                if (_plan!['description'] != null) ...[
                  const SizedBox(height: 8),
                  Text(_plan!['description'].toString(),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                ],
                if (program != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Programme: ${program['title'] ?? ''}',
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (steps.isEmpty)
            Center(child: Text("Aucune étape définie", style: TextStyle(color: AppColors.muted)))
          else ...[
            Text('Étapes', style: TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ...steps.asMap().entries.map((e) {
              final step = e.value as Map<String, dynamic>;
              final done = step['completed'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: done ? AppColors.teal.withValues(alpha: 0.5) : AppColors.line),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: done ? AppColors.teal.withValues(alpha: 0.15) : AppColors.accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        done ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                        color: done ? AppColors.teal : AppColors.accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step['title'] ?? '', style: TextStyle(
                            color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 14,
                            decoration: done ? TextDecoration.lineThrough : null,
                          )),
                          if (step['description'] != null)
                            Text(step['description'].toString(),
                              style: TextStyle(color: AppColors.muted, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ── Tab 3: Coach humain ────────────────────────────────────────────────────────

class _HumanCoachTab extends StatelessWidget {
  const _HumanCoachTab();

  @override
  Widget build(BuildContext context) {
    final coaches = [
      {'name': 'Aminata Koné', 'specialty': 'Transition de carrière', 'exp': '8 ans', 'rating': '4.9', 'available': true},
      {'name': 'Jean-Marc Brou', 'specialty': 'Entrepreneuriat & startups', 'exp': '12 ans', 'rating': '4.8', 'available': true},
      {'name': 'Fatou Diallo', 'specialty': 'Ressources humaines', 'exp': '6 ans', 'rating': '4.7', 'available': false},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Icon(Icons.person_search, color: AppColors.teal, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Text(
                'Échangez avec un coach certifié pour un accompagnement personnalisé.',
                style: TextStyle(color: AppColors.ink, fontSize: 13, height: 1.4),
              )),
            ]),
          ),
          const SizedBox(height: 24),
          Text('Coachs disponibles', style: TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          ...coaches.map((c) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: c['available'] == true
                          ? [AppColors.accent, AppColors.teal]
                          : [AppColors.muted, AppColors.muted],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (c['name'] as String).split(' ').map((w) => w[0]).take(2).join(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(c['name'] as String, style: TextStyle(
                          color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 14))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (c['available'] == true ? AppColors.teal : AppColors.muted).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(c['available'] == true ? 'Disponible' : 'Indisponible',
                            style: TextStyle(
                              color: c['available'] == true ? AppColors.teal : AppColors.muted,
                              fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      const SizedBox(height: 3),
                      Text(c['specialty'] as String, style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.star, color: const Color(0xFFEAB308), size: 13),
                        const SizedBox(width: 3),
                        Text(c['rating'] as String, style: TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Icon(Icons.work_outline, color: AppColors.muted, size: 13),
                        const SizedBox(width: 3),
                        Text(c['exp'] as String, style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: AppColors.accent, size: 18),
              const SizedBox(width: 12),
              Expanded(child: Text(
                'La mise en relation avec les coachs humains sera disponible prochainement.',
                style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Tab 4: Suivi & rappels ─────────────────────────────────────────────────────

class _SuiviTab extends StatefulWidget {
  const _SuiviTab();
  @override
  State<_SuiviTab> createState() => _SuiviTabState();
}

class _SuiviTabState extends State<_SuiviTab> {
  final List<Map<String, dynamic>> _reminders = [
    {'title': 'Mise à jour du CV', 'date': 'Tous les 30 jours', 'active': true, 'icon': Icons.description_outlined},
    {'title': 'Session de coaching IA', 'date': 'Tous les 7 jours', 'active': true, 'icon': Icons.chat_bubble_outline},
    {'title': 'Révision du plan d\'action', 'date': 'Tous les 14 jours', 'active': false, 'icon': Icons.checklist_rtl},
    {'title': 'Test psychométrique', 'date': 'Tous les 90 jours', 'active': false, 'icon': Icons.psychology_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    final activeCount = _reminders.where((r) => r['active'] == true).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Suivi actif', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('$activeCount rappels activés', style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Restez régulier dans votre progression.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, height: 1.4)),
                    ],
                  ),
                ),
                Icon(Icons.notifications_active, color: Colors.white.withValues(alpha: 0.8), size: 48),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Rappels automatiques', style: TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),

          ..._reminders.asMap().entries.map((e) {
            final r = e.value;
            final active = r['active'] as bool;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: active ? AppColors.accent.withValues(alpha: 0.4) : AppColors.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: active ? AppColors.accent.withValues(alpha: 0.12) : AppColors.muted.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(r['icon'] as IconData,
                      color: active ? AppColors.accent : AppColors.muted, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['title'] as String, style: TextStyle(
                          color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(r['date'] as String, style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(
                    value: active,
                    activeColor: AppColors.accent,
                    onChanged: (v) => setState(() => _reminders[e.key]['active'] = v),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: AppColors.teal, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Text('Les notifications push seront disponibles dans la prochaine version.',
                style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4))),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String role;
  final String content;
  const _MessageBubble({required this.role, required this.content});

  @override
  Widget build(BuildContext context) {
    final isUser = role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accent, AppColors.teal]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 8)],
              ),
              child: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(colors: [AppColors.accent, Color(0xFFC2410C)])
                    : null,
                color: isUser ? null : AppColors.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: AppColors.line),
                boxShadow: isUser ? [
                  BoxShadow(color: AppColors.accent.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
                ] : null,
              ),
              child: Text(content, style: TextStyle(
                color: isUser ? Colors.white : AppColors.ink,
                fontSize: 14, height: 1.5,
              )),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34, height: 34,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.accent, AppColors.teal]),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) => _Dot(delay: i * 200)),
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: 7, height: 7,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.4 + 0.6 * _anim.value),
        shape: BoxShape.circle,
      ),
    ),
  );
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSend;
  final bool sending;
  const _InputBar({required this.ctrl, required this.onSend, required this.sending});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.line),
              ),
              child: TextField(
                controller: ctrl,
                style: TextStyle(color: AppColors.ink, fontSize: 14),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Posez votre question...',
                  hintStyle: TextStyle(color: AppColors.muted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: sending ? null : const LinearGradient(colors: [AppColors.accent, AppColors.teal]),
                color: sending ? AppColors.muted.withValues(alpha: 0.3) : null,
                shape: BoxShape.circle,
                boxShadow: sending ? null : [
                  BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 12),
                ],
              ),
              child: Icon(sending ? Icons.hourglass_top : Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeHint extends StatelessWidget {
  final void Function(String) onSuggestion;
  const _WelcomeHint({required this.onSuggestion});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'Comment préparer mon entretien ?',
      'Secteurs porteurs en Côte d\'Ivoire ?',
      'Quel salaire négocier ?',
    ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accent, AppColors.teal]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 24, spreadRadius: 4)],
              ),
              child: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Coach IA OrientIA', style: TextStyle(
              color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 8),
            Text(
              'Posez vos questions sur les entretiens, les secteurs porteurs ou votre parcours.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 28),
            ...suggestions.map((s) => GestureDetector(
              onTap: () => onSuggestion(s),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt, color: AppColors.accent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s, style: TextStyle(color: AppColors.ink, fontSize: 14))),
                    Icon(Icons.arrow_forward_ios, color: AppColors.muted, size: 14),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
