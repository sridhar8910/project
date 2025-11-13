import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiClientException implements Exception {
  ApiClientException(this.message);

  final String message;

  @override
  String toString() => 'ApiClientException: $message';
}

enum WellnessTaskCategory { daily, evening }

extension WellnessTaskCategoryX on WellnessTaskCategory {
  String get apiValue => switch (this) {
        WellnessTaskCategory.daily => 'daily',
        WellnessTaskCategory.evening => 'evening',
      };

  String get displayLabel => switch (this) {
        WellnessTaskCategory.daily => 'Daily Tasks',
        WellnessTaskCategory.evening => 'Evening Reflection',
      };

  static WellnessTaskCategory fromApi(String value) {
    switch (value) {
      case 'evening':
        return WellnessTaskCategory.evening;
      case 'daily':
      default:
        return WellnessTaskCategory.daily;
    }
  }
}

class WellnessTaskItem {
  const WellnessTaskItem({
    required this.id,
    required this.title,
    required this.category,
    required this.isCompleted,
    required this.order,
  });

  factory WellnessTaskItem.fromJson(Map<String, dynamic> json) {
    return WellnessTaskItem(
      id: json['id'] as int,
      title: (json['title'] as String?)?.trim() ?? '',
      category: WellnessTaskCategoryX.fromApi(json['category'] as String? ?? 'daily'),
      isCompleted: json['is_completed'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
    );
  }

  final int id;
  final String title;
  final WellnessTaskCategory category;
  final bool isCompleted;
  final int order;

  WellnessTaskItem copyWith({
    String? title,
    WellnessTaskCategory? category,
    bool? isCompleted,
    int? order,
  }) {
    return WellnessTaskItem(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
    );
  }
}

class WellnessTaskSummary {
  const WellnessTaskSummary({
    required this.total,
    required this.completed,
  });

  final int total;
  final int completed;

  double get completionRatio => total == 0 ? 0 : completed / total;
}

class WellnessTasksResponse {
  const WellnessTasksResponse({
    required this.daily,
    required this.evening,
    required this.summary,
  });

  final List<WellnessTaskItem> daily;
  final List<WellnessTaskItem> evening;
  final WellnessTaskSummary summary;
}

class WellnessJournalEntry {
  WellnessJournalEntry({
    required this.id,
    required this.title,
    required this.note,
    required this.mood,
    required this.entryType,
    required this.formattedDate,
    this.createdAt,
  });

  factory WellnessJournalEntry.fromJson(Map<String, dynamic> json) {
    return WellnessJournalEntry(
      id: json['id'] as int,
      title: (json['title'] as String?)?.trim() ?? '',
      note: (json['note'] as String?)?.trim() ?? '',
      mood: (json['mood'] as String?)?.trim() ?? '',
      entryType: (json['entry_type'] as String?)?.trim() ?? '',
      formattedDate: (json['formatted_date'] as String?)?.trim() ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  final int id;
  final String title;
  final String note;
  final String mood;
  final String entryType;
  final String formattedDate;
  final DateTime? createdAt;

  WellnessJournalEntry copyWith({
    String? title,
    String? note,
    String? mood,
    String? entryType,
    String? formattedDate,
    DateTime? createdAt,
  }) {
    return WellnessJournalEntry(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      mood: mood ?? this.mood,
      entryType: entryType ?? this.entryType,
      formattedDate: formattedDate ?? this.formattedDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ApiClient {
  static const String _defaultBase = 'http://127.0.0.1:8000/api';
  static const String base =
      String.fromEnvironment('BACKEND_BASE_URL', defaultValue: _defaultBase);

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> _saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access', value: access);
    await _storage.write(key: 'refresh', value: refresh);
  }

  Future<String?> get _accessToken async => _storage.read(key: 'access');

  Future<String?> get _refreshToken async => _storage.read(key: 'refresh');

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<(bool, String?)> register({
    required String username,
    String? email,
    required String password,
    String? fullName,
    String? phone,
    int? age,
    String? gender,
  }) async {
    final payload = <String, dynamic>{
      'username': username,
      'password': password,
    };

    void addIfPresent(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      payload[key] = value;
    }

    addIfPresent('email', email);
    addIfPresent('full_name', fullName);
    addIfPresent('phone', phone);
    if (age != null) {
      payload['age'] = age;
    }
    addIfPresent('gender', gender);

    final response = await http.post(
      Uri.parse('$base/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    return (response.statusCode == 201, response.body);
  }

  Future<(bool, String?)> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$base/auth/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      await _saveTokens(decoded['access'] as String, decoded['refresh'] as String);
      return (true, null);
    }

    return (false, response.body);
  }

  Future<bool> _refreshTokenIfNeeded() async {
    final refresh = await _refreshToken;
    if (refresh == null) {
      return false;
    }

    final response = await http.post(
      Uri.parse('$base/auth/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['access'] != null) {
        await _storage.write(key: 'access', value: decoded['access'] as String);
        return true;
      }
    }

    return false;
  }

  Map<String, String> _headers(String? access, [Map<String, String>? overrides]) {
    return {
      'Accept': 'application/json',
      if (access != null) 'Authorization': 'Bearer $access',
      if (overrides != null) ...overrides,
    };
  }

  Future<http.Response> _sendAuthorized(
    Future<http.Response> Function(String? accessToken) makeRequest,
  ) async {
    Future<http.Response> attempt() async {
      final access = await _accessToken;
      return makeRequest(access);
    }

    var response = await attempt();
    if (response.statusCode == 401 && await _refreshTokenIfNeeded()) {
      response = await attempt();
    }
    return response;
  }

  String _extractErrorMessage(http.Response response) {
    if (response.body.isEmpty) {
      return 'Request failed with status ${response.statusCode}';
    }
    try {
      final Object? decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          return detail;
        }
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
        if (decoded.values.isNotEmpty) {
          final dynamic firstValue = decoded.values.first;
          if (firstValue is List && firstValue.isNotEmpty) {
            final first = firstValue.first;
            if (first is String) {
              return first;
            }
          } else if (firstValue is String) {
            return firstValue;
          }
        }
      } else if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.first;
        if (first is String) {
          return first;
        }
      }
    } catch (_) {
      // ignore decode errors and fall through to raw body
    }
    return response.body;
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/profile/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<WellnessTasksResponse> fetchWellnessTasks() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/wellness/tasks/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final tasksJson = (decoded['tasks'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      final tasks =
          tasksJson.map(WellnessTaskItem.fromJson).toList(growable: false);

      final summaryJson = decoded['summary'] as Map<String, dynamic>? ?? {};
      final summary = WellnessTaskSummary(
        total: summaryJson['total'] as int? ?? tasks.length,
        completed:
            summaryJson['completed'] as int? ?? tasks.where((t) => t.isCompleted).length,
      );

      final daily =
          tasks.where((task) => task.category == WellnessTaskCategory.daily).toList();
      final evening =
          tasks.where((task) => task.category == WellnessTaskCategory.evening).toList();

      return WellnessTasksResponse(
        daily: daily,
        evening: evening,
        summary: summary,
      );
    }

    if (response.statusCode == 401) {
      throw ApiClientException('You need to log in to view your wellness plan.');
    }

    throw ApiClientException(
      'Unable to fetch wellness tasks: ${_extractErrorMessage(response)}',
    );
  }

  Future<WellnessTaskItem> toggleWellnessTaskCompletion(
    int taskId,
    bool isCompleted,
  ) async {
    final response = await _sendAuthorized(
      (access) => http.patch(
        Uri.parse('$base/wellness/tasks/$taskId/'),
        headers: _headers(access, {'Content-Type': 'application/json'}),
        body: jsonEncode({'is_completed': isCompleted}),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return WellnessTaskItem.fromJson(decoded);
    }

    if (response.statusCode == 404) {
      throw ApiClientException('Task not found');
    }

    throw ApiClientException(
      'Unable to update task: ${_extractErrorMessage(response)}',
    );
  }

  Future<WellnessTaskItem> createWellnessTask({
    required String title,
    required WellnessTaskCategory category,
  }) async {
    final response = await _sendAuthorized(
      (access) => http.post(
        Uri.parse('$base/wellness/tasks/'),
        headers: _headers(access, {'Content-Type': 'application/json'}),
        body: jsonEncode({
          'title': title,
          'category': category.apiValue,
        }),
      ),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return WellnessTaskItem.fromJson(decoded);
    }

    throw ApiClientException(
      'Unable to add task: ${_extractErrorMessage(response)}',
    );
  }

  Future<void> deleteWellnessTask(int taskId) async {
    final response = await _sendAuthorized(
      (access) => http.delete(
        Uri.parse('$base/wellness/tasks/$taskId/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 204) {
      return;
    }

    if (response.statusCode == 404) {
      throw ApiClientException('Task already removed');
    }

    throw ApiClientException(
      'Unable to delete task: ${_extractErrorMessage(response)}',
    );
  }

  Future<List<WellnessJournalEntry>> fetchWellnessJournalEntries() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/wellness/journals/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final entriesJson = (decoded['entries'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      return entriesJson.map(WellnessJournalEntry.fromJson).toList();
    }

    if (response.statusCode == 401) {
      throw ApiClientException('You need to log in to view journal entries.');
    }

    throw ApiClientException(
      'Unable to fetch journal entries: ${_extractErrorMessage(response)}',
    );
  }

  Future<WellnessJournalEntry> createWellnessJournalEntry({
    required String title,
    required String note,
    required String mood,
    required String entryType,
  }) async {
    final response = await _sendAuthorized(
      (access) => http.post(
        Uri.parse('$base/wellness/journals/'),
        headers: _headers(access, {'Content-Type': 'application/json'}),
        body: jsonEncode({
          'title': title,
          'note': note,
          'mood': mood,
          'entry_type': entryType,
        }),
      ),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return WellnessJournalEntry.fromJson(decoded);
    }

    throw ApiClientException(
      'Unable to save journal entry: ${_extractErrorMessage(response)}',
    );
  }

  Future<void> deleteWellnessJournalEntry(int entryId) async {
    final response = await _sendAuthorized(
      (access) => http.delete(
        Uri.parse('$base/wellness/journals/$entryId/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 204) {
      return;
    }

    if (response.statusCode == 404) {
      throw ApiClientException('Entry already removed');
    }

    throw ApiClientException(
      'Unable to delete journal entry: ${_extractErrorMessage(response)}',
    );
  }
}

