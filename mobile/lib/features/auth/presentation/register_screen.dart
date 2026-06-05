import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  bool _obscure = true;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _localError = null);

    if (_emailController.text.trim().isEmpty || _usernameController.text.trim().isEmpty) {
      setState(() => _localError = 'Please fill in all fields');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() => _localError = 'Passwords do not match');
      return;
    }
    if (_passwordController.text.length < 8) {
      setState(() => _localError = 'Password must be at least 8 characters');
      return;
    }

    final success = await ref.read(authProvider).register(
      _emailController.text.trim(),
      _usernameController.text.trim(),
      _passwordController.text,
    );
    if (success && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoading = auth.state.status == AuthStatus.loading;
    final error = _localError ?? auth.state.error;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0D0D1A), Color(0xFF1A0A2E), Color(0xFF0D0D1A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.05),
                  // Cold-start warning banner
                  if (isLoading)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.3)),
                      ),
                      child: const Row(children: [
                        SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF6C5CE7))),
                        SizedBox(width: 10),
                        Expanded(child: Text('Connecting to server... (first start may take up to 60s)', style: TextStyle(fontSize: 12, color: Color(0xFF6C5CE7)))),
                      ]),
                    ),
                  Center(
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: KarmaColors.accent.withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(color: KarmaColors.accent.withValues(alpha: 0.5), width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(child: Text('Create Account', style: GoogleFonts.outfit(fontSize: 30, fontWeight: FontWeight.w700, color: KarmaColors.textPrimary))),
                  const SizedBox(height: 8),
                  const Center(child: Text('Begin your virtue journey', style: TextStyle(fontSize: 16, color: KarmaColors.textSecondary))),
                  const SizedBox(height: 36),

                  if (error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: KarmaColors.negative.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KarmaColors.negative.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: KarmaColors.negative, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(error, style: const TextStyle(color: KarmaColors.negative, fontSize: 14))),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: KarmaColors.textPrimary), decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: KarmaColors.textHint))),
                  const SizedBox(height: 14),
                  TextField(controller: _usernameController, style: const TextStyle(color: KarmaColors.textPrimary), decoration: const InputDecoration(hintText: 'Username', prefixIcon: Icon(Icons.person_outline, color: KarmaColors.textHint))),
                  const SizedBox(height: 14),
                  TextField(controller: _passwordController, obscureText: _obscure, style: const TextStyle(color: KarmaColors.textPrimary), decoration: InputDecoration(hintText: 'Password', prefixIcon: const Icon(Icons.lock_outline, color: KarmaColors.textHint), suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: KarmaColors.textHint), onPressed: () => setState(() => _obscure = !_obscure)))),
                  const SizedBox(height: 14),
                  TextField(controller: _confirmController, obscureText: true, style: const TextStyle(color: KarmaColors.textPrimary), onSubmitted: (_) => _register(), decoration: const InputDecoration(hintText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline, color: KarmaColors.textHint))),
                  const SizedBox(height: 28),

                  GradientButton(text: 'Create Account', isLoading: isLoading, colors: [KarmaColors.accent, KarmaColors.primary], onPressed: isLoading ? null : _register),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/login'),
                      child: RichText(text: const TextSpan(style: TextStyle(fontSize: 15, color: KarmaColors.textSecondary), children: [TextSpan(text: 'Already have an account? '), TextSpan(text: 'Sign In', style: TextStyle(color: KarmaColors.primary, fontWeight: FontWeight.w600))])),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
