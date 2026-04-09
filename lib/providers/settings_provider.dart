import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isHindi = false;
  bool _notificationsEnabled = true;
  Color _accentColor = const Color(0xFF3B82F6);

  bool  get isHindi              => _isHindi;
  bool  get notificationsEnabled => _notificationsEnabled;
  Color get accentColor          => _accentColor;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isHindi = prefs.getBool('isHindi') ?? false;
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    final colorValue = prefs.getInt('accentColor');
    if (colorValue != null) _accentColor = Color(colorValue);
    notifyListeners();
  }

  Future<void> toggleLanguage(bool val) async {
    _isHindi = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isHindi', val);
    notifyListeners();
  }

  Future<void> toggleNotifications(bool val) async {
    _notificationsEnabled = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', val);
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accentColor', color.value);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('history_results');
    await prefs.remove('bookmarked_results');
    notifyListeners();
  }
}

// A simple translation map to keep things lightweight
String tr(String text, bool isHindi) {
  if (!isHindi) return text;

  const map = {
    'Settings': 'सेटिंग्स',
    'Preferences': 'अपनी पसंद',
    'Dark Mode': 'डार्क मोड',
    'Toggle dark and light themes dynamically.': 'डार्क और लाइट थीम बदलें।',
    'Language': 'भाषा',
    'Switch language between English and Hindi.': 'अंग्रेज़ी और हिंदी में बदलें।',
    'Push Notifications': 'नोटिफिकेशन',
    'Alert me instantly when remote analysis finishes.': 'स्कैन पूरा होने पर मुझे बताएं।',
    'Privacy Mode': 'प्राइवेसी मोड',
    'Hide sensitive data on dashboards and reports.': 'अपना ज़रूरी डेटा छिपाएं।',
    'Data Management': 'डेटा मैनेजमेंट',
    'Clear All History': 'सारी हिस्ट्री मिटाएं',
    'Permanently delete entire scan history from device.': 'फोन से पूरी स्कैन हिस्ट्री हमेशा के लिए मिटा दें।',
    'About & Privacy': 'ऐप और प्राइवेसी',
    'Data Privacy Policy': 'प्राइवेसी पॉलिसी',
    'Terms of Service': 'शर्तें',
    'Application Version': 'ऐप वर्ज़न',
    'Hi, Raj 👋': 'नमस्ते, राज 👋',
    'Scan New Document': 'नया डॉक्यूमेंट स्कैन करें',
    'Upload Documents': 'डॉक्यूमेंट अपलोड करें',
    'Secure identity verification in seconds': 'सेकंडों में पक्की चेकिंग',
    'Tap to start a new analysis': 'नया स्कैन शुरू करने के लिए टैप करें',
    'Last Scan': 'आखिरी स्कैन',
    'Total Checks': 'कुल चेक',
    'Total': 'कुल',
    'Matches': 'मैच',
    'Today': 'आज',
    'Recent Activity': 'हाल की एक्टिविटी',
    'Home': 'होम',
    'History': 'हिस्ट्री',
    'Profile': 'प्रोफ़ाइल',
    'Edit Profile Information': 'प्रोफ़ाइल बदलें',
    'Change Password': 'पासवर्ड बदलें',
    'Log Out': 'लॉग आउट',
    'Recent Analyses': 'हाल के स्कैन',
    'Search by name or date...': 'नाम या तारीख से खोजें...',
    'No History Yet': 'अभी कोई हिस्ट्री नहीं है',
    'Past document analyses will appear here.': 'आपके पुराने स्कैन यहां दिखेंगे।',
    'No results found': 'कुछ नहीं मिला',
    'Try adjusting your search terms.': 'कुछ और लिखकर खोजें।',
    
    // Upload Screen
    'Select Documents': 'डॉक्यूमेंट चुनें',
    'Add images or PDFs (max 10MB per file)': 'फोटो या PDF डालें (10MB तक)',
    'Take Photo': 'फोटो लें',
    'Select Files': 'फ़ाइलें चुनें',
    'Selected Files': 'चुनी गई फ़ाइलें',
    'Next': 'अगला',

    // Preview Screen
    'Preview Selection': 'क्या चुना है, वो देखें',
    'Uploading files to server...': 'फ़ाइलें अपलोड हो रही हैं...',
    'Add More': 'और जोड़ें',
    'Continue': 'आगे बढ़ें',

    // Processing Screen
    'Analyzing Documents...': 'डॉक्यूमेंट चेक हो रहे हैं...',
    'Checking authenticity & mismatches': 'असली-नकली और गलतियों की जांच हो रही है',
    'Analysis Failed': 'चेकिंग फेल हो गई',
    'API Timeout: Failed to analyze documents. Please try again.': 'नेटवर्क प्रॉब्लम: डॉक्यूमेंट चेक नहीं हो पाए। फिर से कोशिश करें।',
    'Retry Analysis': 'फिर से चेक करें',

    // Result Screen
    'Analysis Report': 'स्कैन रिपोर्ट',
    'Fraud Analysis Report': 'धोखाधड़ी विश्लेषण',
    'Documents Match': 'डॉक्यूमेंट मैच हो गए !',
    'Mismatch Detected': 'डॉक्यूमेंट में गलती मिली',
    'All verified fields align properly.': 'सारी जानकारी सही से मिल गई है।',
    'We found discrepancies between the provided documents.': 'दिए गए डॉक्यूमेंट्स में कुछ जानकारी अलग है।',
    'Download Report': 'रिपोर्ट डाउनलोड करें',
    'Back to Dashboard': 'होम पर वापस जाएं',
    'Re-upload Documents': 'फिर से डॉक्यूमेंट अपलोड करें',
    'Detailed Comparison': 'पूरी जानकारी',
    'DOCUMENT 1': 'डॉक्यूमेंट 1',
    'DOCUMENT 2': 'डॉक्यूमेंट 2',

    // Login Screen
    'Welcome Back': 'फिर से स्वागत है!',
    'Please enter your details to sign in.': 'लॉगिन करने के लिए अपनी डिटेल डालें।',
    'Email': 'ईमेल',
    'Password': 'पासवर्ड',
    'Forgot password?': 'पासवर्ड भूल गए?',
    'Sign in': 'लॉगिन करें',
    "Don't have an account? ": "अकाउंट नहीं है? ",
    'Sign up': 'नया अकाउंट बनाएं',

    // Onboarding Screen
    'Verify Documents\nInstantly': 'डॉक्यूमेंट तुरंत\nचेक करें',
    'Upload Aadhaar, PAN, or any document and let AI verify authenticity in seconds.': 'आधार, PAN या कोई भी डॉक्यूमेंट अपलोड करें और AI से सेकंडों में असली-नकली चेक करें।',
    'Detect Mismatches\n& Fraud': 'गलतियां और फ्रॉड\nपकड़ें',
    'Compare multiple documents and identify mismatches with smart AI analysis.': 'कई डॉक्यूमेंट्स को मिलाएं और स्मार्ट AI से झटपट गलतियां पकड़ें।',
    'Get Started': 'शुरू करें',

    // Signup Screen
    'Create Account': 'नया अकाउंट बनाएं',
    'Join us to get started': 'शुरू करने के लिए हमारे साथ जुड़ें',
    'Full Name': 'पूरा नाम',
    'Email Address': 'ईमेल आईडी',
    'Confirm Password': 'फिर से पासवर्ड डालें',
    'Sign Up': 'अकाउंट बनाएं',

    // Forgot Password Screen
    'Reset Password': 'अपना पासवर्ड बदलें',
    'Enter your email address to receive a password reset link.': 'नया पासवर्ड बनाने के लिए अपना ईमेल डालें।',
    'Send Reset Link': 'लिंक मंगाएं',

    // Edit Profile Screen
    'Edit Profile': 'प्रोफ़ाइल बदलें',
    'Update your personal information': 'अपनी जानकारी अपडेट करें',
    'Save Changes': 'बदलाव सेव करें',
    'Profile updated successfully!': 'प्रोफ़ाइल अपडेट हो गई!',
    'Error updating profile. Please try again.': 'प्रोफ़ाइल अपडेट में दिक्कत। फिर से कोशिश करें।',
    'Fields cannot be empty': 'सभी खाने भरना ज़रूरी है',

    // Change Password Screen
    'Use a strong password to keep your account secure.': 'अपना अकाउंट सुरक्षित रखने के लिए मज़बूत पासवर्ड बनाएं।',
    'Current Password': 'पुराना पासवर्ड',
    'New Password': 'नया पासवर्ड',
    'Confirm New Password': 'नया पासवर्ड दोबारा डालें',
    'Password must be at least 6 characters long.': 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए।',
    'Update Password': 'पासवर्ड बदलें',
    'Password changed successfully!': 'पासवर्ड बदल गया!',
    'Passwords do not match': 'दोनों पासवर्ड एक जैसे नहीं हैं',

    // Profile Screen
    'Confirm Logout': 'लॉगआउट की पुष्टि करें',
    'Are you sure you want to log out?': 'क्या आप वाकई लॉगआउट करना चाहते हैं?',
    'Cancel': 'रद्द करें',
    'Logged out successfully': 'लॉगआउट हो गए',
    'Verified User': 'वेरिफाइड यूजर',

    // Login/Auth
    'New here?': 'पहली बार आए हैं?',
    'Processing details...': 'विवरण संसाधित हो रहा है...',
    'Scanning document...': 'डॉक्यूमेंट स्कैन हो रहा है...',
    'Extracting data...': 'डेटा निकाला जा रहा है...',
    'Analyzing authenticity...': 'असलियत जांची जा रही है...',
    'Generating report': 'रिपोर्ट बन रही है',
    'Fraud Risk Score': 'धोखाधड़ी जोखिम स्कोर',
    'Comparison Options': 'तुलना के विकल्प',
    'Copy Details': 'जानकारी कॉपी करें',
    'Share': 'शेयर करें',
    'Save Field': 'फील्ड सेव करें',
    'Uploaded Documents': 'अपलोड किए डॉक्यूमेंट',
    'Verified': 'सत्यापित',

    'See all': 'सभी देखें',
    'Good Morning': 'सुप्रभात',
    'Good Afternoon': 'नमस्ते',
    'Good Evening': 'शुभ संध्या',
    'Ready to scan a document?': 'क्या आप एक डॉक्यूमेंट स्कैन करने के लिए तैयार हैं?',
    'Scanned': 'स्कैन किए',
    'Analytics': 'विश्लेषण',
    'Streak': 'स्ट्रीक',
    'days': 'दिन',
    'Switch between English and Hindi': 'अंग्रेज़ी और हिंदी में बदलें',
    'Toggle dark and light themes': 'डार्क और लाइट थीम बदलें',
    'Alert when analysis finishes': 'स्कैन खत्म होने पर अलर्ट',
    'Accent Color': 'रंग चुनें',
    'Personalize your app color': 'अपना पसंदीदा रंग चुनें',
    'Permanently delete scan history': 'स्कैन हिस्ट्री हमेशा के लिए मिटाएं',
    'Bookmarked': 'बुकमार्क',
    'All': 'सभी',
    'Export CSV': 'CSV डाउनलोड',
    'Add Note': 'नोट जोड़ें',
    'Note saved': 'नोट सेव हो गया',
    'Copied!': 'कॉपी हो गया!',
    'Rate Us': 'रेटिंग दें',
    'Enjoying the app?': 'ऐप अच्छा लग रहा है?',
    'Day Streak': 'दिन की स्ट्रीक',
    
    // Additional translations
    'Welcome back to DocVerify': 'DocVerify में आपकी वापसी का स्वागत है',
    'Total Scans': 'कुल स्कैन',
    'No scans yet. Upload a document to begin.': 'अभी तक कोई स्कैन नहीं। शुरू करने के लिए दस्तावेज़ अपलोड करें।',
    'Help us improve by leaving a rating.': 'रेटिंग देकर ऐप को बेहतर बनाने में हमारी मदद करें।',
    'Later': 'बाद में',
    'Verify a Document': 'दस्तावेज़ की जांच करें',
    'Upload and check document authenticity': 'अपलोड करें और असली-नकली चेक करें',
    'Record deleted': 'रिकॉर्ड मिटा दिया गया',
    'Add a personal note to this scan record': 'इस स्कैन रिपोर्ट के लिए एक नोट लिखें',
    'Save Note': 'नोट सेव करें',
    'Delete': 'डिलीट करें',
    'Share Result': 'रिजल्ट शेयर करें',
    'Delete record?': 'रिकॉर्ड मिटाएं?',
    'This cannot be undone.': 'इसे वापस नहीं लाया जा सकता।',
    'Export PDF': 'PDF डाउनलोड करें',
    'Summary': 'संक्षेप',
    'Risk Score': 'जोखिम स्कोर',
    'EXTRACTED DATA': 'निकाला गया डेटा',
    'PDF Report': 'PDF रिपोर्ट',
    'Disable App Lock': 'ऐप लॉक बंद करें',
    'Are you sure you want to remove the PIN lock?': 'क्या आप वाकई PIN लॉक हटाना चाहते हैं?',
    'Disable': 'बंद करें',
    'App Lock enabled!': 'ऐप लॉक चालू हो गया!',
    'Clear History?': 'हिस्ट्री मिटाएं?',
    'History cleared.': 'हिस्ट्री मिटा दी गई।',
    'Genuine vs Fraudulent': 'असली बनाम नकली',
    'Genuine': 'असली',
    'Fraudulent': 'नकली',
    'No scans yet — run your first analysis to see data here.': 'कोई स्कैन नहीं — डेटा देखने के लिए अपना पहला स्कैन चलाएं।',
    'Scans This Week': 'इस हफ़्ते के स्कैन',
    'last 7 days': 'पिछले 7 दिन',
    'No recent scans': 'हाल में कोई स्कैन नहीं',
    'Document Types Scanned': 'स्कैन किए गए दस्तावेज़ों के प्रकार',
    'Hi': 'नमस्ते',
    'document(s) ready for analysis': 'दस्तावेज़ स्कैन के लिए तैयार',
    'PDF Document': 'PDF दस्तावेज़',
    'Remove': 'हटाएं',
    'Please wait, this may take a moment': 'कृपया प्रतीक्षा करें, इसमें थोड़ा समय लग सकता है',
  };

  return map[text] ?? text;
}
