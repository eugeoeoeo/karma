import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final auth = ref.watch(authProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(dashboardProvider),
      color: KarmaColors.primary,
      child: CustomScrollView(
        slivers: [
          // ─── App Bar ────────────────────
          SliverAppBar(
            floating: true,
            backgroundColor: KarmaColors.background,
            title: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: KarmaColors.primary.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Karma', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700)),
              ],
            ),
            actions: [
              if (!auth.state.aiAvailable)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AIStatusBadge(isAI: false, aiAvailable: false),
                ),
              IconButton(
                icon: const Icon(Icons.psychology, color: KarmaColors.primaryLight),
                onPressed: () => context.push('/mentor'),
                tooltip: 'AI Mentor',
              ),
              const SizedBox(width: 4),
            ],
          ),

          // ─── Content ────────────────────
          dashboard.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: KarmaColors.primary))),
            error: (e, _) => SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off, size: 48, color: KarmaColors.textHint),
              const SizedBox(height: 16),
              Text('Could not load dashboard', style: TextStyle(color: KarmaColors.textSecondary)),
              const SizedBox(height: 8),
              TextButton(onPressed: () => ref.invalidate(dashboardProvider), child: const Text('Retry')),
            ]))),
            data: (data) {
              final user = data['user'] ?? {};
              final virtues = (data['virtues'] as List?) ?? [];
              final recentActions = (data['recentActions'] as List?) ?? [];
              final activeIntentions = (data['activeIntentions'] as List?) ?? [];
              final stats = data['stats'] ?? {};
              final obligations = (data['obligations'] as List?) ?? [];

              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  // ─── Greeting + Avatar ────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Hello, ${user['username'] ?? 'Seeker'}', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: KarmaColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text(_getGreeting(), style: const TextStyle(fontSize: 15, color: KarmaColors.textSecondary)),
                          ]),
                        ),
                        _AvatarWidget(stage: user['avatarStage'] ?? 1),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Quick Actions ──────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _QuickAction(icon: Icons.add_circle_outline, label: 'Good Action', color: KarmaColors.good, onTap: () => _logAction(context, ref, 'GOOD')),
                        _QuickAction(icon: Icons.remove_circle_outline, label: 'Growth Area', color: KarmaColors.negative, onTap: () => _logAction(context, ref, 'NEGATIVE')),
                        _QuickAction(icon: Icons.favorite_outline, label: 'Blessing', color: KarmaColors.accent, onTap: () => context.go('/blessings')),
                        _QuickAction(icon: Icons.flag_outlined, label: 'Intention', color: KarmaColors.wisdom, onTap: () => context.go('/intentions')),
                        _QuickAction(icon: Icons.auto_awesome, label: 'Wishes', color: KarmaColors.primary, onTap: () => context.go('/wishes')),
                      ],
                    ),
                  ),

                  // ─── Stats Row ────────────────────────
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _StatCard(label: 'Readiness', value: '${stats['readiness']?['readiness'] ?? 0}', icon: Icons.trending_up, color: KarmaColors.primary),
                        const SizedBox(width: 10),
                        _StatCard(label: 'Actions', value: '${stats['totalActions'] ?? 0}', icon: Icons.bolt, color: KarmaColors.good),
                        const SizedBox(width: 10),
                        _StatCard(label: 'Blessings', value: '${stats['totalBlessings'] ?? 0}', icon: Icons.stars, color: KarmaColors.accent),
                      ],
                    ),
                  ),

                  // ─── Top Virtues ────────────────────────
                  if (virtues.isNotEmpty) ...[
                    SectionHeader(title: 'Your Virtues', actionText: 'See All', onAction: () => context.go('/virtues')),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: virtues.length > 6 ? 6 : virtues.length,
                        itemBuilder: (_, i) {
                          final uv = virtues[i];
                          final virtue = uv['virtue'] ?? {};
                          return _VirtueChip(name: virtue['name'] ?? '', icon: virtue['icon'] ?? '⭐', level: uv['level'] ?? 1, score: (uv['score'] ?? 0).toDouble());
                        },
                      ),
                    ),
                  ],

                  // ─── Wishes & Worthiness ──────────────
                  if (dashboard.value?['wishes'] != null && (dashboard.value?['wishes'] as List).isNotEmpty) ...[
                    SectionHeader(title: 'Wishes & Worthiness', actionText: 'See All', onAction: () => context.go('/wishes')),
                    ...(dashboard.value?['wishes'] as List).take(2).map((w) {
                      final title = w['title'] ?? 'Wish';
                      final virtueName = w['virtueName'] ?? '';
                      final reqLevel = w['requiredLevel'] ?? 1;
                      final status = w['status'] ?? 'PENDING';
                      
                      final uv = virtues.firstWhere(
                        (element) => (element['virtue']?['name'] as String?)?.toLowerCase() == virtueName.toLowerCase(),
                        orElse: () => null,
                      );
                      final userLevel = uv?['level'] ?? 1;
                      final isWorthy = userLevel >= reqLevel;

                      return GlassCard(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            status == 'GRANTED'
                                ? Icons.check_circle_outline
                                : isWorthy
                                    ? Icons.lock_open_rounded
                                    : Icons.lock_outline,
                            color: status == 'GRANTED'
                                ? KarmaColors.good
                                : isWorthy
                                    ? KarmaColors.primaryLight
                                    : KarmaColors.textHint,
                          ),
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: KarmaColors.textPrimary)),
                          subtitle: Text(
                            status == 'GRANTED'
                                ? 'Granted!'
                                : 'Needs $virtueName Level $reqLevel (You: Level $userLevel)',
                            style: TextStyle(
                              color: status == 'GRANTED'
                                  ? KarmaColors.goodLight
                                  : isWorthy
                                      ? KarmaColors.primaryLight
                                      : KarmaColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: status == 'GRANTED'
                                  ? KarmaColors.good.withValues(alpha: 0.1)
                                  : isWorthy
                                      ? KarmaColors.primary.withValues(alpha: 0.1)
                                      : KarmaColors.surfaceLighter,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status == 'GRANTED'
                                  ? 'Granted'
                                  : isWorthy
                                      ? 'Worthy'
                                      : 'Locked',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: status == 'GRANTED'
                                    ? KarmaColors.good
                                    : isWorthy
                                        ? KarmaColors.primaryLight
                                        : KarmaColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],

                  // ─── Obligations Warning ──────────────
                  if (obligations.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    GlassCard(
                      borderColor: KarmaColors.warning.withValues(alpha: 0.4),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.warning_amber_rounded, color: KarmaColors.warning, size: 20),
                          const SizedBox(width: 8),
                          Text('Gratitude Obligations', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: KarmaColors.warning)),
                        ]),
                        const SizedBox(height: 8),
                        Text('You have ${obligations.length} blessing(s) that exceeded your readiness. Honor them through virtuous actions.', style: const TextStyle(fontSize: 13, color: KarmaColors.textSecondary)),
                      ]),
                    ),
                  ],

                  // ─── Recent Actions ──────────────────
                  if (recentActions.isNotEmpty) ...[
                    SectionHeader(title: 'Recent Actions', actionText: 'View All'),
                    ...recentActions.take(3).map((a) => _ActionTile(action: a)),
                  ],

                  // ─── Active Intentions ────────────────
                  if (activeIntentions.isNotEmpty) ...[
                    SectionHeader(title: 'Active Intentions', actionText: 'Manage', onAction: () => context.go('/intentions')),
                    ...activeIntentions.take(3).map((i) => _IntentionTile(intention: i)),
                  ],

                  // ─── Story + More ─────────────────────
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Expanded(child: _FeatureCard(icon: Icons.auto_stories, title: 'Life Story', subtitle: 'Your AI narrative', color: KarmaColors.wisdom, onTap: () => context.go('/story'))),
                      const SizedBox(width: 10),
                      Expanded(child: _FeatureCard(icon: Icons.psychology, title: 'AI Mentor', subtitle: 'Get guidance', color: KarmaColors.good, onTap: () => context.push('/mentor'))),
                    ]),
                  ),
                ])),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Start your morning with intention ☀️';
    if (hour < 17) return 'Keep growing this afternoon 🌿';
    return 'Reflect on your day tonight 🌙';
  }

  Future<void> _logAction(BuildContext context, WidgetRef ref, String type) async {
    final controller = TextEditingController();
    bool honestPledge = true;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: KarmaColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: KarmaColors.surfaceLighter, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(type == 'GOOD' ? '✨ Log Good Action' : '🌱 Log Growth Area', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: KarmaColors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              autofocus: true,
              style: const TextStyle(color: KarmaColors.textPrimary),
              decoration: InputDecoration(hintText: type == 'GOOD' ? 'What good did you do?' : 'What could you improve?'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: honestPledge,
                  activeColor: KarmaColors.primary,
                  onChanged: (val) {
                    setModalState(() {
                      honestPledge = val ?? true;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    'I pledge under my conscience that this is 100% honest and accurate.',
                    style: TextStyle(color: KarmaColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GradientButton(
              text: 'Log Action',
              colors: type == 'GOOD' ? [KarmaColors.good, KarmaColors.goodLight] : [KarmaColors.negative, KarmaColors.negativeLight],
              onPressed: () {
                if (honestPledge) {
                  Navigator.pop(ctx, {'text': controller.text});
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('You must pledge honesty to log actions.'), backgroundColor: KarmaColors.warning)
                  );
                }
              },
            ),
          ]),
        ),
      ),
    );

    if (result != null && result['text'] != null && (result['text'] as String).isNotEmpty) {
      try {
        await ApiClient().post('/actions', data: {'actionText': result['text'], 'actionType': type, 'source': 'TEXT'});
        ref.invalidate(dashboardProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action logged! ✨'), backgroundColor: KarmaColors.surfaceLighter));
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to log action'), backgroundColor: KarmaColors.negative));
        }
      }
    }
  }
}

// ─── Widget Components ──────────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  final int stage;
  const _AvatarWidget({required this.stage});

  @override
  Widget build(BuildContext context) {
    final colors = [
      [KarmaColors.textHint, KarmaColors.surfaceLighter],           // Stage 1
      [KarmaColors.good, KarmaColors.goodLight],                     // Stage 2
      [KarmaColors.primary, KarmaColors.primaryLight],                // Stage 3
      [KarmaColors.accent, KarmaColors.primary],                     // Stage 4
      [KarmaColors.accent, KarmaColors.warning, KarmaColors.primary], // Stage 5
    ];
    final stageColors = stage <= 5 ? colors[stage - 1] : colors[4];
    final icons = [Icons.person, Icons.person, Icons.shield, Icons.auto_awesome, Icons.all_inclusive];
    final icon = stage <= 5 ? icons[stage - 1] : icons[4];

    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: stageColors.cast<Color>()),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: stageColors.first.withValues(alpha: 0.5), blurRadius: 20)],
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 62) / 4;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w, height: 80,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: KarmaColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: KarmaColors.textPrimary)),
        Text(label, style: TextStyle(fontSize: 12, color: KarmaColors.textSecondary)),
      ]),
    ));
  }
}

class _VirtueChip extends StatelessWidget {
  final String name, icon;
  final int level;
  final double score;
  const _VirtueChip({required this.name, required this.icon, required this.level, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = KarmaColors.getVirtueColor(name);
    return Container(
      width: 90, margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color), overflow: TextOverflow.ellipsis),
        Text('Lv. $level', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final dynamic action;
  const _ActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final isGood = action['actionType'] == 'GOOD';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: KarmaColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: (isGood ? KarmaColors.good : KarmaColors.negative).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(isGood ? Icons.add : Icons.remove, color: isGood ? KarmaColors.good : KarmaColors.negative, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(action['actionText'] ?? '', style: const TextStyle(fontSize: 14, color: KarmaColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

class _IntentionTile extends StatelessWidget {
  final dynamic intention;
  const _IntentionTile({required this.intention});

  @override
  Widget build(BuildContext context) {
    final progress = (intention['progress'] ?? 0).toDouble() / 100;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: KarmaColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(intention['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: KarmaColors.textPrimary)),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: KarmaColors.surfaceLighter, color: KarmaColors.primary, minHeight: 4)),
      ]),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _FeatureCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: KarmaColors.textSecondary)),
        ]),
      ),
    );
  }
}
