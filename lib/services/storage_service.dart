import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/member.dart';
import '../models/task.dart';

// Saves app data on the device with SharedPreferences.
// Members and tasks are each stored as one JSON list.
class StorageService {
  static const _membersKey = 'sprintly.members';
  static const _tasksKey = 'sprintly.tasks';
  static const _currentUserKey = 'sprintly.currentUserId';

  // Returns null when nothing has been saved yet or the saved data is unreadable,
  // so the caller can fall back to the starter data.
  Future<List<Member>?> loadMembers() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeList(prefs.getString(_membersKey), Member.fromJson);
  }

  Future<void> saveMembers(List<Member> members) async {
    final prefs = await SharedPreferences.getInstance();
    final json = members.map((member) => member.toJson()).toList();
    await prefs.setString(_membersKey, jsonEncode(json));
  }

  Future<List<Task>?> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeList(prefs.getString(_tasksKey), Task.fromJson);
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final json = tasks.map((task) => task.toJson()).toList();
    await prefs.setString(_tasksKey, jsonEncode(json));
  }

  Future<String?> loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  Future<void> saveCurrentUserId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_currentUserKey);
    } else {
      await prefs.setString(_currentUserKey, id);
    }
  }

  List<T>? _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null) return null;

    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
