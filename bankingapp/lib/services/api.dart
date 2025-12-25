import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String apiBase = 'http://192.168.29.132:5000';

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<String?> get accessToken async {
    final p = await _prefs();
    return p.getString('access_token');
  }

  static Future<String?> get refreshToken async {
    final p = await _prefs();
    return p.getString('refresh_token');
  }

  static Future<void> saveTokens(String access, String? refresh) async {
    final p = await _prefs();
    await p.setString('access_token', access);
    if (refresh != null) await p.setString('refresh_token', refresh);
  }

  static Future<void> clearTokens() async {
    final p = await _prefs();
    await p.remove('access_token');
    await p.remove('refresh_token');
  }

  static Future<bool> isLoggedIn() async => (await accessToken) != null;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await accessToken;
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  static Map<String, dynamic> _parse(http.Response r) {
    final code = r.statusCode;
    if (code >= 200 && code < 300) {
      if (r.body.isEmpty) return {};
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    try {
      final m = jsonDecode(r.body);
      throw Exception(m['error'] ?? m['msg'] ?? 'HTTP $code');
    } catch (_) {
      throw Exception('HTTP $code: ${r.body}');
    }
  }

  static Future<void> _refreshOnce() async {
    final rt = await refreshToken;
    if (rt == null) throw Exception('Not authenticated');
    final res = await http.post(
      Uri.parse('$apiBase/api/auth/refresh'),
      headers: {'Authorization': 'Bearer $rt'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await saveTokens(data['access_token'] as String, rt);
    } else {
      await clearTokens();
      throw Exception('Session expired');
    }
  }

  static Future<T> _withAuthRetry<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      final s = e.toString();
      if (s.contains('401') || s.contains('expired') || s.contains('Auth')) {
        await _refreshOnce();
        return await fn();
      }
      rethrow;
    }
  }

  // Auth
  static Future<void> register(String email, String password, {String fullName = ''}) async {
    final r = await http.post(
      Uri.parse('$apiBase/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'full_name': fullName}),
    );
    final data = _parse(r);
    await saveTokens(data['access_token'] as String, data['refresh_token'] as String?);
  }

  static Future<void> login(String email, String password) async {
    final r = await http.post(
      Uri.parse('$apiBase/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _parse(r);
    await saveTokens(data['access_token'] as String, data['refresh_token'] as String?);
  }

  static Future<Map<String, dynamic>> me() async {
    return _withAuthRetry(() async {
      final r = await http.get(Uri.parse('$apiBase/api/auth/me'), headers: await _authHeaders());
      return _parse(r);
    });
  }

  // Domain
  static Future<Map<String, dynamic>> portfolio() async {
    return _withAuthRetry(() async {
      final r = await http.get(Uri.parse('$apiBase/api/portfolio'), headers: await _authHeaders());
      return _parse(r);
    });
  }

  static Future<Map<String, dynamic>> pendingRoundups() async {
    return _withAuthRetry(() async {
      final r = await http.get(Uri.parse('$apiBase/api/roundups/pending'), headers: await _authHeaders());
      return _parse(r);
    });
  }

  static Future<List<dynamic>> transactions({int limit = 20, int offset = 0}) async {
    return _withAuthRetry(() async {
      final uri = Uri.parse('$apiBase/api/transactions').replace(queryParameters: {
        'limit': '$limit', 'offset': '$offset'
      });
      final r = await http.get(uri, headers: await _authHeaders());
      if (r.statusCode >= 200 && r.statusCode < 300) return jsonDecode(r.body) as List<dynamic>;
      throw Exception('HTTP ${r.statusCode}');
    });
  }

  static Future<Map<String, dynamic>> createTransaction(double amount, {String? merchant}) async {
    return _withAuthRetry(() async {
      final r = await http.post(
        Uri.parse('$apiBase/api/transactions'),
        headers: await _authHeaders(),
        body: jsonEncode({'amount': amount, 'merchant': merchant}),
      );
      return _parse(r);
    });
  }

  static Future<Map<String, dynamic>> createMandate() async {
    return _withAuthRetry(() async {
      final r = await http.post(Uri.parse('$apiBase/api/mandates'), headers: await _authHeaders());
      return _parse(r);
    });
  }

  static Future<Map<String, dynamic>> executeSweep() async {
    return _withAuthRetry(() async {
      final r = await http.post(Uri.parse('$apiBase/api/investments/execute'), headers: await _authHeaders(), body: jsonEncode({}));
      return _parse(r);
    });
  }

  static Future<Map<String, dynamic>> aiAdvice(String topic) async {
    return _withAuthRetry(() async {
      final r = await http.post(Uri.parse('$apiBase/api/ai/advice'), headers: await _authHeaders(), body: jsonEncode({'topic': topic}));
      return _parse(r);
    });
  }

  // Settings
  static Future<Map<String, dynamic>> getSettings() async {
    return _withAuthRetry(() async {
      final r = await http.get(Uri.parse('$apiBase/api/user/settings'), headers: await _authHeaders());
      return _parse(r);
    });
  }

  static Future<Map<String, dynamic>> updateSettings({int? roundingBase, String? riskTier, String? sweepFrequency}) async {
    final body = <String, dynamic>{};
    if (roundingBase != null) body['rounding_base'] = roundingBase;
    if (riskTier != null) body['risk_tier'] = riskTier;
    if (sweepFrequency != null) body['sweep_frequency'] = sweepFrequency;
    return _withAuthRetry(() async {
      final r = await http.patch(Uri.parse('$apiBase/api/user/settings'), headers: await _authHeaders(), body: jsonEncode(body));
      return _parse(r);
    });
  }

  // Mandates
  static Future<List<dynamic>> listMandates() async {
    return _withAuthRetry(() async {
      final r = await http.get(Uri.parse('$apiBase/api/mandates'), headers: await _authHeaders());
      if (r.statusCode >= 200 && r.statusCode < 300) return jsonDecode(r.body) as List<dynamic>;
      throw Exception('HTTP ${r.statusCode}');
    });
  }

  static Future<Map<String, dynamic>> pauseMandate(int id) async {
    return _withAuthRetry(() async {
      final r = await http.post(Uri.parse('$apiBase/api/mandates/$id/pause'), headers: await _authHeaders());
      return _parse(r);
    });
  }

  static Future<Map<String, dynamic>> resumeMandate(int id) async {
    return _withAuthRetry(() async {
      final r = await http.post(Uri.parse('$apiBase/api/mandates/$id/resume'), headers: await _authHeaders());
      return _parse(r);
    });
  }

  static Future<Map<String, dynamic>> cancelMandate(int id) async {
    return _withAuthRetry(() async {
      final r = await http.post(Uri.parse('$apiBase/api/mandates/$id/cancel'), headers: await _authHeaders());
      return _parse(r);
    });
  }

  // KYC
  static Future<Map<String, dynamic>> kycGet() async {
    return _withAuthRetry(() async {
      final r = await http.get(Uri.parse('$apiBase/api/kyc'), headers: await _authHeaders());
      return _parse(r);
    });
  }

  static Future<Map<String, dynamic>> kycStart(String pan, String aadhaarLast4) async {
    return _withAuthRetry(() async {
      final r = await http.post(
        Uri.parse('$apiBase/api/kyc/start'),
        headers: await _authHeaders(),
        body: jsonEncode({'pan': pan, 'aadhaar_last4': aadhaarLast4}),
      );
      return _parse(r);
    });
  }

  static Future<Map<String, dynamic>> kycVerify() async {
    return _withAuthRetry(() async {
      final r = await http.post(Uri.parse('$apiBase/api/kyc/verify'), headers: await _authHeaders());
      return _parse(r);
    });
  }
}
