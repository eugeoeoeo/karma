import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    final success = await ref.read(authProvider).login(_emailController.text.trim(), _passwordController.text);
    if (success && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoading = auth.state.status == AuthStatus.loading;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0D1A), Color(0xFF1A1035), Color(0xFF0D0D1A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.07),
                    // Cold-start warning banner
                    if (isLoading)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: KarmaColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: KarmaColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Row(children: [
                          SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 1.5, color: KarmaColors.primary)),
                          SizedBox(width: 10),
                          Expanded(child: Text('Connecting to server... (first start may take up to 60s)', style: TextStyle(fontSize: 12, color: KarmaColors.primary))),
                        ]),
                      ),
                    // Logo area
                    Center(
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [KarmaColors.primary, KarmaColors.accent]),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: KarmaColors.primary.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 10))],
                        ),
                        child: const Icon(Icons.auto_awesome, size: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Center(
                      child: Text('Welcome Back', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700, color: KarmaColors.textPrimary)),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text('Continue your growth journey', style: TextStyle(fontSize: 16, color: KarmaColors.textSecondary)),
                    ),
                    const SizedBox(height: 48),

                    // Error message
                    if (auth.state.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: KarmaColors.negative.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: KarmaColors.negative.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: KarmaColors.negative, size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text(auth.state.error!, style: const TextStyle(color: KarmaColors.negative, fontSize: 14))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Email field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: KarmaColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined, color: KarmaColors.textHint),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: KarmaColors.textPrimary),
                      onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, color: KarmaColors.textHint),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: KarmaColors.textHint),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Login button
                    GradientButton(text: 'Sign In', isLoading: isLoading, onPressed: isLoading ? null : _login),
                    const SizedBox(height: 24),

                    // Register link
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go('/register'),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 15, color: KarmaColors.textSecondary),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(text: 'Sign Up', style: TextStyle(color: KarmaColors.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
