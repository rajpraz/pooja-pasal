import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';

/// Shared look of the login and sign-up screens: mandala backdrop, diya
/// medallion, floating white card, Login / Create Account switch.

/// Faint mandala ring and stars behind the content.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(child: CustomPaint(painter: _BackdropPainter(AppColors.accent))),
    );
  }
}

/// Fades the content in and slides it up when the screen opens.
class AuthEntrance extends StatelessWidget {
  const AuthEntrance({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

/// Dark medallion with a glowing diya flame.
class DiyaLogo extends StatelessWidget {
  const DiyaLogo({super.key, this.size = 112});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(colors: [Color(0xFF6B2E12), Color(0xFF2A0E06)]),
        border: Border.all(color: const Color(0xFFFFB300), width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA000).withValues(alpha: 0.55),
            blurRadius: 36,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(Icons.local_fire_department_rounded,
          color: const Color(0xFFFFC53D), size: size * 0.46),
    );
  }
}

/// The white rounded card the forms sit in.
class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.16),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Small uppercase caption above a field.
class AuthLabel extends StatelessWidget {
  const AuthLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.text,
        ),
      ),
    );
  }
}

/// Orange gradient call-to-action; shows a spinner while [loading].
class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.icon = Icons.arrow_forward,
  });

  final String label;
  final VoidCallback onTap;
  final bool loading;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [AppColors.accent, const Color(0xFFFFA000)]),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: loading ? null : onTap,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 16.5, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(width: 8),
                      Icon(icon, size: 19, color: Colors.white),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Login / Create Account pill switch; the active side is highlighted and
/// the other side calls its callback.
class AuthModeSwitch extends StatelessWidget {
  const AuthModeSwitch({
    super.key,
    required this.loginActive,
    required this.onLogin,
    required this.onSignUp,
  });

  final bool loginActive;
  final VoidCallback onLogin;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tab(Icons.login, 'Login', loginActive, loginActive ? null : onLogin),
          ),
          Expanded(
            child: _tab(Icons.person_add_alt_1, 'Create Account', !loginActive,
                loginActive ? onSignUp : null),
          ),
        ],
      ),
    );
  }

  Widget _tab(IconData icon, String label, bool active, VoidCallback? onTap) {
    final color = active ? Colors.white : AppColors.text;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: active
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(colors: [AppColors.accentDark, AppColors.accent]),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.38);
    final radius = size.width * 0.78;
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color.withValues(alpha: 0.14);
    const segments = 72;
    for (var i = 0; i < segments; i++) {
      final a = i * 2 * math.pi / segments;
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius), a, math.pi / segments * 0.8, false, dash);
    }
    canvas.drawCircle(center, radius * 0.72, dash..color = color.withValues(alpha: 0.08));

    // Four-point stars.
    final fill = Paint()..color = color.withValues(alpha: 0.07);
    void star(Offset c, double r) {
      final p = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r);
      canvas.drawPath(p, fill);
    }

    star(Offset(size.width * 0.9, size.height * 0.4), 90);
    star(Offset(size.width * 0.08, size.height * 0.55), 60);
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter old) => old.color != color;
}
