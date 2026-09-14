import 'package:flutter/material.dart';

class AppTheme {
  // الألوان الأساسية (حافظنا عليها لأنها ممتازة جداً ومناسبة للقطاع الطبي/التقني)
  static const Color navy = Color(0xFF10243E);
  static const Color teal = Color(0xFF0E8F8F);
  static const Color mint = Color(0xFF52C7B8);
  static const Color coral = Color(0xFFE86D5A);
  static const Color amber = Color(0xFFF5B84B);
  static const Color cloud = Color(
    0xFFF9FAFC,
  ); // تفتيح بسيط جداً لخلفية أريح للعين
  static const Color ink = Color(0xFF1D2939);

  // الثيم الفاتح (Light Theme)
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: Brightness.light,
      primary: teal,
      secondary: coral,
      surface: Colors.white,
      onSurface: navy,
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: cloud,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: cloud,
        foregroundColor: navy,
        surfaceTintColor:
            Colors.transparent, // منع تغير لون الـ AppBar عند التمرير
        titleTextStyle: const TextStyle(
          color: navy,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          fontFamily: 'Inter', // أو Roboto
        ),
      ),
    );
  }

  // الثيم الداكن (Dark Theme) - تم تحسينه ليكون أكثر فخامة (Deep Dark)
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: mint,
      brightness: Brightness.dark,
      primary: mint,
      secondary: amber,
      surface: const Color(0xFF1E293B), // أزرق رمادي داكن فخم
      onSurface: Colors.white,
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  // القاعدة الأساسية الموحدة للثيمين (Base Theme)
  static ThemeData _base(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily:
          'Inter', // يفضل استخدام خطوط عصرية مثل Inter أو Poppins إن أمكن، أو إبقاؤها على Roboto
      // حركات تنقل عصرية بين الواجهات (Fade & Slide)
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // تنسيق البطاقات (Cards)
      cardTheme: CardTheme(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // حواف ناعمة جداً وفخمة
        ),
      ),

      // تنسيق الأزرار المعبأة (Primary Buttons)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56), // زر أكبر وأوضح
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: isDark ? navy : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // تنسيق الأزرار المفرغة (Outlined Buttons)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          foregroundColor: scheme.primary,
          side: BorderSide(
            color: scheme.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // تنسيق حقول الإدخال (TextFields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        prefixIconColor: isDark ? Colors.grey.shade400 : Colors.grey.shade500,

        // الحدود في الحالة العادية
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
          ),
        ),

        // الحدود عند التركيز (Focus)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),

        // الحدود عند الخطأ (Error)
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
    );
  }
}
