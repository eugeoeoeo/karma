import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

class StoryScreen extends ConsumerStatefulWidget {
  const StoryScreen({super.key});

  @override
  ConsumerState<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends ConsumerState<StoryScreen> {
  bool _isGenerating = false;

  Future<void> _generateChapter() async {
    setState(() => _isGenerating = true);
    try {
      await ApiClient().post('/story/generate');
      ref.invalidate(storyProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate chapter')));
    }
    setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    final storyAsync = ref.watch(storyProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true, backgroundColor: KarmaColors.background,
          title: const Text('Your Life Story'), automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: _isGenerating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: KarmaColors.primary, strokeWidth: 2)) : const Icon(Icons.auto_stories, color: KarmaColors.primary),
              onPressed: _isGenerating ? null : _generateChapter,
              tooltip: 'Generate new chapter',
            ),
            const SizedBox(width: 8),
          ],
        ),
        storyAsync.when(
          loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: KarmaColors.primary))),
          error: (e, _) => SliverFillRemaining(child: Center(child: Text('Failed to load', style: TextStyle(color: KarmaColors.textHint)))),
          data: (chapters) {
            if (chapters.isEmpty) {
              return SliverFillRemaining(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const EmptyState(icon: Icons.auto_stories, title: 'Your story begins here', subtitle: 'Generate your first life chapter based on your actions and reflections'),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: GradientButton(text: 'Generate Chapter', icon: Icons.auto_stories, isLoading: _isGenerating, onPressed: _isGenerating ? null : _generateChapter),
                ),
              ]));
            }

            return SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (_, i) => _ChapterCard(chapter: chapters[i], index: i),
                childCount: chapters.length,
              )),
            );
          },
        ),
      ],
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final dynamic chapter;
  final int index;
  const _ChapterCard({required this.chapter, required this.index});

  @override
  Widget build(BuildContext context) {
    final title = chapter['chapterTitle'] ?? 'Chapter ${index + 1}';
    final story = chapter['generatedStory'] ?? '';
    final createdAt = DateTime.tryParse(chapter['createdAt'] ?? '') ?? DateTime.now();

    return GlassCard(
      borderColor: KarmaColors.wisdom.withValues(alpha: 0.3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: KarmaColors.wisdom)),
        const SizedBox(height: 6),
        Text('${createdAt.day}/${createdAt.month}/${createdAt.year}', style: const TextStyle(fontSize: 12, color: KarmaColors.textHint)),
        const SizedBox(height: 16),
        Text(story, style: GoogleFonts.inter(fontSize: 14, color: KarmaColors.textPrimary, height: 1.7)),
      ]),
    );
  }
}
