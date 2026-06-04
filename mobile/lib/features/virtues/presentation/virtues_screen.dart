import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

class VirtuesScreen extends ConsumerWidget {
  const VirtuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final virtuesAsync = ref.watch(userVirtuesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(userVirtuesProvider),
      color: KarmaColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(floating: true, backgroundColor: KarmaColors.background, title: const Text('Your Virtues'), automaticallyImplyLeading: false),
          virtuesAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: KarmaColors.primary))),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Failed to load', style: TextStyle(color: KarmaColors.textHint)))),
            data: (virtues) {
              if (virtues.isEmpty) return const SliverFillRemaining(child: EmptyState(icon: Icons.auto_awesome, title: 'No virtues yet', subtitle: 'Log your first action to start tracking virtues'));

              // Sort by score desc
              final sorted = List.from(virtues)..sort((a, b) => ((b['score'] ?? 0) as num).compareTo((a['score'] ?? 0) as num));
              final topVirtues = sorted.take(8).toList();

              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  // Radar Chart
                  if (topVirtues.length >= 3) ...[
                    const SectionHeader(title: 'Virtue Map'),
                    SizedBox(
                      height: 280,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: RadarChart(RadarChartData(
                          radarShape: RadarShape.polygon,
                          tickCount: 4,
                          ticksTextStyle: const TextStyle(color: Colors.transparent),
                          radarBorderData: BorderSide(color: KarmaColors.surfaceLighter, width: 0.5),
                          gridBorderData: BorderSide(color: KarmaColors.surfaceLighter.withValues(alpha: 0.3), width: 0.5),
                          tickBorderData: BorderSide(color: KarmaColors.surfaceLighter.withValues(alpha: 0.2), width: 0.5),
                          titlePositionPercentageOffset: 0.2,
                          getTitle: (i, _) => RadarChartTitle(
                            text: topVirtues[i]['virtue']?['icon'] ?? '⭐',
                            angle: 0,
                          ),
                          dataSets: [
                            RadarDataSet(
                              fillColor: KarmaColors.primary.withValues(alpha: 0.2),
                              borderColor: KarmaColors.primary,
                              borderWidth: 2,
                              entryRadius: 4,
                              dataEntries: topVirtues.map<RadarEntry>((v) => RadarEntry(value: ((v['score'] ?? 0) as num).toDouble().clamp(0, 500))).toList(),
                            ),
                          ],
                        )),
                      ),
                    ),
                  ],

                  // Virtue Cards
                  const SectionHeader(title: 'All Virtues'),
                  ...sorted.map((uv) => _VirtueCard(userVirtue: uv)),
                ])),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VirtueCard extends StatelessWidget {
  final dynamic userVirtue;
  const _VirtueCard({required this.userVirtue});

  @override
  Widget build(BuildContext context) {
    final virtue = userVirtue['virtue'] ?? {};
    final name = virtue['name'] ?? '';
    final icon = virtue['icon'] ?? '⭐';
    final desc = virtue['description'] ?? '';
    final score = (userVirtue['score'] ?? 0).toDouble();
    final level = userVirtue['level'] ?? 1;
    final color = KarmaColors.getVirtueColor(name);
    final progress = (score % 100) / 100;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KarmaColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            Text(desc, style: const TextStyle(fontSize: 12, color: KarmaColors.textHint), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Lv. $level', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            Text('${score.toInt()} pts', style: const TextStyle(fontSize: 11, color: KarmaColors.textSecondary)),
          ]),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress, backgroundColor: KarmaColors.surfaceLighter, color: color, minHeight: 5),
        ),
        const SizedBox(height: 4),
        Align(alignment: Alignment.centerRight, child: Text('${(progress * 100).toInt()}% to next level', style: const TextStyle(fontSize: 10, color: KarmaColors.textHint))),
      ]),
    );
  }
}
