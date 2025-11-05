import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://dummyjson.com';

  void _logRequest(String method, String endpoint, {String? body}) {
    debugPrint('═══════════════════════════════════════');
    debugPrint('API REQUEST');
    debugPrint('═══════════════════════════════════════');
    debugPrint('Method: $method');
    debugPrint('URL: $_baseUrl$endpoint');
    if (body != null) {
      debugPrint('Body: $body');
    }
    debugPrint('═══════════════════════════════════════\n');
  }

  void _logResponse(
    String endpoint,
    int statusCode,
    String body,
  ) {
    debugPrint('═══════════════════════════════════════');
    debugPrint('API RESPONSE');
    debugPrint('═══════════════════════════════════════');
    debugPrint('Endpoint: $endpoint');
    debugPrint('Status Code: $statusCode');
    debugPrint('Response Body:');
    try {
      final jsonResponse = json.decode(body);
      debugPrint(json.encode(jsonResponse));
    } catch (e) {
      debugPrint(body);
    }
    debugPrint('═══════════════════════════════════════\n');
  }

  /// NOTE - Auth API
  Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    const endpoint = '/auth/login';
    final requestBody = json.encode({
      'username': username,
      'password': password,
      'expiresInMins': 30,
    });

    _logRequest('POST', endpoint, body: requestBody);

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      _logResponse(endpoint, res.statusCode, res.body);

      if (res.statusCode == 200) {
        return json.decode(res.body);
      } else {
        final errorData = json.decode(res.body);
        throw Exception(errorData['message'] ?? 'Login gagal');
      }
    } catch (e) {
      debugPrint('ERROR $endpoint: $e\n');
      rethrow;
    }
  }

  /// SECTION - Posts API

  // NOTE - Get All Posts
  Future<List<dynamic>> getPosts() async {
    const endpoint = '/posts';
    _logRequest('GET', endpoint);

    try {
      final res = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
      );

      _logResponse(endpoint, res.statusCode, res.body);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data['posts'];
      } else {
        throw Exception('Gagal mengambil data posts');
      }
    } catch (e) {
      debugPrint('ERROR $endpoint: $e\n');
      rethrow;
    }
  }

  // NOTE - Add Post
  Future<Map<String, dynamic>> addPost(String title, String body) async {
    const endpoint = '/posts/add';
    final requestBody = json.encode({
      'title': title,
      'body': body,
      'userId': 5,
    });

    _logRequest('POST', endpoint, body: requestBody);

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      _logResponse(endpoint, res.statusCode, res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return json.decode(res.body);
      } else {
        throw Exception('Gagal menambahkan post');
      }
    } catch (e) {
      debugPrint('ERROR $endpoint: $e\n');
      rethrow;
    }
  }

  // NOTE - Update Post
  Future<Map<String, dynamic>> updatePost(
    int id,
    String title,
    String body,
  ) async {
    final endpoint = '/posts/$id';
    final requestBody = json.encode({
      'title': title,
      'body': body,
    });

    _logRequest('PUT', endpoint, body: requestBody);

    try {
      final res = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      _logResponse(endpoint, res.statusCode, res.body);

      if (res.statusCode == 200) {
        return json.decode(res.body);
      } else {
        throw Exception('Gagal mengupdate post');
      }
    } catch (e) {
      debugPrint('ERROR $endpoint: $e\n');
      rethrow;
    }
  }

  // NOTE - Delete Post
  Future<bool> deletePost(int id) async {
    final endpoint = '/posts/$id';
    _logRequest('DELETE', endpoint);

    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl$endpoint'),
      );

      _logResponse(endpoint, res.statusCode, res.body);

      if (res.statusCode == 200) {
        return true;
      } else {
        throw Exception('Gagal menghapus post');
      }
    } catch (e) {
      debugPrint('ERROR $endpoint: $e\n');
      rethrow;
    }
  }
}
