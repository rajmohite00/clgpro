import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'result_screen.dart';
import 'utils/animations.dart';
import 'providers/settings_provider.dart';

class HistoryScreen extends StatefulWidget {
  final bool isTab;
  const HistoryScreen({super.key, this.isTab = false});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteItem(int index, Map<String, dynamic> item) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedItems = prefs.getStringList('history_results') ?? [];

    savedItems.removeWhere((element) {
      final map = jsonDecode(element) as Map<String, dynamic>;
      return map['date'] == item['date'] &&
          map['fraudScore'] == item['fraudScore'] &&
          map['summary'] == item['summary'];
    });

    await prefs.setStringList('history_results', savedItems);
    setState(() {
      _historyFuture = _fetchHistory();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.delete_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text('Item deleted'),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          margin: EdgeInsets.all(16.w),
        ),
      );
    }
  }

  Future<bool?> _showConfirmDialog(BuildContext context, String actionStr) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Confirm $actionStr',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        content: Text('Are you sure you want to ${actionStr.toLowerCase()} this item?',
            style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: actionStr == 'Delete' ? const Color(0xFFEF4444) : Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionStr, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          )
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedItems = prefs.getStringList('history_results') ?? [];

    if (savedItems.isNotEmpty) {
      return savedItems.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
    }

    await Future.delayed(const Duration(milliseconds: 800));
    return [
      {'date': '19 Mar 2026', 'status': 'Match', 'summary': 'Driver License & Passport Verification', 'fraudScore': 15},
      {'date': '18 Mar 2026', 'status': 'Mismatch', 'summary': 'ID Card & Utility Bill Verification', 'fraudScore': 85},
      {'date': '15 Mar 2026', 'status': 'Match', 'summary': 'Bank Statement Authentication', 'fraudScore': 20},
      {'date': '12 Mar 2026', 'status': 'Match', 'summary': 'Tax API Data Verification', 'fraudScore': 18},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final textColor = colorScheme.onSurface;
    final textDimColor = colorScheme.onSurface.withOpacity(0.55);

    final settings = Provider.of<SettingsProvider>(context);
    final bool isHindi = settings.isHindi;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.isTab
          ? null
          : AppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              title: Text(tr('History', isHindi),
                  style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w700)),
              elevation: 0,
              iconTheme: IconThemeData(color: textColor),
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
                  child: StaggeredListItem(
                    index: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              tr('Recent Analyses', isHindi),
                              style: GoogleFonts.inter(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),
                        _buildSearchBar(theme, colorScheme, isDark, textDimColor, isHindi),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _historyFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return ListView.separated(
                          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
                          itemCount: 5,
                          separatorBuilder: (_, __) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            return ShimmerWidget(
                              width: double.infinity,
                              height: 88.h,
                              borderRadius: 20,
                            );
                          },
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text('Failed to load history',
                              style: GoogleFonts.inter(color: theme.colorScheme.error)),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState(theme, textColor, textDimColor, isHindi);
                      }

                      final allHistory = snapshot.data!;
                      final history = allHistory.where((item) {
                        final query = _searchQuery.toLowerCase();
                        return item['summary']!.toLowerCase().contains(query) ||
                            item['date']!.toLowerCase().contains(query);
                      }).toList();

                      if (history.isEmpty) {
                        return _buildNoResultsState(theme, textColor, textDimColor, isHindi);
                      }

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 100.h),
                        itemCount: history.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
                          final item = history[index];
                          final isMatch = item['status'] == 'Match';
                          final color = isMatch ? const Color(0xFF10B981) : const Color(0xFFEF4444);

                          return StaggeredListItem(
                            index: index + 1,
                            child: Dismissible(
                              key: Key(item.hashCode.toString() + index.toString()),
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_rounded, color: Colors.white, size: 24.sp),
                                    SizedBox(width: 8.w),
                                    Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              secondaryBackground: Container(
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text('Share', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                                    SizedBox(width: 8.w),
                                    Icon(Icons.share_rounded, color: Colors.white, size: 24.sp),
                                  ],
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  final confirm = await _showConfirmDialog(context, 'Delete');
                                  return confirm ?? false;
                                } else {
                                  Share.share(
                                      'Analysis Result: ${item['summary']} \nRisk Score: ${item['fraudScore']}% \nStatus: ${item['status']}\nVerified via Smart Document Detective');
                                  return false;
                                }
                              },
                              onDismissed: (direction) {
                                if (direction == DismissDirection.startToEnd) {
                                  _deleteItem(index, item);
                                }
                              },
                              child: AnimatedScaleButton(
                                onTap: () {
                                  final mockResult = item['comparisons'] != null
                                      ? item
                                      : {
                                          'status': item['status'],
                                          'fraudScore': item['fraudScore'] ?? (isMatch ? 15 : 85),
                                          'comparisons': [
                                            {
                                              'field': 'Full Name',
                                              'doc1': 'John Doe',
                                              'doc2': isMatch ? 'John Doe' : 'Jonathan Doe',
                                              'status': isMatch ? 'Match' : 'Mismatch'
                                            },
                                            {
                                              'field': 'Date of Birth',
                                              'doc1': '15-08-1990',
                                              'doc2': '15-08-1990',
                                              'status': 'Match'
                                            },
                                            if (!isMatch)
                                              {
                                                'field': 'Address',
                                                'doc1': '123 Fake Street, NY',
                                                'doc2': '456 Different St, NY',
                                                'status': 'Mismatch'
                                              },
                                          ]
                                        };
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => ResultScreen(resultData: mockResult)));
                                },
                                child: Container(
                                  padding: EdgeInsets.all(18.w),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                      color: color.withOpacity(0.12),
                                      width: 1.w,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                        blurRadius: 12.r,
                                        offset: Offset(0, 4.h),
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(12.w),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(14.r),
                                        ),
                                        child: Icon(
                                          isMatch ? Icons.verified_rounded : Icons.warning_amber_rounded,
                                          color: color,
                                          size: 22.sp,
                                        ),
                                      ),
                                      SizedBox(width: 14.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['summary'],
                                              style: GoogleFonts.inter(
                                                color: textColor,
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              item['date'],
                                              style: GoogleFonts.inter(
                                                color: textDimColor,
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10.r),
                                          border: Border.all(color: color.withOpacity(0.25)),
                                        ),
                                        child: Text(
                                          item['status']!.toUpperCase(),
                                          style: GoogleFonts.inter(
                                            color: color,
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(
      ThemeData theme, ColorScheme colorScheme, bool isDark, Color textDimColor, bool isHindi) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: 14.sp, fontWeight: FontWeight.w500),
        cursorColor: colorScheme.primary,
        decoration: InputDecoration(
          hintText: tr('Search by name or date...', isHindi),
          hintStyle:
              GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.35), fontSize: 14.sp),
          prefixIcon: Icon(Icons.search_rounded,
              color: colorScheme.onSurface.withOpacity(0.35), size: 20.sp),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      color: colorScheme.onSurface.withOpacity(0.35), size: 18.sp),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.5), width: 1.5.w)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      ThemeData theme, Color textColor, Color textDimColor, bool isHindi) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(28.w),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, size: 56.sp, color: theme.primaryColor.withOpacity(0.6)),
          ),
          SizedBox(height: 24.h),
          Text(tr('No History Yet', isHindi),
              style: GoogleFonts.inter(fontSize: 22.sp, fontWeight: FontWeight.w800, color: textColor)),
          SizedBox(height: 8.h),
          Text(tr('Past document analyses will appear here.', isHindi),
              style: GoogleFonts.inter(color: textDimColor, fontSize: 14.sp), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(
      ThemeData theme, Color textColor, Color textDimColor, bool isHindi) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, size: 48.sp, color: textDimColor.withOpacity(0.6)),
          ),
          SizedBox(height: 20.h),
          Text(tr('No results found', isHindi),
              style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w700, color: textColor)),
          SizedBox(height: 8.h),
          Text(tr('Try adjusting your search terms.', isHindi),
              style: GoogleFonts.inter(color: textDimColor, fontSize: 14.sp)),
        ],
      ),
    );
  }
}
