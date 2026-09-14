import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/screening_record.dart';
import '../state/app_state.dart';
import 'result_screen.dart';
import 'screening_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  final List<String> _carouselImages = [
    'https://images.unsplash.com/photo-1532094349884-543bc11b234d?q=80&w=2070&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?q=80&w=2070&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?q=80&w=2070&auto=format&fit=crop',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < _carouselImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = context.l10n;
    final latest = state.latestRecord;
    final records = state.records.reversed.toList();
    final riskCount =
        state.records.where((record) => record.result.riskDetected).length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: state.refreshHistory,
          color: AppTheme.teal,
          child: ListView(
            // تقليل المساحة العلوية لاستغلال الشاشة بشكل أفضل
            padding: const EdgeInsets.only(top: 12, bottom: 32),
            children: [
              // 1. الترويسة المخصصة (تقليل الهوامش الجانبية إلى 16 بدلاً من 24)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('goodMorning'),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.currentUser?.name.split(' ').first ??
                              l10n.t('defaultUser'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.navy,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            state.mockMode
                                ? AppTheme.amber.withValues(alpha: 0.15)
                                : AppTheme.teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              state.mockMode
                                  ? AppTheme.amber.withValues(alpha: 0.3)
                                  : AppTheme.teal.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            state.mockMode
                                ? Icons.science_rounded
                                : Icons.cloud_done_rounded,
                            size: 16,
                            color:
                                state.mockMode ? AppTheme.amber : AppTheme.teal,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            state.mockMode
                                ? l10n.t('mockAi')
                                : l10n.t('liveSystem'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color:
                                  state.mockMode
                                      ? AppTheme.amber
                                      : AppTheme.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. السلايدر (تصغير الارتفاع قليلاً ليترك مجالاً لباقي العناصر)
              Column(
                children: [
                  SizedBox(
                    height: 170,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (int page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      itemCount: _carouselImages.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap:
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ScreeningScreen(),
                                ),
                              ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                image: NetworkImage(_carouselImages[index]),
                                onError: (_, __) {},
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _carouselImages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 5,
                        width: _currentPage == index ? 20 : 6,
                        decoration: BoxDecoration(
                          color:
                              _currentPage == index
                                  ? AppTheme.teal
                                  : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. الإحصائيات (تغيير التصميم ليكون مضغوطاً وعملياً)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildCompactMetricCard(
                        icon: Icons.fact_check_rounded,
                        label: l10n.t('totalScans'),
                        value: '${state.records.length}',
                        color: AppTheme.teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactMetricCard(
                        icon: Icons.flag_rounded,
                        label: l10n.t('riskFlags'),
                        value: '$riskCount',
                        color: AppTheme.coral,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. الرسم البياني (تصميم متماسك مع معالجة للحالة الفارغة)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildBeautifulChart(records),
              ),
              const SizedBox(height: 24),

              // 5. أحدث فحص (Latest Record) تقليص الفراغات الداخلية للبطاقة
              if (latest != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('recentResult'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.navy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap:
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ResultScreen(record: latest),
                              ),
                            ),
                        child: Container(
                          padding: const EdgeInsets.all(
                            16,
                          ), // تقليل الحشو الداخلي هنا
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey.shade100,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.teal.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.analytics_rounded,
                                      color: AppTheme.teal,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.translateKnown(
                                            latest.result.finalLabel,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.navy,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l10n.formatMonthDay(latest.createdAt),
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: Colors.grey.shade400,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Text(
                                    '${latest.result.confidencePercent.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color:
                                          latest.result.riskDetected
                                              ? AppTheme.coral
                                              : AppTheme.teal,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value:
                                            latest.result.confidencePercent /
                                            100,
                                        minHeight: 6,
                                        backgroundColor: Colors.grey.shade100,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              latest.result.riskDetected
                                                  ? AppTheme.coral
                                                  : AppTheme.teal,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // بطاقة إحصائيات مدمجة (Compact) لتعبئة الشاشة وتجنب المساحات الفارغة الكبيرة
  Widget _buildCompactMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // رسم بياني محكم يعالج حالة الفراغ بشكل أنيق
  Widget _buildBeautifulChart(List<ScreeningRecord> records) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(20), // تقليل الحشو
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('confidenceOverview'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140, // ارتفاع أصغر قليلاً لمنع الفراغ المفرط
            child:
                records.isEmpty
                    // تصميم مخصص للحالة الفارغة لتبدو كجزء من الواجهة
                    ? Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.show_chart_rounded,
                            color: Colors.grey.shade300,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.t('firstScanData'),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                    : LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 100,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine:
                              (value) => FlLine(
                                color: Colors.grey.shade100,
                                strokeWidth: 2,
                                dashArray: [5, 5],
                              ),
                        ),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget:
                                  (value, meta) => Text(
                                    '${value.toInt()}',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (var i = 0; i < records.length; i++)
                                FlSpot(
                                  i.toDouble(),
                                  records[i].result.confidencePercent,
                                ),
                            ],
                            isCurved: true,
                            curveSmoothness: 0.35,
                            barWidth: 4,
                            color: AppTheme.teal,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter:
                                  (spot, percent, barData, index) =>
                                      FlDotCirclePainter(
                                        radius: 4,
                                        color: Colors.white,
                                        strokeWidth: 3,
                                        strokeColor: AppTheme.teal,
                                      ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.teal.withValues(alpha: 0.25),
                                  AppTheme.teal.withValues(alpha: 0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
