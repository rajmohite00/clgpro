import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import '../providers/settings_provider.dart';

// ═══════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════
class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isPdfResult;
  final bool isVoiceResult;
  final List<String>? sources;
  _ChatMessage({
    required this.text,
    required this.isUser,
    this.isPdfResult = false,
    this.isVoiceResult = false,
    this.sources,
  });
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
  bool _lastIsHindi = false; // tracks language to detect changes

  // ── LOCAL LLAMA 3 STATE ──────────────────────────────────────
  final List<Map<String, String>> _llamaHistory = [];

  // ── VOICE AGENT STATE ────────────────────────────────────────
  bool _isVoiceAgentMode = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _apiBaseUrl = 'http://10.0.2.2:8000'; // Default for Android Emulator

  void _initLlama() {
    final isHindi = Provider.of<SettingsProvider>(context, listen: false).isHindi;
    final langInstruction = isHindi
        ? 'Always reply in Hindi using English characters (Hinglish) or Devanagari based on what user uses. '
        : 'Always reply in English. ';
        
    _llamaHistory.clear();
    _llamaHistory.add({
      "role": "system",
      "content": "You are the AI assistant for 'Satya Agent' (Smart Document Detective API app). Your job is to help users upload documents, view results, or summarize PDFs. Explain things concisely and be friendly. Use bolding and emojis to make things readable. $langInstruction"
    });
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

    _initLlama();

    Future.delayed(const Duration(milliseconds: 380), () {
      if (!mounted || _greetingSent) return;
      _greetingSent = true;
      final isHindi = Provider.of<SettingsProvider>(context, listen: false).isHindi;
      _addBotMessage(
        isHindi
          ? "Namaste! 😊 Main aapki madad ke liye hoon. Aap PDF upload kar sakte hain, ya 🎙️ tap kar ke Voice Knowledge Base mode use kar sakte hain."
          : "Hi! I'm your AI assistant 😊 I can answer questions, summarize PDFs, or you can tap 🎙️ to use the Voice RAG Knowledge Base.",
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Detect language change and reinitialize Gemini with correct language
    final isHindi = Provider.of<SettingsProvider>(context, listen: false).isHindi;
    if (isHindi != _lastIsHindi) {
      _lastIsHindi = isHindi;
      _initLlama(); // Rebuild with correct language instruction
      if (_greetingSent) {
        // Send a follow-up greeting in the new language
        Future.microtask(() => _addBotMessage(
          isHindi
            ? "🇮🇳 Bhasha badal gayi! Ab main Hindi mein jawab dunga. 😊"
            : "🇬🇧 Language switched to English! How can I help you? 😊",
        ));
      }
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _sheetCtrl.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _addBotMessage(String text, {bool isPdfResult = false, bool isVoiceResult = false, List<String>? sources}) {
    if (!mounted) return;
    setState(() => _messages.add(_ChatMessage(text: text, isUser: false, isPdfResult: isPdfResult, isVoiceResult: isVoiceResult, sources: sources)));
    _scrollToBottom();
  }

  Future<void> _playAudio(String base64Data) async {
    try {
      final bytes = base64Decode(base64Data);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/response_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await file.writeAsBytes(bytes);
      await _audioPlayer.play(DeviceFileSource(file.path));
    } catch (_) {}
  }

  void _openVoiceSettings() {
    final urlCtrl = TextEditingController(text: _apiBaseUrl);
    bool localToggle = _isVoiceAgentMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Text('Voice RAG System', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16.sp)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile.adaptive(
                title: Text('Enable Voice Mode', style: GoogleFonts.inter(fontSize: 14.sp)),
                value: localToggle,
                activeThumbColor: const Color(0xFF6366F1),
                activeTrackColor: const Color(0xFF6366F1).withOpacity(0.4),
                onChanged: (v) => setD(() => localToggle = v),
              ),
              if (localToggle) ...[
                SizedBox(height: 10.h),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Backend URL',
                    hintText: 'http://10.0.2.2:8000',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isVoiceAgentMode = localToggle;
                  _apiBaseUrl = urlCtrl.text.trim();
                });
                Navigator.pop(ctx);
                if (_isVoiceAgentMode) _addBotMessage('🎙️ Voice mode enabled! Type or ask questions to search the vector database.', isVoiceResult: true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
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

    if (_isVoiceAgentMode) {
      try {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/api/ask'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({"text": text}),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final answer = data['answer'] ?? "No answer.";
          final sources = List<String>.from(data['sources'] ?? []);
          final b64Audio = data['audio_base64'] ?? "";
          
          setState(() => _isTyping = false);
          _addBotMessage(answer, isVoiceResult: true, sources: sources);
          
          if (b64Audio.isNotEmpty) {
            await _playAudio(b64Audio);
          }
        } else {
          setState(() => _isTyping = false);
          _addBotMessage("🚨 Backend Error: ${response.statusCode}");
        }
      } catch (e) {
        setState(() => _isTyping = false);
        _addBotMessage("🚨 Could not reach Python Voice Backend.\nMake sure $_apiBaseUrl is running.");
      }
      return;
    }

    _llamaHistory.add({"role": "user", "content": text});

    final apiKey = dotenv.env['GROQ_API_KEY'] ?? "";

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.1-8b-instant",
          "messages": _llamaHistory,
          "temperature": 0.7
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'];
        _llamaHistory.add({"role": "assistant", "content": reply});
        setState(() => _isTyping = false);
        _addBotMessage(reply);
      } else {
        setState(() => _isTyping = false);
        _addBotMessage("🚨 **Groq API Error** 🚨\n\nCode: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isTyping = false);
      _addBotMessage("🚨 **Connection Failed** 🚨\n\nCould not connect to Groq Cloud.");
    }
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

        String extractedText = "";
        if (ext == 'pdf') {
          final PdfDocument document = PdfDocument(inputBytes: bytes);
          extractedText = PdfTextExtractor(document).extractText();
          document.dispose();
          
          if (extractedText.trim().isEmpty) {
            extractedText = "[Could not extract text from this PDF. It might be scanned images.]";
          }
        } else {
          setState(() => _isTyping = false);
          _addBotMessage("📸 **Image Uploaded**\n\n*Note: The local Llama-3 model only supports text PDFs right now. I cannot 'see' images yet!*");
          _isPickerActive = false;
          return;
        }

        final promptText = "I have uploaded a document named '$fileName'. Here is the text extracted from it:\n\n---\n$extractedText\n---\n\nPlease provide a clear summary of this document, state the main points, and suggest any actions or solutions I should take based on it. Keep your answer clean and readable.";

        // Clear history to save context size when doing document summaries
        _initLlama(); 
        _llamaHistory.add({"role": "user", "content": promptText});

        final apiKey = dotenv.env['GROQ_API_KEY'] ?? "";

        try {
          final response = await http.post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              "model": "llama-3.1-8b-instant",
              "messages": _llamaHistory,
              "temperature": 0.3 
            }),
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final reply = data['choices'][0]['message']['content'];
            _llamaHistory.add({"role": "assistant", "content": reply});
            setState(() => _isTyping = false);
            _addBotMessage("📄 **Analysis Complete**\n\n$reply", isPdfResult: true);
          } else {
            setState(() => _isTyping = false);
            _addBotMessage("🚨 **Groq API Error** 🚨\n\nCode: ${response.statusCode}");
          }
        } catch (err) {
          setState(() => _isTyping = false);
          _addBotMessage("🚨 **Connection Failed** 🚨\n\nCould not connect to Groq cloud.");
        }
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
                  _isVoiceAgentMode ? 'RAG Voice Agent 🎙️' : (isHindi ? 'AI सहायक' : 'AI Assistant (Groq Cloud Llama 3)'),
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
                      _isVoiceAgentMode ? 'FastAPI Cloud Vector Backend' : subtitle,
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
          GestureDetector(
            onTap: _openVoiceSettings,
            child: Container(
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: _isVoiceAgentMode ? const Color(0xFF6366F1).withOpacity(0.15) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isVoiceAgentMode ? Icons.headset_mic_rounded : Icons.headset_off_rounded,
                color: _isVoiceAgentMode ? const Color(0xFF6366F1) : theme.colorScheme.onSurface.withOpacity(0.38),
                size: 22.sp,
              ),
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
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
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
                    border: msg.isPdfResult ? Border.all(color: const Color(0xFF60A5FA), width: 1.5) : msg.isVoiceResult ? Border.all(color: const Color(0xFF6366F1), width: 1.5) : null,
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
        if (!isUser && msg.sources != null && msg.sources!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 40.w, top: 2.h, bottom: 8.h),
            child: Wrap(
              spacing: 4.w,
              runSpacing: 4.h,
              children: msg.sources!.map((s) => Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                ),
                child: Text('📄 $s', style: GoogleFonts.inter(fontSize: 10.sp, color: const Color(0xFF6366F1), fontWeight: FontWeight.bold)),
              )).toList(),
            ),
          ),
      ]),
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isVoiceAgentMode ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)] : [const Color(0xFF60A5FA), const Color(0xFF3B82F6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isVoiceAgentMode ? const Color(0xFF6366F1) : const Color(0xFF3B82F6)).withOpacity(0.35),
                      blurRadius: 10.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Icon(_isVoiceAgentMode ? Icons.record_voice_over_rounded : Icons.send_rounded, color: Colors.white, size: 20.sp),
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
