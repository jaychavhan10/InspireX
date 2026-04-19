import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MLService {
  // For physical device: 192.168.29.56 | For Android emulator: 10.0.2.2
  static const String _baseUrl = 'http://192.168.29.56:5000';

  Future<Map<String, dynamic>?> processIdea(String text) async {
    try {
      debugPrint('🔵 MLService: Sending request to $_baseUrl/process');
      debugPrint('📝 Text length: ${text.length} characters');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/process'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(seconds: 60));

      debugPrint('✅ MLService: Response status: ${response.statusCode}');
      debugPrint('📋 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✓ ML processing successful');
        return result;
      } else {
        debugPrint('❌ MLService: Error ${response.statusCode}');
        debugPrint('Error body: ${response.body}');
        return null;
      }
    } on TimeoutException {
      debugPrint('❌ MLService Timeout: Backend not responding within 60 seconds');
      debugPrint('⚠️ Ensure backend is running: python backend/app.py');
      debugPrint('⚠️ Backend should be at $_baseUrl');
      debugPrint('⚠️ First request takes longer due to model loading');
    } catch (e) {
      debugPrint('❌ MLService Error: $e');
      debugPrint('⚠️ Check if backend is running and accessible at $_baseUrl');
      debugPrint('⚠️ Make sure mobile and laptop are on same WiFi network');
    }
    return null;
  }
}
