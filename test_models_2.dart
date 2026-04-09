import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  final apiKey = 'AIzaSyDByuv-Y2vznv4JVg9IAcnpwU4sGXCfsT8';
  
  try {
    final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
    final response = await model.generateContent([Content.text('say hi')]);
    print('gemini-1.5-flash-latest WORKS! Response: ${response.text}');
  } catch (e) {
    print('gemini-1.5-flash-latest failed: $e');
  }

  try {
    final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
    final response = await model.generateContent([Content.text('say hi')]);
    print('gemini-pro WORKS! Response: ${response.text}');
  } catch (e) {
    print('gemini-pro failed: $e');
  }

  try {
    final model = GenerativeModel(model: 'gemini-pro-vision', apiKey: apiKey);
    final response = await model.generateContent([Content.text('say hi')]);
    print('gemini-pro-vision WORKS! Response: ${response.text}');
  } catch (e) {
    print('gemini-pro-vision failed: $e');
  }
}
