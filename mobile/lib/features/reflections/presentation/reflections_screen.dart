import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

class ReflectionsScreen extends ConsumerStatefulWidget {
  const ReflectionsScreen({super.key});

  @override
  ConsumerState<ReflectionsScreen> createState() => _ReflectionsScreenState();
}

class _ReflectionsScreenState extends ConsumerState<ReflectionsScreen> {
  bool _isGenerating = false;

  Future<void> _generateReflection(String type) async {
    setState(() => _isGenerating = true);
    try {
      await ApiClient().post('/reflections', data: {'reflectionType': type});
      ref.invalidate(reflectionsProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate reflection')));
    }
    setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    final reflectionsAsync = ref.watch(reflectionsProvider);
    final auth = ref.watch(authProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(reflectionsProvider),
      color: KarmaColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(floating: true, backgroundColor: KarmaColors.background, title: const Text('Reflections'), automaticallyImplyLeading: false),

          // Generate buttons
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(children: [
              if (!auth.state.aiAvailable)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: KarmaColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: KarmaColors.warning.withValues(alpha: 0.3))),
                    child: const Row(children: [
                      Icon(Icons.info_outline, color: KarmaColors.warning, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text('AI is temporarily unavailable. Reflections will use local analysis instead.', style: TextStyle(fontSize: 12, color: KarmaColors.warning))),
                    ]),
                  ),
                ),
              Row(children: [
                _GenButton(label: 'Daily', icon: '☀️', color: KarmaColors.good, isLoading: _isGenerating, onTap: () => _generateReflection('DAILY')),
                const SizedBox(width: 8),
                _GenButton(label: 'Weekly', icon: '📅', color: KarmaColors.primary, isLoading: _isGenerating, onTap: () => _generateReflection('WEEKLY')),
                const SizedBox(width: 8),
                _GenButton(label: 'Monthly', icon: '🌙', color: KarmaColors.accent, isLoading: _isGenerating, onTap: () => _generateReflection('MONTHLY')),
                const SizedBox(width: 8),
                _GenButton(label: 'Yearly', icon: '⭐', color: KarmaColors.warning, isLoading: _isGenerating, onTap: () => _generateReflection('YEARLY')),
              ]),
            ]),
          )),

          // Reflection list
          reflectionsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: KarmaColors.primary))),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Failed to load', style: TextStyle(color: KarmaColors.textHint)))),
            data: (reflections) {
              if (reflections.isEmpty) return const SliverFillRemaining(child: EmptyState(icon: Icons.self_improvement, title: 'No reflections yet', subtitle: 'Generate your first reflection above'));

              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (_, i) => _ReflectionCard(reflection: reflections[i]),
                  childCount: reflections.length,
                )),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GenButton extends StatelessWidget {
  final String label, icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;
  const _GenButton({required this.label, required this.icon, required this.color, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    ));
  }
}

class _ReflectionCard extends StatelessWidget {
  final dynamic reflection;
  const _ReflectionCard({required this.reflection});

  @override
  Widget build(BuildContext context) {
    final type = reflection['reflectionType'] ?? 'DAILY';
    final text = reflection['generatedText'] ?? '';
    final isAI = reflection['isAI'] ?? true;
    final createdAt = DateTime.tryParse(reflection['createdAt'] ?? '') ?? DateTime.now();
    final typeColors = {'DAILY': KarmaColors.good, 'WEEKLY': KarmaColors.primary, 'MONTHLY': KarmaColors.accent, 'YEARLY': KarmaColors.warning};
    final color = typeColors[type] ?? KarmaColors.primary;

    return GlassCard(
      borderColor: color.withValues(alpha: 0.3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(type, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          AIStatusBadge(isAI: isAI),
        ]),
        const SizedBox(height: 14),
        Text(text, style: const TextStyle(fontSize: 14, color: KarmaColors.textPrimary, height: 1.6)),
        const SizedBox(height: 10),
        Text('${createdAt.day}/${createdAt.month}/${createdAt.year}', style: const TextStyle(fontSize: 11, color: KarmaColors.textHint)),
      ]),
    );
  }
}
