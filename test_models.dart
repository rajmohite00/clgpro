import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  final apiKey = 'AIzaSyDByuv-Y2vznv4JVg9IAcnpwU4sGXCfsT8';
  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  try {
    final response = await model.generateContent([Content.text('say hi')]);
    print('gemini-1.5-flash WORKS! Response: ${response.text}');
  } catch (e) {
    print('gemini-1.5-flash failed: $e');
  }

  try {
    final model2 = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
    final response = await model2.generateContent([Content.text('say hi')]);
    print('gemini-2.0-flash WORKS! Response: ${response.text}');
  } catch (e) {
    print('gemini-2.0-flash failed: $e');
  }

  try {
    final model3 = GenerativeModel(model: 'gemini-1.5-pro', apiKey: apiKey);
    final response = await model3.generateContent([Content.text('say hi')]);
    print('gemini-1.5-pro WORKS! Response: ${response.text}');
  } catch (e) {
    print('gemini-1.5-pro failed: $e');
  }
}
