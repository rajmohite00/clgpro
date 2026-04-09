import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../providers/settings_provider.dart';

// ═══════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════
class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isPdfResult;
  _ChatMessage({required this.text, required this.isUser, this.isPdfResult = false});
}

// ═══════════════════════════════════════════════════════════
// FLOATING ACTION BUTTON  (placed on Scaffold)
// ═══════════════════════════════════════════════════════════
class ChatbotFAB extends StatefulWidget {
  const ChatbotFAB({super.key});

  @override
  State<ChatbotFAB> createState() => _ChatbotFABState();
}

class _ChatbotFABState extends State<ChatbotFAB> with SingleTickerProviderStateMixin {
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
    final isHindi = Provider.of<SettingsProvider>(context, listen: false).isHindi;
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

class _ChatScreenState extends State<_ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];

  late AnimationController _sheetCtrl;
  late Animation<double> _sheetAnim;

  bool _isTyping = false;
  bool _greetingSent = false;

  // ── API KEY ROTATION ─────────────────────────────────────────
  // Add up to 5 free Gemini API keys. When one hits the rate limit,
  // the next is used automatically — completely invisible to the user.
  static const List<String> _apiKeys = [
    "AIzaSyCitrLAFN-C6qD7rFdzpsSMaidyVtOmhuM", // Key 1 (current)
    "AIzaSyAfLhtjJTs-jy--wZeYOh44QVBbY_o-Xio",                          // Key 2
    "AIzaSyAYIgw1LvfOFrUPV3SwcA_qeBD1WqkRRRQ",                          // Key 3
    "AIzaSyC1U_8WGv7Beq-p6XojjtRTdcF8fHvTauM",                          // Key 4
    "AIzaSyCAhycjL6fpvIqP1RrTQ7JGUwcGhCFTKck",                          // Key 5
  ];
  int _currentKeyIndex = 0;
  late GenerativeModel _model;
  late ChatSession _chatSession;

  // Build a model with the key at [index]
  GenerativeModel _buildModel(int keyIndex, String langInstruction) {
    return GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKeys[keyIndex],
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
      systemInstruction: Content.system(
        "You are the AI assistant for 'Satya Agent' (Smart Document Detective API app). "
        "Your job is to help users upload documents, understand the AI Fraud Score (0-100%), "
        "view results in history, or summarize uploaded PDFs. Explain things concisely and be friendly. "
        "Use bolding and emojis to make things readable. $langInstruction",
      ),
    );
  }

  // Rotate to next available key; returns false if all keys are exhausted
  bool _rotateKey() {
    if (_currentKeyIndex < _apiKeys.length - 1) {
      _currentKeyIndex++;
      final isHindi = Provider.of<SettingsProvider>(context, listen: false).isHindi;
      final langInstruction = isHindi
          ? 'Always reply in Hindi using English characters (Hinglish) or Devanagari based on what user uses. '
          : 'Always reply in English. ';
      _model = _buildModel(_currentKeyIndex, langInstruction);
      _chatSession = _model.startChat();
      return true;
    }
    return false; // All keys exhausted
  }

  void _initGemini() {
    final isHindi = Provider.of<SettingsProvider>(context, listen: false).isHindi;
    final langInstruction = isHindi
        ? 'Always reply in Hindi using English characters (Hinglish) or Devanagari based on what user uses. '
        : 'Always reply in English. ';
    _model = _buildModel(_currentKeyIndex, langInstruction);
    _chatSession = _model.startChat();
  }

  @override
  void initState() {
    super.initState();
    _sheetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _sheetAnim = CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutCubic);
    _sheetCtrl.forward();

    _initGemini();

    Future.delayed(const Duration(milliseconds: 380), () {
      if (!mounted || _greetingSent) return;
      _greetingSent = true;
      final isHindi = Provider.of<SettingsProvider>(context, listen: false).isHindi;
      _addBotMessage(
        isHindi
          ? "Namaste! 😊 Main aapki madad ke liye hoon. Aap PDF ya image upload kar sakte hain summary ke liye (📎 tap karein), ya mujhse kuch bhi puch sakte hain."
          : "Hi! I'm your AI assistant 😊 I can answer questions, or you can click the 📎 icon to upload a PDF or Image and I will summarize it for you in real-time.",
      );
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _sheetCtrl.dispose();
    super.dispose();
  }

  void _addBotMessage(String text, {bool isPdfResult = false}) {
    if (!mounted) return;
    setState(() => _messages.add(_ChatMessage(text: text, isUser: false, isPdfResult: isPdfResult)));
    _scrollToBottom();
  }

  Future<void> _sendMessage({String? override}) async {
    final raw = override ?? _inputCtrl.text;
    final text = raw.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();
    _inputCtrl.clear();

    GenerateContentResponse? response;
    // Try every available key silently — user sees nothing if a key rotates
    for (int attempt = 0; attempt < _apiKeys.length; attempt++) {
      try {
        response = await _chatSession.sendMessage(Content.text(text));
        break; // Success!
      } catch (err) {
        final errorStr = err.toString();
        if (errorStr.contains('503')) {
          // Server overload — brief wait, retry same key
          await Future.delayed(const Duration(seconds: 4));
          continue;
        } else if (errorStr.toLowerCase().contains('quota') || errorStr.contains('429')) {
          // Rate limited — silently switch to next key
          final rotated = _rotateKey();
          if (!rotated) {
            // All 5 keys exhausted
            setState(() => _isTyping = false);
            _addBotMessage("All API keys are currently busy. Please wait 1 minute and try again.");
            return;
          }
          // Retry automatically with new key (no message shown to user)
          continue;
        } else {
          setState(() => _isTyping = false);
          _addBotMessage("Error: $err");
          return;
        }
      }
    }

    setState(() => _isTyping = false);
    _addBotMessage(response?.text ?? "I couldn't process that.");
  }

  bool _isPickerActive = false;

  Future<void> _pickAndProcessFile() async {
    if (_isPickerActive) return;
    _isPickerActive = true;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        final ext = result.files.single.extension?.toLowerCase() ?? '';

        setState(() {
          _messages.add(_ChatMessage(text: "📎 Uploaded file: $fileName", isUser: true));
          _isTyping = true;
        });
        _scrollToBottom();

        final File file = File(filePath);
        final bytes = await file.readAsBytes();
        final promptText = "I have uploaded a document named '$fileName'. Please provide a clear summary of this document, state the main points, and suggest any actions or solutions I should take based on it.";

        String mimeType;
        if (ext == 'pdf') {
          mimeType = 'application/pdf';
        } else if (ext == 'png') {
          mimeType = 'image/png';
        } else if (ext == 'webp') {
          mimeType = 'image/webp';
        } else {
          mimeType = 'image/jpeg';
        }

        // RESET CHAT SESSION SO IT DOESNT OVERLOAD NETWORK WITH OLD IMAGES
        _chatSession = _model.startChat();
        
        final documentPart = DataPart(mimeType, bytes);
        
        GenerateContentResponse? response;
        // Silent key rotation for file uploads too
        for (int attempt = 0; attempt < _apiKeys.length; attempt++) {
          try {
            _chatSession = _model.startChat();
            response = await _chatSession.sendMessage(Content.multi([TextPart(promptText), documentPart]));
            break; // Success!
          } catch(err) {
            final errorStr = err.toString();
            if (errorStr.contains('503')) {
              await Future.delayed(const Duration(seconds: 3));
              continue;
            } else if (errorStr.toLowerCase().contains('quota') || errorStr.contains('429')) {
              // Silently switch key
              final rotated = _rotateKey();
              if (!rotated) rethrow;
              continue;
            } else {
              rethrow;
            }
          }
        }
        
        setState(() => _isTyping = false);
        final iconEmoji = ext == 'pdf' ? '📄' : '🖼️';
        _addBotMessage("$iconEmoji **Analysis Complete**\n\n${response?.text ?? 'No response'}", isPdfResult: true);
      }
    } catch (e) {
      setState(() => _isTyping = false);
      String errorMsg = e.toString();
      if (errorMsg.startsWith("Exception: ")) {
        errorMsg = errorMsg.replaceFirst("Exception: ", "");
      }
      _addBotMessage(errorMsg.contains("Sorry") ? errorMsg : "Sorry, I encountered an error: $errorMsg");
    } finally {
      _isPickerActive = false;
    }
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

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    final hintText = isHindi ? 'Kuch puchho...' : 'Ask something...';
    final headerSubtitle = isHindi ? 'Online · intelligent PDF assistant' : 'Online · intelligent PDF assistant';

    return AnimatedBuilder(
      animation: _sheetAnim,
      builder: (_, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(_sheetAnim),
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
            _buildInputBar(isDark, theme, hintText),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Container(
      margin: EdgeInsets.only(top: 12.h, bottom: 4.h),
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.14) : Colors.black.withOpacity(0.11),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  Widget _buildHeader(bool isDark, ThemeData theme, bool isHindi, String subtitle) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 8.w, 12.h),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
              ),
            ),
            child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? 'AI सहायक' : 'AI Assistant (Gemini 2.0 Flash)',
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

  Widget _buildMessageList(bool isDark, ThemeData theme) {
    return Expanded(
      child: _messages.isEmpty
          ? _buildEmptyState(isDark)
          : ListView.builder(
              controller: _scrollCtrl,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
            'Start the conversation or upload a PDF!',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.32),
            ),
          ),
        ],
      ),
    );
  }

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
                  child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 14.sp),
                ),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
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
                    border: msg.isPdfResult ? Border.all(color: const Color(0xFF60A5FA), width: 1.5) : null,
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
                      color: isUser ? Colors.white : theme.colorScheme.onSurface,
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

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h, left: 34.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: _TypingDots(isDark: isDark),
      ),
    );
  }

  Widget _buildInputBar(bool isDark, ThemeData theme, String hint) {
    final borderColor = isDark ? Colors.white.withOpacity(0.10) : const Color(0xFF3B82F6).withOpacity(0.22);
    final fillColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // File Upload Button
            GestureDetector(
              onTap: _pickAndProcessFile,
              child: Container(
                margin: EdgeInsets.only(right: 8.w),
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                ),
                child: Icon(Icons.attach_file_rounded, color: const Color(0xFFEF4444), size: 22.sp),
              ),
            ),
            // Text field
            Expanded(
              child: Container(
                constraints: BoxConstraints(minHeight: 48.h),
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: TextField(
                  controller: _inputCtrl,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: 4,
                  minLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    height: 1.45,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.36),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
                    isDense: true,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // Send button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.35),
                      blurRadius: 10.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
