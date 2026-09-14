import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isRegistering = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppTheme.navy,
      // استخدام LayoutBuilder و SingleChildScrollView لضمان استجابة الواجهة للكيبورد
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    // 1. الخلفية العصرية مع الأشكال الهندسية (3D Floating Orbs Effect)
                    _buildBackgroundShapes(),

                    // 2. المحتوى الرئيسي (النصوص العلوية + البطاقة البيضاء السفلية)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // المساحة العلوية للترحيب
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 40,
                              left: 32,
                              right: 32,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.graphic_eq_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  _isRegistering
                                      ? l10n.t('createAccountTitle')
                                      : l10n.t('signInTitle'),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.2,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(), // لدفع البطاقة البيضاء للأسفل
                        const SizedBox(height: 40),

                        // 3. البطاقة البيضاء السفلية (Bottom Sheet Card) كما في الصورة
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 40,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // حقول الإدخال بالتصميم المبسط (Minimalist Underline)
                                if (_isRegistering) ...[
                                  _buildMinimalTextField(
                                    controller: _name,
                                    label: l10n.t('fullName'),
                                    hint: l10n.t('fullNameHint'),
                                    icon: Icons.person_outline_rounded,
                                    validator:
                                        (value) =>
                                            value == null ||
                                                    value.trim().length < 2
                                                ? l10n.t('validName')
                                                : null,
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                _buildMinimalTextField(
                                  controller: _email,
                                  label: l10n.t('emailAddress'),
                                  hint: l10n.t('emailHint'),
                                  icon: Icons.alternate_email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator:
                                      (value) =>
                                          value != null && value.contains('@')
                                              ? null
                                              : l10n.t('validEmail'),
                                ),
                                const SizedBox(height: 24),

                                _buildMinimalTextField(
                                  controller: _password,
                                  label: l10n.t('password'),
                                  hint: l10n.t('passwordHint'),
                                  icon: Icons.lock_outline_rounded,
                                  isObscure: true,
                                  validator:
                                      (value) =>
                                          value != null && value.length >= 6
                                              ? null
                                              : l10n.t('minimumPassword'),
                                ),

                                if (!_isRegistering) ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: TextButton(
                                      onPressed:
                                          () {}, // إضافة ميزة استعادة كلمة المرور مستقبلاً
                                      child: Text(
                                        l10n.t('forgotPassword'),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                // رسالة الخطأ
                                if (state.errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.translateKnown(state.errorMessage!),
                                    style: const TextStyle(
                                      color: AppTheme.coral,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],

                                const SizedBox(height: 40),

                                // زر التأكيد (Gradient Button) كما في الصورة
                                Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    gradient: const LinearGradient(
                                      colors: [AppTheme.navy, AppTheme.teal],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.teal.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: state.isBusy ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                    child:
                                        state.isBusy
                                            ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                            : Text(
                                              _isRegistering
                                                  ? l10n.t('signUpAction')
                                                  : l10n.t('signInAction'),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // نص التبديل بين الدخول والتسجيل (RichText Style)
                                GestureDetector(
                                  onTap:
                                      state.isBusy
                                          ? null
                                          : () => setState(() {
                                            _isRegistering = !_isRegistering;
                                          }),
                                  child: Center(
                                    child: RichText(
                                      text: TextSpan(
                                        text:
                                            _isRegistering
                                                ? l10n.t('alreadyHaveAccount')
                                                : l10n.t('dontHaveAccount'),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        children: [
                                          TextSpan(
                                            text:
                                                _isRegistering
                                                    ? l10n.t('signIn')
                                                    : l10n.t('signUp'),
                                            style: const TextStyle(
                                              color: AppTheme.navy,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // تصميم الحقول المفرغة (Underline Style) كما في الصورة الأولى
  Widget _buildMinimalTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isObscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppTheme.navy,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade300,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        floatingLabelBehavior:
            FloatingLabelBehavior.always, // إبقاء العنوان بالأعلى دائماً
        suffixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: false, // بدون خلفية
        contentPadding: const EdgeInsets.symmetric(vertical: 8),

        // خط سفلي فقط بدلاً من الإطار الكامل
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.teal, width: 2.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.coral, width: 1.5),
        ),
      ),
    );
  }

  // دالة لبناء الخلفية والكرات العائمة بدقة وبدون صور خارجية للحفاظ على الأداء
  Widget _buildBackgroundShapes() {
    return Stack(
      children: [
        // تدرج لوني للخلفية ككل
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.navy, AppTheme.navy.withValues(alpha: 0.8)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
        // دائرة علوية يمنى
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.teal.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // دائرة وسطى يسرى
        Positioned(
          top: 250,
          left: -80,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.mint.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // دائرة صغيرة لتأثير العمق
        Positioned(
          top: 150,
          right: 40,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.coral.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // تأثير التغبيش الزجاجي (Glassmorphism Effect) لجعل الكرات تظهر كأنها خلف الزجاج
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    if (_isRegistering) {
      state.register(_name.text, _email.text, _password.text);
    } else {
      state.login(_email.text, _password.text);
    }
  }
}
