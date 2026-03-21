import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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

  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    // API mock: /get-history
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      {'date': '19 Mar 2026', 'status': 'Match', 'summary': 'Driver License & Passport Verification'},
      {'date': '18 Mar 2026', 'status': 'Mismatch', 'summary': 'ID Card & Utility Bill Verification'},
      {'date': '15 Mar 2026', 'status': 'Match', 'summary': 'Bank Statement Authentication'},
      {'date': '12 Mar 2026', 'status': 'Match', 'summary': 'Tax API Data Verification'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final textColor = colorScheme.onSurface;
    final textDimColor = colorScheme.onSurface.withOpacity(0.6);

    final settings = Provider.of<SettingsProvider>(context);
    final bool isHindi = settings.isHindi;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.isTab
          ? null
          : AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
              title: Text(tr('History', isHindi), style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w600)),
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
                  padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 8.h),
                  child: StaggeredListItem(
                    index: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('Recent Analyses', isHindi), style: GoogleFonts.inter(fontSize: 22.sp, fontWeight: FontWeight.bold, color: textColor)),
                        SizedBox(height: 16.h),
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
                        return Center(child: CircularProgressIndicator(color: theme.primaryColor));
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Failed to load history', style: GoogleFonts.inter(color: theme.colorScheme.error)));
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
                        padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
                        itemCount: history.length,
                        separatorBuilder: (_, __) => SizedBox(height: 16.h),
                        itemBuilder: (context, index) {
                          final item = history[index];
                          final isMatch = item['status'] == 'Match';
                          final color = isMatch ? const Color(0xFF10B981) : Colors.redAccent;

                          return StaggeredListItem(
                            index: index + 1,
                            child: AnimatedScaleButton(
                              onTap: () {
                                final mockResult = {
                                  'status': item['status'],
                                  'comparisons': [
                                    {'field': 'Full Name', 'doc1': 'John Doe', 'doc2': isMatch ? 'John Doe' : 'Jonathan Doe', 'status': isMatch ? 'Match' : 'Mismatch'},
                                    {'field': 'Date of Birth', 'doc1': '15-08-1990', 'doc2': '15-08-1990', 'status': 'Match'},
                                    if (!isMatch) {'field': 'Address', 'doc1': '123 Fake Street, NY', 'doc2': '456 Different St, NY', 'status': 'Mismatch'},
                                  ]
                                };
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(resultData: mockResult)));
                              },
                              child: Container(
                                padding: EdgeInsets.all(20.w),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(color: colorScheme.onSurface.withOpacity(0.05), width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                                      blurRadius: 15.r,
                                      offset: Offset(0, 4.h),
                                    )
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item['date'],
                                          style: GoogleFonts.inter(color: textDimColor, fontSize: 13.sp, fontWeight: FontWeight.w500),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12.r),
                                            border: Border.all(color: color.withOpacity(0.2)),
                                          ),
                                          child: Text(
                                            item['status']!.toUpperCase(),
                                            style: GoogleFonts.inter(color: color, fontSize: 11.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                          ),
                                        )
                                      ],
                                    ),
                                    SizedBox(height: 12.h),
                                    Text(
                                      item['summary'],
                                      style: GoogleFonts.inter(color: textColor, fontSize: 16.sp, fontWeight: FontWeight.w600),
                                    ),
                                  ],
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

  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme, bool isDark, Color textDimColor, bool isHindi) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.02),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
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
        style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: 15.sp),
        cursorColor: colorScheme.primary,
        decoration: InputDecoration(
          hintText: tr('Search by name or date...', isHindi),
          hintStyle: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 14.sp),
          prefixIcon: Icon(Icons.search_rounded, color: colorScheme.onSurface.withOpacity(0.4), size: 20.sp),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: colorScheme.onSurface.withOpacity(0.4), size: 20.sp),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, Color textColor, Color textDimColor, bool isHindi) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 80.sp, color: theme.primaryColor.withOpacity(0.5)),
          SizedBox(height: 24.h),
          Text(tr('No History Yet', isHindi), style: GoogleFonts.inter(fontSize: 24.sp, fontWeight: FontWeight.bold, color: textColor)),
          SizedBox(height: 8.h),
          Text(tr('Past document analyses will appear here.', isHindi), style: GoogleFonts.inter(color: textDimColor)),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(ThemeData theme, Color textColor, Color textDimColor, bool isHindi) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60.sp, color: textDimColor.withOpacity(0.5)),
          SizedBox(height: 16.h),
          Text(tr('No results found', isHindi), style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.bold, color: textColor)),
          SizedBox(height: 8.h),
          Text(tr('Try adjusting your search terms.', isHindi), style: GoogleFonts.inter(color: textDimColor)),
        ],
      ),
    );
  }
}

