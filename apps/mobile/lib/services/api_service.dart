import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  // Override at build time: --dart-define=API_URL=http://192.168.x.x:8000
  // Default 10.0.2.2 works for the Android emulator only.
  static const _defaultUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');

  final String baseUrl;

  ApiService({this.baseUrl = _defaultUrl});

  /// Returns auth headers for the current Supabase session.
  Map<String, String> get _authHeaders {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) return {};
    return {'Authorization': 'Bearer $token'};
  }

  /// Upload the processed (cropped/transformed) image for AI extraction.
  Future<Map<String, dynamic>> uploadScan({
    required File processedFile,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/scan'),
    );

    request.headers.addAll(_authHeaders);
    request.files.add(
      await http.MultipartFile.fromPath('file', processedFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<dynamic>> fetchScans({int offset = 0, int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/scans?offset=$offset&limit=$limit'),
      headers: _authHeaders,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to fetch scans: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchScan(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/scan/$id'),
      headers: _authHeaders,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch scan: ${response.statusCode}');
    }
  }

  Future<void> verifyScan(String id, Map<String, dynamic> verifiedData) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/scan/$id'),
      headers: {..._authHeaders, 'Content-Type': 'application/json'},
      body: jsonEncode({'verified_data': verifiedData, 'status': 'verified'}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to verify scan: ${response.statusCode}');
    }
  }

  Future<void> rejectScan(String id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/scan/$id'),
      headers: {..._authHeaders, 'Content-Type': 'application/json'},
      body: jsonEncode({'status': 'failed'}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reject scan: ${response.statusCode}');
    }
  }

  Future<void> signOut() => Supabase.instance.client.auth.signOut();
}
