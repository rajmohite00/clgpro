import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

// ═══════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════
class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

// ═══════════════════════════════════════════════════════════
// BOT BRAIN  –  keyword matching, bilingual
// ═══════════════════════════════════════════════════════════
class _BotBrain {
  // Each rule: keywords (English+Hindi mixed) → {en, hi} response
  static const List<_BotRule> _rules = [
    // ── Greeting ──────────────────────────────────────────
    _BotRule(
      keywords: ['hello', 'hi', 'hey', 'hii', 'helo', 'namaste', 'helo'],
      en: "Hey there! 👋 I'm your assistant. Ask me about uploading docs, fraud score, checking results, or downloading reports!",
      hi: "Namaste! 👋 Main aapka assistant hoon. Upload, fraud score, result ya report ke baare me pucho!",
    ),

    // ── How to use the app ─────────────────────────────────
    _BotRule(
      keywords: ['use', 'how to use', 'kaise use', 'app use', 'kaise kare', 'use karna', 'start', 'shuru'],
      en: "Using the app is simple:\n\n1️⃣ Go to Dashboard\n2️⃣ Tap 'Upload Documents'\n3️⃣ Select your files\n4️⃣ View results 📋",
      hi: "App use karna easy hai:\n\n1️⃣ Dashboard par jao\n2️⃣ 'Upload Documents' par tap karo\n3️⃣ File select karo\n4️⃣ Result dekho 📋",
    ),

    // ── Upload single document ─────────────────────────────
    _BotRule(
      keywords: ['upload', 'how to upload', 'upload kaise', 'document upload', 'file upload', 'scan', 'document', 'file'],
      en: "To upload documents:\n\n👉 Go to Dashboard → tap 'Upload Documents'\n👉 Select files from gallery or camera\n👉 AI will analyse them instantly! 📄",
      hi: "Document upload karne ke liye:\n\n👉 Dashboard pe jao → 'Upload Documents' pe tap karo\n👉 Gallery ya camera se file chuno\n👉 AI turant check karegi! 📄",
    ),

    // ── Multiple documents ─────────────────────────────────
    _BotRule(
      keywords: ['multiple', 'more documents', 'ek se jyada', 'kai document', 'many files', 'multiple files', 'alag alag'],
      en: "Yes! You can upload multiple documents at once 📂\n\nJust tap 'Upload Documents' and select multiple files from your gallery. The AI compares them all together.",
      hi: "Haan! Aap ek saath kai documents upload kar sakte ho 📂\n\n'Upload Documents' pe tap karo aur gallery se kai files chuno. AI sabko ek saath compare karegi.",
    ),

    // ── App features ───────────────────────────────────────
    _BotRule(
      keywords: ['features', 'kya karta hai', 'what does', 'app kya', 'capabilities', 'kya kar sakta', 'app me kya'],
      en: "Here's what this app can do 🚀\n\n✅ Upload & scan documents\n🔍 AI-powered fraud detection\n📊 Fraud score (0–100%)\n📋 Full comparison report\n📥 Download PDF report",
      hi: "App ye sab kar sakta hai 🚀\n\n✅ Documents upload aur scan karna\n🔍 AI se fraud pakadna\n📊 Fraud score (0–100%)\n📋 Puri comparison report\n📥 PDF report download karna",
    ),

    // ── Fraud score ────────────────────────────────────────
    _BotRule(
      keywords: ['fraud', 'fraud score', 'score', 'risk', 'percentage', 'dhokha', 'nakli', 'genuine'],
      en: "The **Fraud Score** is an AI rating from 0–100% 🔢\n\n• Higher score = more genuine ✅\n• Lower score = possible fraud ⚠️\n\nIt checks document authenticity & cross-matches fields.",
      hi: "**Fraud Score** ek AI rating hai 0–100% ke beech 🔢\n\n• Zyada score = document sahi hai ✅\n• Kam score = fraud ho sakta hai ⚠️\n\nYe document ki sachhai aur details check karta hai.",
    ),

    // ── View results ───────────────────────────────────────
    _BotRule(
      keywords: ['result', 'output', 'check result', 'view result', 'results', 'dekho', 'kahan hai', 'analysis', 'report dekho'],
      en: "To view your results 📋\n\n👉 Tap **History** at the bottom navigation\n👉 Each entry shows document name, date & verification status",
      hi: "Result dekhne ke liye 📋\n\n👉 Neeche **History** pe tap karo\n👉 Har entry me document ka naam, date aur status dikhega",
    ),

    // ── Download report ────────────────────────────────────
    _BotRule(
      keywords: ['download', 'report', 'export', 'save', 'pdf', 'download kaise', 'report download'],
      en: "To download a report 📥\n\n👉 Open any result from **History**\n👉 Tap the **Download** icon at top-right\n👉 Report saves as PDF",
      hi: "Report download karne ke liye 📥\n\n👉 **History** se koi bhi result kholo\n👉 Upar-daaye **Download** icon pe tap karo\n👉 PDF aa jayegi",
    ),

    // ── Help / what can you do ─────────────────────────────
    _BotRule(
      keywords: ['help', 'guide', 'assist', 'what can you', 'kya puch', 'kya puchu', 'madad'],
      en: "I can help you with 😊\n\n📤 How to upload documents\n📂 Uploading multiple docs\n🔢 What is fraud score\n📋 How to check results\n📥 How to download report\n\nJust ask!",
      hi: "Main in cheezon me madad kar sakta hoon 😊\n\n📤 Document kaise upload karein\n📂 Kai documents ek saath upload karna\n🔢 Fraud score kya hai\n📋 Result kaise dekhein\n📥 Report kaise download karein\n\nBas pucho!",
    ),

    // ── Thanks ─────────────────────────────────────────────
    _BotRule(
      keywords: ['thank', 'thanks', 'ty', 'great', 'awesome', 'perfect', 'shukriya', 'dhanyawad', 'acha', 'theek hai'],
      en: "You're welcome! 😊 Feel free to ask anytime.",
      hi: "Koi baat nahi! 😊 Kabhi bhi pucho.",
    ),
  ];

  // Fallback messages
  static const String _fallbackEn =
      "I didn't understand 😅 Try asking about upload, results, or features.";
  static const String _fallbackHi =
      "Mujhe samajh nahi aaya 😅 Upload ya result ke baare me pucho.";

  /// Normalize: lowercase + trim
  static String _normalize(String input) => input.toLowerCase().trim();

  /// Main respond method.  isHindi drives which language to return.
  static String respond(String input, {required bool isHindi}) {
    final normalized = _normalize(input);
    for (final rule in _rules) {
      for (final kw in rule.keywords) {
        if (normalized.contains(kw)) {
          return isHindi ? rule.hi : rule.en;
        }
      }
    }
    return isHindi ? _fallbackHi : _fallbackEn;
  }

  /// Greeting message for the initial bot bubble
  static String greeting({required bool isHindi}) => isHindi
      ? "Namaste! 😊 Main aapki madad ke liye hoon. App use karne ke baare me pucho."
      : "Hi! I'm here to help 😊 Ask me how to use the app.";
}

// Simple immutable rule holder
class _BotRule {
  final List<String> keywords;
  final String en;
  final String hi;
  const _BotRule({required this.keywords, required this.en, required this.hi});
}

// ═══════════════════════════════════════════════════════════
// FLOATING ACTION BUTTON  (placed on Scaffold)
// ═══════════════════════════════════════════════════════════
class ChatbotFAB extends StatefulWidget {
  const ChatbotFAB({super.key});

  @override
  State<ChatbotFAB> createState() => _ChatbotFABState();
}

class _ChatbotFABState extends State<ChatbotFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.09).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _openChat(BuildContext context) {
    final isHindi =
        Provider.of<SettingsProvider>(context, listen: false).isHindi;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: Provider.of<SettingsProvider>(context, listen: false),
        child: _ChatScreen(initialIsHindi: isHindi),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 72.h),
      child: ScaleTransition(
        scale: _pulseAnim,
        child: GestureDetector(
          onTap: () => _openChat(context),
          child: Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.42),
                  blurRadius: 18.r,
                  spreadRadius: 1,
                  offset: Offset(0, 6.h),
                ),
              ],
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 26.sp,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CHAT SCREEN  (bottom sheet)
// ═══════════════════════════════════════════════════════════
class _ChatScreen extends StatefulWidget {
  final bool initialIsHindi;
  const _ChatScreen({required this.initialIsHindi});

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];

  late AnimationController _sheetCtrl;
  late Animation<double> _sheetAnim;

  bool _isTyping = false;
  bool _greetingSent = false;

  // ── Quick reply chip definitions (EN / HI) ───────────────
  static const _chipsEn = [
    ('📤', 'How to upload'),
    ('📱', 'App features'),
    ('📋', 'View results'),
    ('📥', 'Download report'),
  ];
  static const _chipsHi = [
    ('📤', 'Upload kaise karein'),
    ('📱', 'App features kya hain'),
    ('📋', 'Result kaise dekhein'),
    ('📥', 'Report download karo'),
  ];

  @override
  void initState() {
    super.initState();
    _sheetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _sheetAnim =
        CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutCubic);
    _sheetCtrl.forward();

    // Initial greeting after slight delay
    Future.delayed(const Duration(milliseconds: 380), () {
      if (!mounted || _greetingSent) return;
      _greetingSent = true;
      final isHindi =
          Provider.of<SettingsProvider>(context, listen: false).isHindi;
      _addBotMessage(_BotBrain.greeting(isHindi: isHindi));
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _sheetCtrl.dispose();
    super.dispose();
  }

  // ── Message helpers ──────────────────────────────────────
  void _addBotMessage(String text) {
    if (!mounted) return;
    setState(() => _messages.add(_ChatMessage(text: text, isUser: false)));
    _scrollToBottom();
  }

  void _sendMessage({String? override}) {
    final raw = override ?? _inputCtrl.text;
    final text = raw.trim();
    if (text.isEmpty) return;

    final isHindi =
        Provider.of<SettingsProvider>(context, listen: false).isHindi;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    final delay = 550 + Random().nextInt(400);
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      final response = _BotBrain.respond(text, isHindi: isHindi);
      setState(() => _isTyping = false);
      _addBotMessage(response);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    final chips = isHindi ? _chipsHi : _chipsEn;
    final hintText = isHindi ? 'Kuch puchho...' : 'Ask something...';
    final headerSubtitle =
        isHindi ? 'Online · hamesha yahan hoon' : 'Online · always here for you';

    return AnimatedBuilder(
      animation: _sheetAnim,
      builder: (_, child) => SlideTransition(
        position:
            Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(_sheetAnim),
        child: child,
      ),
      child: Container(
        height: screenHeight * 0.84,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 40,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHandle(isDark),
            _buildHeader(isDark, theme, isHindi, headerSubtitle),
            Divider(height: 1, color: theme.dividerColor.withOpacity(0.08)),
            _buildMessageList(isDark, theme),
            // Show chips only while conversation is short
            if (_messages.length <= 2) _buildChips(chips, isDark),
            _buildInputBar(isDark, theme, hintText),
          ],
        ),
      ),
    );
  }

  // ── Handle bar ───────────────────────────────────────────
  Widget _buildHandle(bool isDark) {
    return Container(
      margin: EdgeInsets.only(top: 12.h, bottom: 4.h),
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.14)
            : Colors.black.withOpacity(0.11),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────
  Widget _buildHeader(
      bool isDark, ThemeData theme, bool isHindi, String subtitle) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 8.w, 12.h),
      child: Row(
        children: [
          // Bot avatar
          Container(
            width: 44.w,
            height: 44.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
              ),
            ),
            child:
                Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? 'AI सहायक' : 'AI Assistant',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Container(
                      width: 7.w,
                      height: 7.w,
                      margin: EdgeInsets.only(right: 5.w),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.38),
              size: 22.sp,
            ),
          ),
        ],
      ),
    );
  }

  // ── Message list ─────────────────────────────────────────
  Widget _buildMessageList(bool isDark, ThemeData theme) {
    return Expanded(
      child: _messages.isEmpty
          ? _buildEmptyState(isDark)
          : ListView.builder(
              controller: _scrollCtrl,
              padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (_isTyping && i == _messages.length) {
                  return _buildTypingIndicator(isDark);
                }
                return _buildBubble(_messages[i], isDark, theme);
              },
            ),
    );
  }

  // ── Empty state ──────────────────────────────────────────
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48.sp,
            color: const Color(0xFF3B82F6).withOpacity(0.28),
          ),
          SizedBox(height: 12.h),
          Text(
            'Start the conversation!',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.32),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chat bubble ──────────────────────────────────────────
  Widget _buildBubble(_ChatMessage msg, bool isDark, ThemeData theme) {
    final isUser = msg.isUser;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, (1 - val) * 14),
          child: child,
        ),
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            bottom: 12.h,
            left: isUser ? 52.w : 0,
            right: isUser ? 0 : 52.w,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Bot avatar
              if (!isUser)
                Container(
                  width: 28.w,
                  height: 28.w,
                  margin: EdgeInsets.only(right: 6.w),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                    ),
                  ),
                  child: Icon(Icons.smart_toy_rounded,
                      color: Colors.white, size: 14.sp),
                ),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 11.h),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF3B82F6)
                        : isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18.r),
                      topRight: Radius.circular(18.r),
                      bottomLeft: Radius.circular(isUser ? 18.r : 4.r),
                      bottomRight: Radius.circular(isUser ? 4.r : 18.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: GoogleFonts.inter(
                      fontSize: 13.5.sp,
                      height: 1.5,
                      color:
                          isUser ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Typing indicator ─────────────────────────────────────
  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h, left: 34.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: _TypingDots(isDark: isDark),
      ),
    );
  }

  // ── Quick reply chips ────────────────────────────────────
  Widget _buildChips(List<(String, String)> chips, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: chips.map((chip) {
          final label = '${chip.$1} ${chip.$2}';
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GestureDetector(
              onTap: () => _sendMessage(override: chip.$2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFEFF6FF),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.35),
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.08),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Input bar ────────────────────────────────────────────
  Widget _buildInputBar(bool isDark, ThemeData theme, String hint) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 12.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.38),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 18.w, vertical: 14.h),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _sendMessage(),
              child: Container(
                margin: EdgeInsets.all(6.w),
                width: 42.w,
                height: 42.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                  ),
                ),
                child:
                    Icon(Icons.send_rounded, color: Colors.white, size: 18.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ANIMATED TYPING DOTS
// ═══════════════════════════════════════════════════════════
class _TypingDots extends StatefulWidget {
  final bool isDark;
  const _TypingDots({required this.isDark});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with TickerProviderStateMixin {
  final List<AnimationController> _ctrls = [];
  final List<Animation<double>> _anims = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      );
      _anims.add(
        Tween<double>(begin: 0.0, end: -6.0).animate(
          CurvedAnimation(parent: c, curve: Curves.easeInOut),
        ),
      );
      _ctrls.add(c);
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) c.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _anims[i].value),
            child: Container(
              width: 7.w,
              height: 7.w,
              margin: EdgeInsets.symmetric(horizontal: 2.5.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(0.68),
              ),
            ),
          ),
        );
      }),
    );
  }
}
