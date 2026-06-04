import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

class IntentionsScreen extends ConsumerWidget {
  const IntentionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intentionsAsync = ref.watch(intentionsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(intentionsProvider),
      color: KarmaColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true, backgroundColor: KarmaColors.background,
            title: const Text('Intentions'), automaticallyImplyLeading: false,
            actions: [
              IconButton(icon: const Icon(Icons.add_circle_outline, color: KarmaColors.primary), onPressed: () => _addIntention(context, ref)),
              const SizedBox(width: 8),
            ],
          ),
          intentionsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: KarmaColors.primary))),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Failed to load', style: TextStyle(color: KarmaColors.textHint)))),
            data: (intentions) {
              if (intentions.isEmpty) {
                return SliverFillRemaining(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const EmptyState(icon: Icons.flag_outlined, title: 'No intentions yet', subtitle: 'Set your first goal to start tracking'),
                  GradientButton(text: 'Add Intention', icon: Icons.add, onPressed: () => _addIntention(context, ref)),
                ]));
              }

              final active = intentions.where((i) => i['status'] == 'ACTIVE').toList();
              final completed = intentions.where((i) => i['status'] == 'COMPLETED').toList();
              final other = intentions.where((i) => i['status'] != 'ACTIVE' && i['status'] != 'COMPLETED').toList();

              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  if (active.isNotEmpty) ...[
                    const SectionHeader(title: 'Active'),
                    ...active.map((i) => _IntentionCard(intention: i, ref: ref)),
                  ],
                  if (completed.isNotEmpty) ...[
                    const SectionHeader(title: 'Completed'),
                    ...completed.map((i) => _IntentionCard(intention: i, ref: ref)),
                  ],
                  if (other.isNotEmpty) ...[
                    const SectionHeader(title: 'Other'),
                    ...other.map((i) => _IntentionCard(intention: i, ref: ref)),
                  ],
                ])),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addIntention(BuildContext context, WidgetRef ref) async {
    final titleC = TextEditingController();
    final descC = TextEditingController();
    final result = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        decoration: const BoxDecoration(color: KarmaColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: KarmaColors.surfaceLighter, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('🎯 New Intention', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: KarmaColors.textPrimary)),
          const SizedBox(height: 16),
          TextField(controller: titleC, autofocus: true, style: const TextStyle(color: KarmaColors.textPrimary), decoration: const InputDecoration(hintText: 'What do you want to achieve?')),
          const SizedBox(height: 12),
          TextField(controller: descC, maxLines: 2, style: const TextStyle(color: KarmaColors.textPrimary), decoration: const InputDecoration(hintText: 'Description (optional)')),
          const SizedBox(height: 20),
          GradientButton(text: 'Add Intention', colors: [KarmaColors.wisdom, KarmaColors.primary], onPressed: () async {
            if (titleC.text.isEmpty) return;
            try {
              await ApiClient().post('/intentions', data: {'title': titleC.text, 'description': descC.text.isEmpty ? null : descC.text});
              if (ctx.mounted) Navigator.pop(ctx, true);
            } catch (_) {}
          }),
        ]),
      ),
    );
    if (result == true) ref.invalidate(intentionsProvider);
  }
}

class _IntentionCard extends StatelessWidget {
  final dynamic intention;
  final WidgetRef ref;
  const _IntentionCard({required this.intention, required this.ref});

  @override
  Widget build(BuildContext context) {
    final status = intention['status'] ?? 'ACTIVE';
    final isCompleted = status == 'COMPLETED';
    final progress = (intention['progress'] ?? 0).toDouble() / 100;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KarmaColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: isCompleted ? Border.all(color: KarmaColors.good.withValues(alpha: 0.3)) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isCompleted ? Icons.check_circle : Icons.flag, color: isCompleted ? KarmaColors.good : KarmaColors.wisdom, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(intention['title'] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: KarmaColors.textPrimary, decoration: isCompleted ? TextDecoration.lineThrough : null))),
          if (!isCompleted)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: KarmaColors.textHint, size: 20),
              color: KarmaColors.surfaceLighter,
              onSelected: (value) async {
                try {
                  if (value == 'complete') {
                    await ApiClient().patch('/intentions/${intention['id']}', data: {'status': 'COMPLETED', 'progress': 100});
                  } else if (value == 'delete') {
                    await ApiClient().delete('/intentions/${intention['id']}');
                  }
                  ref.invalidate(intentionsProvider);
                } catch (_) {}
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'complete', child: Text('Mark Complete', style: TextStyle(color: KarmaColors.good))),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: KarmaColors.negative))),
              ],
            ),
        ]),
        if (intention['description'] != null) ...[
          const SizedBox(height: 6),
          Text(intention['description'], style: const TextStyle(fontSize: 13, color: KarmaColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        if (!isCompleted) ...[
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: KarmaColors.surfaceLighter, color: KarmaColors.wisdom, minHeight: 5)),
        ],
      ]),
    );
  }
}
