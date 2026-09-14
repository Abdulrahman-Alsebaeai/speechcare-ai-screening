import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../widgets/health_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = context.l10n;
    // تعيين الاسم الافتراضي ليعكس الاحترافية إذا كان فارغاً
    final userName = state.currentUser?.name ?? l10n.t('defaultUser');
    final userEmail = state.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.t('profileSettings'),
          style: const TextStyle(
            color: AppTheme.navy,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // بطاقة الملف الشخصي (Profile Header)
          HealthCard(
            color: AppTheme.teal,
            child: Row(
              children: [
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 3,
                    ),
                    image: DecorationImage(
                      image: const NetworkImage(
                        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=1974&auto=format&fit=crop',
                      ),
                      onError: (_, __) {},
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text(
            l10n.t('preferences'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 16),
          HealthCard(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: _LanguageRow(
              currentLocale: state.locale,
              onChanged: (locale) => state.setLocale(locale),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            l10n.t('systemDetails'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 16),
          HealthCard(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.storage_rounded,
                  title: l10n.t('localRecords'),
                  subtitle: l10n.t('sqliteStorage'),
                  trailingText: l10n.scansCount(state.records.length),
                ),
                Divider(height: 1, color: Colors.grey.shade100, indent: 64),
                _SettingsRow(
                  icon: Icons.api_rounded,
                  title: l10n.t('fastApiIntegration'),
                  subtitle: l10n.t('backendRoute'),
                  trailingText:
                      state.mockMode ? l10n.t('mocked') : l10n.t('live'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // أزرار التحكم
          OutlinedButton.icon(
            onPressed:
                state.records.isEmpty ? null : () => state.clearHistory(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: AppTheme.coral,
              side: const BorderSide(color: AppTheme.coral, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.delete_sweep_rounded),
            label: Text(
              l10n.t('clearHistory'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: state.logout,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.navy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: Text(
              l10n.t('signOut'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.currentLocale,
    required this.onChanged,
  });

  final Locale currentLocale;
  final ValueChanged<Locale> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value =
        currentLocale.languageCode == 'ar' ? const Locale('ar') : const Locale('en');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.language_rounded,
          color: AppTheme.teal,
          size: 22,
        ),
      ),
      title: Text(
        l10n.t('language'),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(
        l10n.t('languageSubtitle'),
        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      ),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: value,
          borderRadius: BorderRadius.circular(16),
          items: [
            DropdownMenuItem(
              value: const Locale('en'),
              child: Text(l10n.t('english')),
            ),
            DropdownMenuItem(
              value: const Locale('ar'),
              child: Text(l10n.t('arabic')),
            ),
          ],
          onChanged: (locale) {
            if (locale != null) onChanged(locale);
          },
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailingText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailingText;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.teal, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          trailingText,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppTheme.navy,
          ),
        ),
      ),
    );
  }
}
