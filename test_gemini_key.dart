import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  const apiKey = 'AIzaSyBn5QMS_669R_FKBmB1plEZ6aeXgUlEe0g';
  print('Testing Gemini API Key...');

  try {
    // We try gemini-1.5-flash as the fallback, or what the user was using
    final modelNamesToTest = ['gemini-2.5-flash', 'gemini-1.5-flash'];
    
    for (var modelName in modelNamesToTest) {
      print('\nTrying model: \$modelName');
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
        );

        final response = await model.generateContent([Content.text('Say "API limit check successful!"')]);
        print('✅ Success with \$modelName: \${response.text?.trim()}');
        
        // If it succeeds with 2.5, no need to test 1.5
        break;
      } catch (e) {
        if (e.toString().contains('models/gemini-2.5-flash is not found')) {
           print('❌ Model \$modelName not available on this key.');
        } else {
           print('❌ Failed with \$modelName: \$e');
           // Re-throw if it's an API key error like 403 or quota so we can see it
           if (e.toString().contains('API_KEY_INVALID') || e.toString().contains('Quota')) {
             return;
           }
        }
      }
    }
  } catch (e) {
    print('Critical Error: \$e');
  }
}
