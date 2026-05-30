import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth/auth_service.dart';
import '../../services/logging/error_logger.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    ref.listenManual(authStateProvider, (_, next) {
      if (next.value != null && mounted) {
        context.go('/library');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      await auth.signIn(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) context.go('/library');
    } on AuthException catch (e) {
      ErrorLogger.instance.capture(e, source: 'LoginScreen.signIn');
      if (mounted) setState(() => _error = e.message);
    } catch (e, stack) {
      ErrorLogger.instance.capture(e, stackTrace: stack, source: 'LoginScreen.signIn');
      if (mounted) setState(() => _error = 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 48,
                      height: 52,
                      child: CustomPaint(painter: _BindRunePainter()),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'EDDA',
                      style: TextStyle(
                        color: AuroraColors.auroraTeal,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        color: AuroraColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 40),

                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AuroraColors.auroraWarm.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AuroraColors.auroraWarm.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AuroraColors.auroraWarm,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _buildTextField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AuroraColors.textTertiary,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      onSubmitted: (_) => _signIn(),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: _loading
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AuroraColors.auroraTeal,
                                ),
                              ),
                            )
                          : AuroraButton(
                              label: 'Sign In',
                              icon: Icons.login_rounded,
                              onPressed: _signIn,
                            ),
                    ),
                    const SizedBox(height: 20),
                    _buildDividerWithText('or'),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: _googleLoading
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AuroraColors.textSecondary,
                                ),
                              ),
                            )
                          : _buildGoogleButton(),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: AuroraColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/signup'),
                          child: const Text(
                            'Create one',
                            style: TextStyle(
                              color: AuroraColors.auroraTeal,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _signInWithGoogle() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      await auth.signInWithGoogle();
      if (mounted) context.go('/library');
    } on AuthException catch (e) {
      ErrorLogger.instance.capture(e, source: 'LoginScreen.googleSignIn');
      if (mounted) setState(() => _error = e.message);
    } catch (e, stack) {
      ErrorLogger.instance.capture(e, stackTrace: stack, source: 'LoginScreen.googleSignIn');
      if (mounted) setState(() => _error = 'Google sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Widget _buildDividerWithText(String text) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: const Color(0xFF252E27).withOpacity(0.6),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: const TextStyle(
              color: AuroraColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: const Color(0xFF252E27).withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _signInWithGoogle,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AuroraColors.surface.withOpacity(0.75),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF252E27),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'G',
              style: TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Continue with Google',
              style: TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AuroraColors.surface.withOpacity(0.75),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF252E27),
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: AuroraColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AuroraColors.textTertiary, size: 20),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: const TextStyle(color: AuroraColors.textTertiary),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _BindRunePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final ember = Paint()
      ..color = AuroraColors.auroraTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    final lichen = Paint()
      ..color = AuroraColors.auroraGreen.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    final cx = w * 0.5;
    final top = h * 0.0;
    final bot = h * 1.0;
    final mid = h * 0.5;

    canvas.drawLine(Offset(cx, top), Offset(cx, bot), ember);

    final dRight = w * 0.95;
    canvas.drawLine(Offset(cx, top), Offset(dRight, mid), lichen);
    canvas.drawLine(Offset(dRight, mid), Offset(cx, bot), lichen);
    canvas.drawLine(Offset(cx, top), Offset(w * 0.05, mid), lichen);
    canvas.drawLine(Offset(w * 0.05, mid), Offset(cx, bot), lichen);

    final eTop = h * 0.22;
    final eMid = h * 0.38;
    final eBot = h * 0.54;
    final eRight = w * 0.82;
    canvas.drawLine(Offset(cx, eTop), Offset(eRight, eMid), ember);
    canvas.drawLine(Offset(eRight, eMid), Offset(cx, eBot), ember);

    final serifW = w * 0.12;
    final serifPaint = Paint()
      ..color = AuroraColors.auroraTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
        Offset(cx - serifW, top), Offset(cx + serifW, top), serifPaint);
    canvas.drawLine(
        Offset(cx - serifW, bot), Offset(cx + serifW, bot), serifPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
