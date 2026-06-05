import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../app/providers.dart';

class WishesScreen extends ConsumerStatefulWidget {
  const WishesScreen({super.key});

  @override
  ConsumerState<WishesScreen> createState() => _WishesScreenState();
}

class _WishesScreenState extends ConsumerState<WishesScreen> {
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final wishesAsync = ref.watch(wishesProvider);
    final virtuesAsync = ref.watch(userVirtuesProvider);

    return Scaffold(
      backgroundColor: KarmaColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [KarmaColors.primary, KarmaColors.accent]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text('Wishes & Worthiness', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(wishesProvider);
              ref.invalidate(userVirtuesProvider);
            },
          ),
        ],
      ),
      body: wishesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: KarmaColors.primary)),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: KarmaColors.negative),
              const SizedBox(height: 16),
              Text('Failed to load wishes: $err', style: const TextStyle(color: KarmaColors.textSecondary)),
            ],
          ),
        ),
        data: (wishes) {
          final virtues = virtuesAsync.value ?? [];

          if (wishes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: KarmaColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: KarmaColors.surfaceLighter),
                    ),
                    child: const Icon(Icons.auto_awesome, size: 40, color: KarmaColors.textHint),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No wishes yet',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: KarmaColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Ask for a blessing. AI will determine the virtues you need to cultivate to make it possible.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: KarmaColors.textSecondary, fontSize: 14, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 32),
                  GradientButton(
                    text: 'Make a Wish',
                    width: 180,
                    onPressed: _showCreateWishDialog,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: wishes.length,
            itemBuilder: (context, index) {
              final wish = wishes[index];
              final String id = wish['id'];
              final String title = wish['title'] ?? '';
              final String description = wish['description'] ?? '';
              final String virtueName = wish['virtueName'] ?? '';
              final int reqLevel = wish['requiredLevel'] ?? 1;
              final String status = wish['status'] ?? 'PENDING';

              final userVirtue = virtues.firstWhere(
                (element) => (element['virtue']?['name'] as String?)?.toLowerCase() == virtueName.toLowerCase(),
                orElse: () => null,
              );
              final userLevel = userVirtue?['level'] ?? 1;
              final isWorthy = userLevel >= reqLevel;
              final isGranted = status == 'GRANTED';

              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: KarmaColors.textPrimary,
                                decoration: isGranted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: KarmaColors.textHint, size: 20),
                            onPressed: () => _deleteWish(id),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(color: KarmaColors.textSecondary.withValues(alpha: 0.9), fontSize: 14, height: 1.4),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(color: KarmaColors.surfaceLighter, height: 1),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Required Alignment',
                                style: TextStyle(color: KarmaColors.textHint, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    virtueName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: KarmaColors.primaryLight, fontSize: 14),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: KarmaColors.surfaceLighter,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Level $reqLevel',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your Level: $userLevel',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isWorthy ? KarmaColors.good : KarmaColors.warning,
                                ),
                              ),
                            ],
                          ),
                          if (isGranted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: KarmaColors.good.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: KarmaColors.good.withValues(alpha: 0.2)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, size: 16, color: KarmaColors.good),
                                  SizedBox(width: 6),
                                  Text(
                                    'Granted',
                                    style: TextStyle(color: KarmaColors.good, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          else if (isWorthy)
                            GradientButton(
                              text: 'Grant Wish',
                              width: 110,
                              colors: const [KarmaColors.good, KarmaColors.goodLight],
                              onPressed: () => _grantWish(id, title),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: KarmaColors.surfaceLighter.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_outline, size: 14, color: KarmaColors.textHint),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Not Worthy Yet',
                                    style: TextStyle(color: KarmaColors.textHint, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: wishesAsync.when(
        data: (wishes) => wishes.isEmpty
            ? const SizedBox.shrink()
            : FloatingActionButton(
                backgroundColor: KarmaColors.primary,
                onPressed: _showCreateWishDialog,
                child: const Icon(Icons.add, color: Colors.white),
              ),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Future<void> _showCreateWishDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSheet) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: KarmaColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: KarmaColors.surfaceLighter, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(
                'Make a Wish',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: KarmaColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'AI will analyze it to set the required virtue and level.',
                style: TextStyle(color: KarmaColors.textHint, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                autofocus: true,
                style: const TextStyle(color: KarmaColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Wish Title',
                  hintText: 'e.g., Get accepted to graduate school',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                style: const TextStyle(color: KarmaColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Details about your wish...',
                ),
              ),
              const SizedBox(height: 24),
              _isCreating
                  ? const Center(child: CircularProgressIndicator(color: KarmaColors.primary))
                  : GradientButton(
                      text: 'Create Wish',
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) return;

                        setStateSheet(() => _isCreating = true);
                        try {
                          await ApiClient().post('/wishes', data: {
                            'title': title,
                            'description': descController.text.trim(),
                          });
                          ref.invalidate(wishesProvider);
                          ref.invalidate(dashboardProvider);
                          if (mounted) Navigator.pop(ctx);
                        } catch (_) {
                          if (mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Failed to create wish'), backgroundColor: KarmaColors.negative),
                            );
                          }
                        } finally {
                          setStateSheet(() => _isCreating = false);
                        }
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _grantWish(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KarmaColors.surface,
        title: Text('Grant Wish?', style: GoogleFonts.outfit(color: KarmaColors.textPrimary)),
        content: Text(
          'Granting "$title" will deduct virtue points to balance the karma scales. Proceed?',
          style: const TextStyle(color: KarmaColors.textSecondary),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: KarmaColors.textHint)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          GradientButton(
            text: 'Yes, Grant',
            width: 110,
            colors: const [KarmaColors.good, KarmaColors.goodLight],
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiClient().post('/wishes/$id/grant');
        ref.invalidate(wishesProvider);
        ref.invalidate(dashboardProvider);
        ref.invalidate(userVirtuesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wish granted! Blessings aligned. ✨'), backgroundColor: KarmaColors.good),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to grant wish'), backgroundColor: KarmaColors.negative),
          );
        }
      }
    }
  }

  Future<void> _deleteWish(String id) async {
    try {
      await ApiClient().delete('/wishes/$id');
      ref.invalidate(wishesProvider);
      ref.invalidate(dashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wish removed'), backgroundColor: KarmaColors.surfaceLighter),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove wish'), backgroundColor: KarmaColors.negative),
        );
      }
    }
  }
}
