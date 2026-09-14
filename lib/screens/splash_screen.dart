import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';

class SplashScreen extends StatelessWidget {
  // هذا هو المُنشئ الثابت الذي كان يبحث عنه التطبيق
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppTheme.navy, // خلفية داكنة فخمة تعكس الاحترافية
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.elasticOut, // حركة مرنة (Bounce) ناعمة
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الأيقونة مع تأثير التوهج (Glow Effect)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.teal.withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: AppTheme.teal,
                  size: 72,
                ),
              ),
              const SizedBox(height: 32),

              // اسم التطبيق بتنسيق عصري
              Text(
                l10n.t('splashName'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),

              // الوصف الفرعي
              Text(
                l10n.t('splashTagline'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 16,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
