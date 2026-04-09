import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/settings_provider.dart';
import 'providers/user_provider.dart';
import 'utils/animations.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // ── Real computed values ───────────────────────────────────────────────────
  int _totalFromHistory = 0;  // actual count from saved history
  int _realCount       = 0;   // status == 'REAL'
  int _fakeCount       = 0;   // status == 'FAKE'
  int _avgFraudScore   = 0;
  Map<String, int> _weeklyData = {};
  Map<String, int> _docTypeData = {};
  bool _loading = true;

  static const List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('history_results') ?? [];

    // Reset
    Map<String, int> weekly  = {for (var d in _weekDays) d: 0};
    Map<String, int> docTypes = {};
    int realC = 0, fakeC = 0, scoreSum = 0, scoreCount = 0;

    if (saved.isEmpty) {
      // Keep counters at zero — no demo data, we show real state
    } else {
      for (final s in saved) {
        try {
          final item = jsonDecode(s) as Map<String, dynamic>;

          // Status — handle both old (Match/Mismatch) and new (REAL/FAKE) formats
          final status = item['status'] as String? ?? '';
          if (status == 'REAL' || status == 'Match') {
            realC++;
          } else {
            fakeC++;
          }

          // Fraud score average
          final score = item['fraudScore'] as int?;
          if (score != null) {
            scoreSum += score;
            scoreCount++;
          }

          // Document type distribution
          final docType = item['documentType'] as String?
              ?? item['tag'] as String?
              ?? 'Other';
          // Clean up multi-doc types like "Aadhaar, PAN"
          for (final part in docType.split(',')) {
            final key = part.trim().isEmpty ? 'Other' : part.trim();
            docTypes[key] = (docTypes[key] ?? 0) + 1;
          }

          // Weekly — date format is yyyy-MM-dd  (new) or "dd Mon yyyy" (old mock)
          final dateStr = item['date'] as String? ?? '';
          try {
            DateTime? dt;
            // Try ISO format: 2026-03-27
            if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(dateStr)) {
              dt = DateTime.tryParse(dateStr);
            } else {
              // Fallback: "19 Mar 2026"
              final parts = dateStr.split(' ');
              if (parts.length >= 3) {
                final months = {
                  'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
                  'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
                  'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
                };
                final d = int.tryParse(parts[0]) ?? 1;
                final m = months[parts[1]] ?? 1;
                final y = int.tryParse(parts[2]) ?? DateTime.now().year;
                dt = DateTime(y, m, d);
              }
            }
            if (dt != null) {
              // Only include scans from the past 7 days
              final daysDiff = DateTime.now().difference(dt).inDays;
              if (daysDiff >= 0 && daysDiff < 7) {
                final dayKey = _weekDays[dt.weekday - 1]; // Mon=1…Sun=7
                weekly[dayKey] = (weekly[dayKey] ?? 0) + 1;
              }
            }
          } catch (_) {}
        } catch (_) {}
      }
    }

    setState(() {
      _totalFromHistory = saved.length;
      _realCount   = realC;
      _fakeCount   = fakeC;
      _avgFraudScore = scoreCount > 0 ? (scoreSum / scoreCount).round() : 0;
      _weeklyData  = weekly;
      _docTypeData = docTypes;
      _loading     = false;
    });
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark      = theme.brightness == Brightness.dark;
    final textColor   = colorScheme.onSurface;
    final dimColor    = colorScheme.onSurface.withOpacity(0.52);
    final cardColor   = theme.cardColor;
    final isHindi     = Provider.of<SettingsProvider>(context).isHindi;
    final user        = Provider.of<UserProvider>(context);

    // The authoritative count: prefer UserProvider (updated live), fall back to history length
    final totalScans = user.totalScans > 0 ? user.totalScans : _totalFromHistory;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          tr('Analytics', isHindi),
          style: GoogleFonts.inter(
              color: textColor, fontWeight: FontWeight.w700, fontSize: 18.sp),
        ),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh_rounded, color: colorScheme.primary, size: 20.sp),
            onPressed: () {
              setState(() => _loading = true);
              _animController.reset();
              _loadData();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() => _loading = true);
                  _animController.reset();
                  await _loadData();
                },
                color: colorScheme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Top stats row ──────────────────────────────────────
                      StaggeredListItem(
                        index: 0,
                        child: Row(
                          children: [
                            _statCard(
                              label: 'Total Scans',
                              value: '$totalScans',
                              icon: Icons.document_scanner_rounded,
                              color: colorScheme.primary,
                              cardColor: cardColor,
                              textColor: textColor,
                              dimColor: dimColor,
                              isDark: isDark,
                            ),
                            SizedBox(width: 12.w),
                            _statCard(
                              label: tr('Streak', isHindi),
                              value: '${user.streakDays}d',
                              icon: Icons.local_fire_department_rounded,
                              color: const Color(0xFFF59E0B),
                              cardColor: cardColor,
                              textColor: textColor,
                              dimColor: dimColor,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),
                      StaggeredListItem(
                        index: 1,
                        child: Row(
                          children: [
                            _statCard(
                              label: 'Genuine Docs',
                              value: '$_realCount',
                              icon: Icons.verified_rounded,
                              color: const Color(0xFF10B981),
                              cardColor: cardColor,
                              textColor: textColor,
                              dimColor: dimColor,
                              isDark: isDark,
                            ),
                            SizedBox(width: 12.w),
                            _statCard(
                              label: 'Avg Fraud Score',
                              value: '$_avgFraudScore%',
                              icon: Icons.bar_chart_rounded,
                              color: const Color(0xFFEF4444),
                              cardColor: cardColor,
                              textColor: textColor,
                              dimColor: dimColor,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // ── Real vs Fake ratio bar ─────────────────────────────
                      StaggeredListItem(
                        index: 2,
                        child: _buildRealFakeCard(
                          realCount: _realCount,
                          fakeCount: _fakeCount,
                          cardColor: cardColor,
                          textColor: textColor,
                          dimColor: dimColor,
                          isDark: isDark,
                          colorScheme: colorScheme,
                          isHindi: isHindi,
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // ── Weekly scan bar chart ──────────────────────────────
                      StaggeredListItem(
                        index: 3,
                        child: _buildWeeklyChart(
                          data: _weeklyData,
                          cardColor: cardColor,
                          textColor: textColor,
                          dimColor: dimColor,
                          isDark: isDark,
                          accentColor: colorScheme.primary,
                          isHindi: isHindi,
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // ── Document type distribution ─────────────────────────
                      if (_docTypeData.isNotEmpty)
                        StaggeredListItem(
                          index: 4,
                          child: _buildDocTypeChart(
                            types: _docTypeData,
                            cardColor: cardColor,
                            textColor: textColor,
                            dimColor: dimColor,
                            isDark: isDark,
                            accentColor: colorScheme.primary,
                            isHindi: isHindi,
                          ),
                        ),
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required Color dimColor,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(height: 14.h),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: textColor)),
            SizedBox(height: 2.h),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11.sp, color: dimColor, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildRealFakeCard({
    required int realCount,
    required int fakeCount,
    required Color cardColor,
    required Color textColor,
    required Color dimColor,
    required bool isDark,
    required ColorScheme colorScheme,
    required bool isHindi,
  }) {
    final total = realCount + fakeCount;
    final realRatio = total == 0 ? 0.5 : realCount / total;
    const realColor  = Color(0xFF10B981);
    const fakeColor  = Color(0xFFEF4444);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tr('Genuine vs Fraudulent', isHindi),
                  style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: textColor)),
              const Spacer(),
              if (total > 0)
                Text('$total total',
                    style: GoogleFonts.inter(
                        fontSize: 11.sp, color: dimColor, fontWeight: FontWeight.w500)),
            ],
          ),
          SizedBox(height: 16.h),
          // Animated split bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                final progress = _animController.value;
                final realFlex = total == 0 ? 50 : (realRatio * 100 * progress).round().clamp(0, 100);
                final fakeFlex = (100 * progress).round() - realFlex;
                return Row(
                  children: [
                    if (realFlex > 0)
                      Expanded(
                        flex: realFlex,
                        child: Container(height: 14.h, color: realColor),
                      ),
                    if (fakeFlex > 0)
                      Expanded(
                        flex: fakeFlex.clamp(0, 100),
                        child: Container(height: 14.h, color: fakeColor),
                      ),
                    if (realFlex == 0 && fakeFlex == 0)
                      Expanded(
                        child: Container(
                            height: 14.h,
                            color: Colors.grey.withOpacity(0.15)),
                      ),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _legendDot(realColor),
              SizedBox(width: 6.w),
              Text(tr('Genuine', isHindi) + ' ($realCount)',
                  style: GoogleFonts.inter(
                      fontSize: 12.sp, color: realColor, fontWeight: FontWeight.w600)),
              SizedBox(width: 20.w),
              _legendDot(fakeColor),
              SizedBox(width: 6.w),
              Text(tr('Fraudulent', isHindi) + ' ($fakeCount)',
                  style: GoogleFonts.inter(
                      fontSize: 12.sp, color: fakeColor, fontWeight: FontWeight.w600)),
            ],
          ),
          if (total == 0) ...[
            SizedBox(height: 12.h),
            Text(tr('No scans yet — run your first analysis to see data here.', isHindi),
                style: GoogleFonts.inter(fontSize: 12.sp, color: dimColor)),
          ],
        ],
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 10.w,
        height: 10.w,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _buildWeeklyChart({
    required Map<String, int> data,
    required Color cardColor,
    required Color textColor,
    required Color dimColor,
    required bool isDark,
    required Color accentColor,
    required bool isHindi,
  }) {
    final maxVal = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);
    final hasAnyData = data.values.any((v) => v > 0);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tr('Scans This Week', isHindi),
                  style: GoogleFonts.inter(
                      fontSize: 15.sp, fontWeight: FontWeight.w800, color: textColor)),
              const Spacer(),
              Text(tr('last 7 days', isHindi),
                  style: GoogleFonts.inter(fontSize: 11.sp, color: dimColor)),
            ],
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 165.h,
            child: !hasAnyData
                ? Center(
                    child: Text(tr('No recent scans', isHindi),
                        style: GoogleFonts.inter(fontSize: 13.sp, color: dimColor)))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: data.entries.map((entry) {
                      final ratio = maxVal == 0 ? 0.0 : entry.value / maxVal;
                      final isToday = entry.key ==
                          _weekDays[DateTime.now().weekday - 1];
                      return AnimatedBuilder(
                        animation: _animController,
                        builder: (context, _) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (entry.value > 0)
                                Text('${entry.value}',
                                    style: GoogleFonts.inter(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w700,
                                        color: accentColor)),
                              SizedBox(height: 4.h),
                              Container(
                                width: 28.w,
                                height: (100.h * ratio * _animController.value)
                                    .clamp(4.h, 100.h),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      isToday
                                          ? const Color(0xFFF59E0B)
                                          : accentColor,
                                      (isToday
                                              ? const Color(0xFFF59E0B)
                                              : accentColor)
                                          .withOpacity(0.5),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(entry.key,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    color: isToday
                                        ? const Color(0xFFF59E0B)
                                        : dimColor,
                                    fontWeight: isToday
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  )),
                            ],
                          );
                        },
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocTypeChart({
    required Map<String, int> types,
    required Color cardColor,
    required Color textColor,
    required Color dimColor,
    required bool isDark,
    required Color accentColor,
    required bool isHindi,
  }) {
    final total = types.values.fold(0, (a, b) => a + b);
    const colors = [
      Color(0xFF6366F1),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
    ];

    // Sort by count descending
    final entries = types.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Document Types Scanned', isHindi),
              style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: textColor)),
          SizedBox(height: 16.h),
          ...List.generate(entries.length, (i) {
            final color = colors[i % colors.length];
            final ratio = total == 0 ? 0.0 : entries[i].value / total;
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _legendDot(color),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(entries[i].key,
                            style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: textColor)),
                      ),
                      Text(
                        '${entries[i].value}  (${(ratio * 100).toStringAsFixed(0)}%)',
                        style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: color),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: ratio * _animController.value,
                          backgroundColor: color.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6.h,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
