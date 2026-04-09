import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  final apiKey = 'AIzaSyDByuv-Y2vznv4JVg9IAcnpwU4sGXCfsT8';
  
  final modelsToTest = [
    'gemini-flash-latest', 
    'gemini-2.0-flash-lite-001',
    'gemini-2.5-flash',
  ];

  for (var m in modelsToTest) {
    try {
      final model = GenerativeModel(model: m, apiKey: apiKey);
      final response = await model.generateContent([Content.text('say hi')]);
      print('$m WORKS! Response: ${response.text}');
      return; 
    } catch (e) {
      print('$m failed: $e');
    }
  }
}
