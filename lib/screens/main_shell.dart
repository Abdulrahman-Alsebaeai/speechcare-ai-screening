import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'screening_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 2; // الرئيسية هي المنتصف
  final List<Widget?> _screens = List<Widget?>.filled(5, null);

  Widget _screenFor(int index) {
    return _screens[index] ??= switch (index) {
      0 => const ScreeningScreen(),
      1 => const HistoryScreen(),
      2 => const HomeScreen(),
      3 => const ProgressScreen(),
      4 => const ProfileScreen(),
      _ => const HomeScreen(),
    };
  }

  void _selectTab(int index) {
    if (_index == index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(key: ValueKey(_index), child: _screenFor(_index)),
      ),
      floatingActionButton: _buildCenterHomeItem(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  Widget _buildCustomBottomNavBar() {
    final l10n = context.l10n;
    return BottomAppBar(
      color: Colors.white, // خلفية بيضاء صافية
      surfaceTintColor: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 10.0,
      clipBehavior: Clip.antiAlias,
      elevation: 20,
      shadowColor: AppTheme.navy.withValues(
        alpha: 0.2,
      ), // ظل واضح ليفصل الشريط عن الخلفية
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 75,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.mic_rounded, l10n.t('record')),
            _buildNavItem(1, Icons.manage_history_rounded, l10n.t('history')),
            const SizedBox(width: 48), // مساحة للزر المركزي
            _buildNavItem(3, Icons.insights_rounded, l10n.t('stats')),
            _buildNavItem(4, Icons.person_rounded, l10n.t('profile')),
          ],
        ),
      ),
    );
  }

  // تصميم أيقونة ثابتة لا تغير حجمها ولا تزيح العناصر
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _index == index;
    return GestureDetector(
      onTap: () => _selectTab(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 26,
            // اللون التفاعلي الواضح (Teal عند التحديد، رمادي غامق عند عدم التحديد)
            color: isSelected ? AppTheme.teal : Colors.grey.shade600,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected ? AppTheme.teal : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // تصميم زر الرئيسية في المنتصف (Floating Action Button)
  Widget _buildCenterHomeItem() {
    final isSelected = _index == 2;
    return FloatingActionButton(
      elevation: 4,
      backgroundColor: isSelected ? AppTheme.teal : AppTheme.navy,
      shape: const CircleBorder(),
      onPressed: () => _selectTab(2),
      child: const Icon(
        Icons.space_dashboard_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
