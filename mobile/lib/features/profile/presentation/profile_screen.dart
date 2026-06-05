import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {

  Future<void> _logout() async {
    await ref.read(authProvider).logout();
  }

  Future<void> _showEditProfileDialog() async {
    final user = ref.read(authProvider).state.user ?? {};
    final controller = TextEditingController(text: user['username'] ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KarmaColors.surface,
        title: Text('Edit Profile', style: GoogleFonts.outfit(color: KarmaColors.textPrimary)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: KarmaColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'Enter new username',
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: KarmaColors.textHint)),
            onPressed: () => Navigator.pop(ctx),
          ),
          GradientButton(
            text: 'Save',
            width: 100,
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              final success = await ref.read(authProvider).updateProfile(newName);
              if (success) {
                ref.invalidate(dashboardProvider);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully! ✨'), backgroundColor: KarmaColors.good),
                  );
                }
              } else {
                if (ctx.mounted) {
                  final error = ref.read(authProvider).state.error ?? 'Failed to update profile';
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: KarmaColors.negative),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.state.user ?? {};
    final avatarStage = user['avatarStage'] ?? 1;

    // Avatar stage info
    final stageName = avatarStage == 1
        ? 'Seeker'
        : avatarStage == 2
            ? 'Apprentice'
            : avatarStage == 3
                ? 'Guardian'
                : avatarStage == 4
                    ? 'Sage'
                    : 'Enlightened';

    final stageDesc = avatarStage == 1
        ? 'Beginning your journey of self-discovery'
        : avatarStage == 2
            ? 'Developing consistent virtuous habits'
            : avatarStage == 3
                ? 'Your character shines with inner strength'
                : avatarStage == 4
                    ? 'Wisdom guides your every action'
                    : 'A beacon of light for those around you';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: KarmaColors.background,
          title: const Text('Profile & Soul Avatar'),
          automaticallyImplyLeading: false,
        ),
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),

              // Avatar Evolution Stage Card
              GlassCard(
                borderColor: KarmaColors.primary.withValues(alpha: 0.3),
                child: Column(
                  children: [
                    _AvatarWidget(stage: avatarStage),
                    const SizedBox(height: 16),
                    Text(
                      'Stage $avatarStage: $stageName',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: KarmaColors.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stageDesc,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: KarmaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Account Info Card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Account Details',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: KarmaColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: KarmaColors.primaryLight, size: 18),
                          onPressed: _showEditProfileDialog,
                        ),
                      ],
                    ),
                    const Divider(color: KarmaColors.surfaceLighter, height: 24),
                    _ProfileRow(label: 'Username', value: user['username'] ?? 'N/A'),
                    _ProfileRow(label: 'Email', value: user['email'] ?? 'N/A'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KarmaColors.negative,
                    side: const BorderSide(color: KarmaColors.negative, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: KarmaColors.textSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(color: KarmaColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

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
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: stageColors.cast<Color>()),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: stageColors.first.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 48),
    );
  }
}
