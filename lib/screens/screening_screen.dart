import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/screening_record.dart';
import '../state/app_state.dart';
import 'result_screen.dart';

class ScreeningScreen extends StatelessWidget {
  const ScreeningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.t('speechCheck'),
          style: const TextStyle(
            color: AppTheme.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.navy),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              children: [
                // Prompter - الجملة المقترحة للقراءة
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.navy,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.navy.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.t('readAloud'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.t('screeningPrompt'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // دائرة التسجيل والعداد
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // تأثير النبض (Pulse Effect)
                      if (state.isRecording)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1.0, end: 1.3),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeInOut,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.coral.withValues(alpha: 0.1),
                                ),
                              ),
                            );
                          },
                        ),
                      // الزر الرئيسي
                      GestureDetector(
                        onTap:
                            state.isAnalyzing
                                ? null
                                : () => _recordAction(context, state),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: state.isRecording ? 120 : 140,
                          height: state.isRecording ? 120 : 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                state.isRecording
                                    ? AppTheme.coral
                                    : AppTheme.teal,
                            boxShadow: [
                              BoxShadow(
                                color: (state.isRecording
                                        ? AppTheme.coral
                                        : AppTheme.teal)
                                    .withValues(alpha: 0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child:
                              state.isAnalyzing
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  )
                                  : Icon(
                                    state.isRecording
                                        ? Icons.stop_rounded
                                        : Icons.mic_rounded,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // الوقت وحالة التسجيل
                Center(
                  child: Text(
                    state.isRecording
                        ? _formatSeconds(state.recordingSeconds)
                        : l10n.t('tapToStart'),
                    style: TextStyle(
                      fontSize: state.isRecording ? 36 : 20,
                      fontWeight: FontWeight.w900,
                      color: state.isRecording ? AppTheme.coral : AppTheme.navy,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),

                if (state.errorMessage != null) ...[
                  const SizedBox(height: 24),
                  _ErrorPanel(message: l10n.translateKnown(state.errorMessage!)),
                ],
              ],
            ),
          ),

          // قسم الأزرار السفلية (Upload & Checklist)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed:
                      state.isAnalyzing || state.isRecording
                          ? null
                          : () => _analyzeUpload(context, state),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.teal, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(
                    Icons.audio_file_outlined,
                    color: AppTheme.teal,
                  ),
                  label: Text(
                    l10n.t('uploadAudio'),
                    style: const TextStyle(
                      color: AppTheme.teal,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const _CompactQualityChecklist(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _recordAction(BuildContext context, AppState state) async {
    ScreeningRecord? record;
    if (state.isRecording) {
      record = await state.stopAndAnalyze();
    } else {
      await state.startRecording();
    }
    if (record != null && context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ResultScreen(record: record!)),
      );
    }
  }

  Future<void> _analyzeUpload(BuildContext context, AppState state) async {
    final record = await state.pickAndAnalyzeFile();
    if (record != null && context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ResultScreen(record: record)),
      );
    }
  }

  String _formatSeconds(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }
}

// قائمة التحقق المدمجة والمبسطة
class _CompactQualityChecklist extends StatelessWidget {
  const _CompactQualityChecklist();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCheckItem(Icons.volume_off_rounded, l10n.t('quietRoom')),
        _buildCheckItem(Icons.straighten_rounded, l10n.t('distanceHint')),
        _buildCheckItem(Icons.timer_rounded, l10n.t('durationHint')),
      ],
    );
  }

  Widget _buildCheckItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.coral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.coral.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.coral),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.coral,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
