import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'result_screen.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  HISTORY SCREEN  —  Minimal Government UI
// ─────────────────────────────────────────────────────────────────────────────



class HistoryScreen extends StatefulWidget {
  final bool isTab;
  const HistoryScreen({super.key, this.isTab = false});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data ops ───────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getStringList('history_results') ?? [];
    return raw.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  void _refresh() => setState(() => _historyFuture = _fetch());

  Future<void> _delete(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = (prefs.getStringList('history_results') ?? []).toList();
    raw.removeWhere((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return m['date'] == item['date'] &&
          m['fraudScore'] == item['fraudScore'] &&
          m['summary'] == item['summary'];
    });
    await prefs.setStringList('history_results', raw);
    _refresh();
    if (mounted) {
      final isHindi = Provider.of<SettingsProvider>(context, listen: false).isHindi;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('Record deleted', isHindi),
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13.sp)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
        margin: EdgeInsets.all(16.w),
      ));
    }
  }




  Future<void> _exportPdf(List<Map<String, dynamic>> history) async {
    final doc  = pw.Document();
    final date = DateTime.now().toString().split(' ')[0];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('DocVerify — Scan History Report',
                    style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900)),
                pw.Text('Generated: $date',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('DocVerify · Document Fraud Detection System',
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey500)),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey500)),
          ],
        ),
        build: (ctx) => [
          // Summary line
          pw.Text(
            'Total records: ${history.length}  ·  '
            'Genuine: ${history.where((i) {
              final s = i['status'] as String? ?? '';
              return s == 'REAL' || s == 'Match';
            }).length}  ·  '
            'Fraudulent: ${history.where((i) {
              final s = i['status'] as String? ?? '';
              return s == 'FAKE' || s == 'Mismatch';
            }).length}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),

          // Table
          pw.TableHelper.fromTextArray(
            headers: ['#', 'Date', 'Document', 'Status', 'Score', 'Type'],
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.indigo800),
            headerHeight: 24,
            cellHeight: 28,
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
            },
            cellStyle: const pw.TextStyle(fontSize: 9),
            oddRowDecoration:
                const pw.BoxDecoration(color: PdfColors.grey100),
            data: history.asMap().entries.map((e) {
              final i      = e.key;
              final item   = e.value;
              final status = item['status'] as String? ?? '';
              final isReal = status == 'REAL' || status == 'Match';
              final label  = (status == 'REAL' || status == 'FAKE')
                  ? status
                  : (status == 'Match' ? 'REAL' : 'FAKE');
              return [
                '${i + 1}',
                item['date'] ?? '',
                (item['summary'] as String? ?? '').isNotEmpty
                    ? item['summary'] as String
                    : (item['documentType'] as String? ?? '—'),
                label,
                '${item['fraudScore'] ?? 0}',
                item['tag'] ?? '—',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    // Save to documents dir and share
    final dir  = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/docverify_history_$date.pdf');
    await file.writeAsBytes(await doc.save());
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: 'DocVerify Scan History — $date',
    );
  }

  // ── Modals ─────────────────────────────────────────────────────────────────



  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final cs      = theme.colorScheme;
    final isDark  = theme.brightness == Brightness.dark;
    final textPri = cs.onSurface;
    final textSec = cs.onSurface.withOpacity(0.5);
    final divClr  = theme.dividerColor;
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi  = settings.isHindi;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.isTab
          ? null
          : AppBar(
              backgroundColor:
                  isDark ? AppTheme.ink : Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(height: 1, color: divClr),
              ),
              title: Text(tr('History', isHindi),
                  style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: textPri)),
            ),
      body: SafeArea(
        child: Column(
          children: [

            // ── Tab header (when used as tab) ──────────────────────────────
            if (widget.isTab)
              Column(children: [
                Padding(
                  padding:
                      EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                  child: Row(
                    children: [
                      Text(tr('History', isHindi),
                          style: GoogleFonts.inter(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w800,
                              color: textPri,
                              letterSpacing: -0.4)),
                      const Spacer(),
                      _exportButton(cs, textSec, isHindi),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
                Divider(height: 1, color: divClr),
              ]),

            // ── Search bar ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: _searchBar(cs, isDark, textSec, isHindi),
            ),

            Divider(height: 1, color: divClr),

            // ── List ──────────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _refresh(),
                color: cs.primary,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _historyFuture,
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return _shimmer(divClr);
                    }
                    if (snap.hasError) {
                      return _centered(
                          'Failed to load history', textSec);
                    }
                    if (!snap.hasData || snap.data!.isEmpty) {
                      return _emptyState(textPri, textSec, isHindi);
                    }

                    // Filter
                    final filtered = snap.data!.where((item) {
                      final q       = _query.toLowerCase();
                      final summary = (item['summary'] ?? item['documentType'] ?? '')
                          .toString().toLowerCase();
                      final date    = (item['date'] ?? '').toString().toLowerCase();
                      final docType = (item['documentType'] ?? '').toString().toLowerCase();
                      final matchQ = q.isEmpty ||
                          summary.contains(q) ||
                          date.contains(q) ||
                          docType.contains(q);
                      return matchQ;
                    }).toList();

                    if (filtered.isEmpty) {
                      return _centered(
                          'No results for "$_query"', textSec);
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final item  = filtered[i];
                        final isLast = i == filtered.length - 1;
                        return _historyRow(
                          item:     item,
                          isLast:   isLast,
                          cs:       cs,
                          isDark:   isDark,
                          textPri:  textPri,
                          textSec:  textSec,
                          divClr:   divClr,
                          isHindi:  isHindi,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Row widget ─────────────────────────────────────────────────────────────
  Widget _historyRow({
    required Map<String, dynamic> item,
    required bool isLast,
    required ColorScheme cs,
    required bool isDark,
    required Color textPri,
    required Color textSec,
    required Color divClr,
    required bool isHindi,
  }) {
    final status     = item['status'] as String? ?? '';
    final isReal     = status == 'REAL' || status == 'Match';
    final statusClr  = isReal ? AppTheme.success : AppTheme.error;
    final statusLabel = (status == 'REAL' || status == 'FAKE')
        ? status
        : (status == 'Match' ? 'REAL' : 'FAKE');
    final title = (item['summary'] as String? ?? '').isNotEmpty
        ? item['summary'] as String
        : (item['documentType'] as String? ?? 'Document Analysis');
    final date  = item['date'] as String? ?? '';
    final tag   = item['tag']   as String?;

    return Dismissible(
      key: Key('${item['date']}_${item['fraudScore']}_${item['summary']}'),
      background: Container(
        color: AppTheme.error.withOpacity(0.08),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20.w),
        child: Row(children: [
          Icon(Icons.delete_outline_rounded,
              color: AppTheme.error, size: 18.sp),
          SizedBox(width: 6.w),
          Text(tr('Delete', isHindi),
              style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: AppTheme.error,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
      secondaryBackground: Container(
        color: cs.primary.withOpacity(0.06),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(tr('Share', isHindi),
                style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: cs.primary,
                    fontWeight: FontWeight.w600)),
            SizedBox(width: 6.w),
            Icon(Icons.share_outlined, color: cs.primary, size: 17.sp),
          ],
        ),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(tr('Delete record?', isHindi),
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 15.sp)),
              content: Text(tr('This cannot be undone.', isHindi),
                  style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: cs.onSurface.withOpacity(0.55))),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(tr('Cancel', isHindi),
                      style: GoogleFonts.inter(fontSize: 13.sp)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(tr('Delete', isHindi),
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp)),
                ),
              ],
            ),
          );
          return ok ?? false;
        } else {
          Share.share(
              'Result: $title\nStatus: $statusLabel | Score: ${item['fraudScore']}\nVerified via DocVerify');
          return false;
        }
      },
      onDismissed: (dir) {
        if (dir == DismissDirection.startToEnd) _delete(item);
      },
      child: InkWell(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) =>
                    ResultScreen(resultData: Map<String, dynamic>.from(item)))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status dot
                  Padding(
                    padding: EdgeInsets.only(top: 5.h),
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                          color: statusClr, shape: BoxShape.circle),
                    ),
                  ),
                  SizedBox(width: 14.w),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: GoogleFonts.inter(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w600,
                              color: textPri,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        SizedBox(height: 2.h),
                        Row(children: [
                          Text(date,
                              style: GoogleFonts.inter(
                                  fontSize: 11.sp, color: textSec)),
                          if (tag != null) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 1.h),
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                              child: Text(tag,
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: cs.primary,
                                  )),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),

                  // Right column: status badge + action menu
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Status badge
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 7.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: statusClr.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4.r),
                          border: Border.all(
                              color: statusClr.withOpacity(0.25)),
                        ),
                        child: Text(statusLabel,
                            style: GoogleFonts.inter(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w800,
                              color: statusClr,
                              letterSpacing: 0.4,
                            )),
                      ),
                      SizedBox(height: 6.h),
                      // ⋮ menu
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showItemMenu(
                            context: context,
                            item: item,
                            cs: cs,
                            textPri: textPri,
                            textSec: textSec,
                            isHindi: isHindi),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(8.w, 4.h, 0, 4.h),
                          child: Icon(Icons.more_vert_rounded,
                              size: 18.sp, color: textSec),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isLast)
              Divider(
                  color: divClr, height: 1, indent: 42.w, endIndent: 20.w),
          ],
        ),
      ),
    );
  }

  // ── Item action menu ───────────────────────────────────────────────────────
  void _showItemMenu({
    required BuildContext context,
    required Map<String, dynamic> item,
    required ColorScheme cs,
    required Color textPri,
    required Color textSec,
    required bool isHindi,
  }) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12.r))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            Container(
              width: 36.w, height: 4.h,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 8.h),
            _menuAction(
              icon: Icons.share_outlined,
              label: tr('Share Result', isHindi),
              color: textPri,
              onTap: () {
                Navigator.pop(ctx);
                final title = (item['summary'] as String? ?? '').isNotEmpty
                    ? item['summary'] as String
                    : (item['documentType'] as String? ?? 'Document');
                Share.share(
                    'Result: $title\nStatus: ${item['status']} | Score: ${item['fraudScore']}\nVerified via DocVerify');
              },
            ),
            Divider(height: 1, color: theme.dividerColor, indent: 52.w),
            _menuAction(
              icon: Icons.delete_outline_rounded,
              label: tr('Delete', isHindi),
              color: AppTheme.error,
              onTap: () {
                Navigator.pop(ctx);
                _delete(item);
              },
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Widget _menuAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        child: Row(children: [
          Icon(icon, size: 19.sp, color: color.withOpacity(0.75)),
          SizedBox(width: 16.w),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _exportButton(ColorScheme cs, Color textSec, bool isHindi) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _historyFuture,
      builder: (ctx, snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => _exportPdf(snap.data!),
          child: Row(children: [
            Icon(Icons.picture_as_pdf_outlined, size: 16.sp, color: textSec),
            SizedBox(width: 4.w),
            Text(tr('Export PDF', isHindi),
                style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: textSec,
                    fontWeight: FontWeight.w600)),
          ]),
        );
      },
    );
  }

  Widget _searchBar(
      ColorScheme cs, bool isDark, Color textSec, bool isHindi) {
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _query = v),
      style: GoogleFonts.inter(
          color: cs.onSurface, fontSize: 13.5.sp),
      cursorColor: cs.primary,
      decoration: InputDecoration(
        hintText: tr('Search by name or date...', isHindi),
        hintStyle: GoogleFonts.inter(
            color: cs.onSurface.withOpacity(0.35), fontSize: 13.5.sp),
        prefixIcon: Icon(Icons.search_rounded,
            color: cs.onSurface.withOpacity(0.35), size: 18.sp),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear_rounded,
                    color: cs.onSurface.withOpacity(0.35), size: 16.sp),
                onPressed: () => setState(() {
                  _searchCtrl.clear();
                  _query = '';
                }),
              )
            : null,
        filled: true,
        fillColor: isDark ? AppTheme.inkSurface : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
              color: isDark ? AppTheme.borderLight : AppTheme.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      ),
    );
  }

  Widget _shimmer(Color divClr) {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) => Divider(height: 1, color: divClr),
      itemBuilder: (_, __) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        child: Row(children: [
          Container(
              width: 8.w, height: 8.w,
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  shape: BoxShape.circle)),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 12.h,
                    width: 160.w,
                    color: Colors.grey.withOpacity(0.15)),
                SizedBox(height: 6.h),
                Container(
                    height: 10.h,
                    width: 90.w,
                    color: Colors.grey.withOpacity(0.1)),
              ],
            ),
          ),
          Container(
              height: 18.h,
              width: 40.w,
              color: Colors.grey.withOpacity(0.12)),
        ]),
      ),
    );
  }

  Widget _emptyState(Color textPri, Color textSec, bool isHindi) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.history_rounded,
            size: 44.sp, color: textSec.withOpacity(0.3)),
        SizedBox(height: 16.h),
        Text(tr('No History Yet', isHindi),
            style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: textPri)),
        SizedBox(height: 6.h),
        Text('Your scan history will appear here.',
            style: GoogleFonts.inter(fontSize: 13.sp, color: textSec),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _centered(String msg, Color textSec) {
    return Center(
      child: Text(msg,
          style: GoogleFonts.inter(fontSize: 13.sp, color: textSec)),
    );
  }
}
