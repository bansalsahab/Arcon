import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String apiBase = 'http://192.168.29.132:5000'; // Update if needed

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<String?> get accessToken async {
    final p = await _prefs();
    return p.getString('access_token');
  }

  static Future<Map<String, dynamic>> createMandate() async {
    final res = await http.post(
      Uri.parse('$apiBase/api/mandates'),
      headers: await _authHeaders(),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> executeSweep() async {
    final res = await http.post(
      Uri.parse('$apiBase/api/investments/execute'),
      headers: await _authHeaders(),
      body: jsonEncode({}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getSettings() async {
    final res = await http.get(
      Uri.parse('$apiBase/api/user/settings'),
      headers: await _authHeaders(),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateSettings({int? roundingBase, String? riskTier, String? sweepFrequency}) async {
    final body = <String, dynamic>{};
    if (roundingBase != null) body['rounding_base'] = roundingBase;
    if (riskTier != null) body['risk_tier'] = riskTier;
    if (sweepFrequency != null) body['sweep_frequency'] = sweepFrequency;
    final res = await http.patch(
      Uri.parse('$apiBase/api/user/settings'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<String?> get refreshToken async {
    final p = await _prefs();
    return p.getString('refresh_token');
  }

  static Future<void> saveTokens(String access, String? refresh) async {
    final p = await _prefs();
    await p.setString('access_token', access);
    if (refresh != null) {
      await p.setString('refresh_token', refresh);
    }
  }

  static Future<void> clearTokens() async {
    final p = await _prefs();
    await p.remove('access_token');
    await p.remove('refresh_token');
  }

  static Future<bool> isLoggedIn() async {
    final t = await accessToken;
    return t != null && t.isNotEmpty;
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await accessToken;
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response r) async {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(r.body);
    }
    // try parse error
    try {
      final m = jsonDecode(r.body);
      throw Exception(m['error'] ?? m['msg'] ?? 'HTTP ${r.statusCode}');
    } catch (_) {
      throw Exception('HTTP ${r.statusCode}: ${r.body}');
    }
  }

  static Future<void> _maybeRefreshAndRetry(Function requestFn) async {
    // naive refresh: try refresh endpoint once
    final rt = await refreshToken;
    if (rt == null) {
      throw Exception('Not authenticated');
    }
    final res = await http.post(
      Uri.parse('$apiBase/api/auth/refresh'),
      headers: {'Authorization': 'Bearer $rt'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final newAccess = data['access_token'] as String;
      await saveTokens(newAccess, rt);
      await requestFn();
      return;
    } else {
      await clearTokens();
      throw Exception('Session expired');
    }
  }

  // Public API methods
  static Future<void> register(String email, String password, {String? fullName}) async {
    final res = await http.post(
      Uri.parse('$apiBase/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'full_name': fullName}),
    );
    final data = await _handleResponse(res);
    await saveTokens(data['access_token'], data['refresh_token']);
  }

  static Future<void> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$apiBase/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = await _handleResponse(res);
    await saveTokens(data['access_token'], data['refresh_token']);
  }

  static Future<Map<String, dynamic>> me() async {
    Future<Map<String, dynamic>> doRequest() async {
      final res = await http.get(
        Uri.parse('$apiBase/api/auth/me'),
        headers: await _authHeaders(),
      );
      if (res.statusCode == 401 || res.statusCode == 422) {
        throw Exception('Auth');
      }
      return _handleResponse(res);
    }

    try {
      return await doRequest();
    } catch (e) {
      if (e.toString().contains('Auth')) {
        await _maybeRefreshAndRetry(() async => await doRequest());
        return await doRequest();
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> pendingRoundups() async {
    final res = await http.get(
      Uri.parse('$apiBase/api/roundups/pending'),
      headers: await _authHeaders(),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> portfolio() async {
    final res = await http.get(
      Uri.parse('$apiBase/api/portfolio'),
      headers: await _authHeaders(),
    );
    return _handleResponse(res);
  }

  static Future<List<dynamic>> transactions({int limit = 20, int offset = 0}) async {
    final uri = Uri.parse('$apiBase/api/transactions').replace(queryParameters: {
      'limit': '$limit',
      'offset': '$offset',
    });
    final res = await http.get(uri, headers: await _authHeaders());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    return _handleResponse(res) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> aiAdvice(String topic) async {
    final res = await http.post(
      Uri.parse('$apiBase/api/ai/advice'),
      headers: await _authHeaders(),
      body: jsonEncode({'topic': topic}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> createTransaction(double amount, {String? merchant}) async {
    final res = await http.post(
      Uri.parse('$apiBase/api/transactions'),
      headers: await _authHeaders(),
      body: jsonEncode({'amount': amount, 'merchant': merchant}),
    );
    return _handleResponse(res);
  }

  // Mandates list and management
  static Future<List<dynamic>> listMandates() async {
    final res = await http.get(
      Uri.parse('$apiBase/api/mandates'),
      headers: await _authHeaders(),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    return _handleResponse(res) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> pauseMandate(int id) async {
    final res = await http.post(
      Uri.parse('$apiBase/api/mandates/$id/pause'),
      headers: await _authHeaders(),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> resumeMandate(int id) async {
    final res = await http.post(
      Uri.parse('$apiBase/api/mandates/$id/resume'),
      headers: await _authHeaders(),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> cancelMandate(int id) async {
    final res = await http.post(
      Uri.parse('$apiBase/api/mandates/$id/cancel'),
      headers: await _authHeaders(),
    );
    return _handleResponse(res);
  }

  // KYC
  static Future<Map<String, dynamic>> kycGet() async {
    final res = await http.get(
      Uri.parse('$apiBase/api/kyc'),
      headers: await _authHeaders(),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> kycStart(String pan, String aadhaarLast4) async {
    final res = await http.post(
      Uri.parse('$apiBase/api/kyc/start'),
      headers: await _authHeaders(),
      body: jsonEncode({'pan': pan, 'aadhaar_last4': aadhaarLast4}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> kycVerify() async {
    final res = await http.post(
      Uri.parse('$apiBase/api/kyc/verify'),
      headers: await _authHeaders(),
    );
    return _handleResponse(res);
  }

  // Notifications
  static Future<List<dynamic>> listNotifications({int limit = 100}) async {
    final res = await http.get(
      Uri.parse('$apiBase/api/notifications'),
      headers: await _authHeaders(),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    return _handleResponse(res) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> schedulePreDebit() async {
    final res = await http.post(
      Uri.parse('$apiBase/api/notifications/pre-debit/schedule'),
      headers: await _authHeaders(),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> sendPreDebit() async {
    final res = await http.post(
      Uri.parse('$apiBase/api/notifications/pre-debit/send'),
      headers: await _authHeaders(),
    );
    return _handleResponse(res);
  }
}
