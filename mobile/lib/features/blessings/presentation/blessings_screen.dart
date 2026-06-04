import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

class BlessingsScreen extends ConsumerWidget {
  const BlessingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blessingsAsync = ref.watch(blessingsProvider(1));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(blessingsProvider(1)),
      color: KarmaColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true, backgroundColor: KarmaColors.background,
            title: const Text('Blessing Journal'), automaticallyImplyLeading: false,
            actions: [
              IconButton(icon: const Icon(Icons.add_circle_outline, color: KarmaColors.accent), onPressed: () => _addBlessing(context, ref)),
              const SizedBox(width: 8),
            ],
          ),
          blessingsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: KarmaColors.primary))),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Failed to load', style: TextStyle(color: KarmaColors.textHint)))),
            data: (data) {
              final blessings = (data['blessings'] as List?) ?? [];
              if (blessings.isEmpty) {
                return SliverFillRemaining(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const EmptyState(icon: Icons.favorite, title: 'No blessings yet', subtitle: 'Record the good things in your life'),
                  GradientButton(text: 'Add Blessing', icon: Icons.add, colors: [KarmaColors.accent, KarmaColors.primary], onPressed: () => _addBlessing(context, ref)),
                ]));
              }

              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (_, i) => _BlessingCard(blessing: blessings[i]),
                  childCount: blessings.length,
                )),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addBlessing(BuildContext context, WidgetRef ref) async {
    final titleC = TextEditingController();
    final descC = TextEditingController();
    String type = 'UNEXPECTED';

    final result = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        decoration: const BoxDecoration(color: KarmaColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: KarmaColors.surfaceLighter, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('🙏 Record Blessing', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: KarmaColors.textPrimary)),
          const SizedBox(height: 16),
          TextField(controller: titleC, autofocus: true, style: const TextStyle(color: KarmaColors.textPrimary), decoration: const InputDecoration(hintText: 'What blessing did you receive?')),
          const SizedBox(height: 12),
          TextField(controller: descC, maxLines: 2, style: const TextStyle(color: KarmaColors.textPrimary), decoration: const InputDecoration(hintText: 'Details (optional)')),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => setS(() => type = 'UNEXPECTED'),
              child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: type == 'UNEXPECTED' ? KarmaColors.accent.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: type == 'UNEXPECTED' ? KarmaColors.accent.withValues(alpha: 0.4) : KarmaColors.surfaceLighter)),
                child: Center(child: Text('✨ Unexpected', style: TextStyle(color: type == 'UNEXPECTED' ? KarmaColors.accent : KarmaColors.textHint, fontWeight: FontWeight.w500)))),
            )),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: () => setS(() => type = 'EXPECTED'),
              child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: type == 'EXPECTED' ? KarmaColors.good.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: type == 'EXPECTED' ? KarmaColors.good.withValues(alpha: 0.4) : KarmaColors.surfaceLighter)),
                child: Center(child: Text('🎯 Expected', style: TextStyle(color: type == 'EXPECTED' ? KarmaColors.good : KarmaColors.textHint, fontWeight: FontWeight.w500)))),
            )),
          ]),
          const SizedBox(height: 20),
          GradientButton(text: 'Save Blessing', colors: [KarmaColors.accent, KarmaColors.primary], onPressed: () async {
            if (titleC.text.isEmpty) return;
            try {
              await ApiClient().post('/blessings', data: {'title': titleC.text, 'description': descC.text.isEmpty ? null : descC.text, 'blessingType': type});
              if (ctx.mounted) Navigator.pop(ctx, true);
            } catch (_) {}
          }),
        ]),
      )),
    );
    if (result == true) ref.invalidate(blessingsProvider(1));
  }
}

class _BlessingCard extends StatelessWidget {
  final dynamic blessing;
  const _BlessingCard({required this.blessing});

  @override
  Widget build(BuildContext context) {
    final type = blessing['blessingType'] ?? 'UNEXPECTED';
    final significance = (blessing['significanceScore'] ?? 0).toDouble();
    final category = _getCategory(significance);
    final createdAt = DateTime.tryParse(blessing['createdAt'] ?? '') ?? DateTime.now();
    final isAI = blessing['aiAnalysis']?['isAI'] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KarmaColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KarmaColors.accent.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _getCategoryColor(category).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(category, style: TextStyle(fontSize: 11, color: _getCategoryColor(category), fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: KarmaColors.surfaceLighter, borderRadius: BorderRadius.circular(8)),
            child: Text(type == 'UNEXPECTED' ? '✨ Unexpected' : '🎯 Expected', style: const TextStyle(fontSize: 11, color: KarmaColors.textSecondary)),
          ),
          const Spacer(),
          AIStatusBadge(isAI: isAI),
        ]),
        const SizedBox(height: 12),
        Text(blessing['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: KarmaColors.textPrimary)),
        if (blessing['description'] != null) ...[
          const SizedBox(height: 4),
          Text(blessing['description'], style: const TextStyle(fontSize: 13, color: KarmaColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.stars, size: 16, color: KarmaColors.warning),
          const SizedBox(width: 4),
          Text('${significance.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: KarmaColors.warning)),
          const Spacer(),
          Text(timeago.format(createdAt), style: const TextStyle(fontSize: 12, color: KarmaColors.textHint)),
        ]),
        if (blessing['reflection'] != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: KarmaColors.surfaceLight.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
            child: Text(blessing['reflection'], style: const TextStyle(fontSize: 13, color: KarmaColors.textSecondary, fontStyle: FontStyle.italic, height: 1.4)),
          ),
        ],
      ]),
    );
  }

  String _getCategory(double sig) => sig < 500 ? 'Minor' : sig < 1500 ? 'Moderate' : sig < 3000 ? 'Major' : 'Extraordinary';
  Color _getCategoryColor(String cat) => cat == 'Minor' ? KarmaColors.textSecondary : cat == 'Moderate' ? KarmaColors.good : cat == 'Major' ? KarmaColors.primary : KarmaColors.warning;
}
