import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'AIzaSyDByuv-Y2vznv4JVg9IAcnpwU4sGXCfsT8';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  final response = await http.get(url);
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    for (var model in data['models']) {
      print('- ${model['name']}');
    }
  } else {
    print('Failed: ${response.body}');
  }
}
