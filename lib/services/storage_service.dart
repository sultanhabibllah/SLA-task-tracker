import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/member.dart';
import '../models/task.dart';

// Saves app data on the device with SharedPreferences.
// Members and tasks are each stored as one JSON list.
class StorageService {
  static const _membersKey = 'sprintly.members';
  static const _tasksKey = 'sprintly.tasks';
  static const _currentUserKey = 'sprintly.currentUserId';

  // Returns null when nothing has been saved yet, so the caller can start
  // from the starter data.
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

    final List list;
    try {
      list = jsonDecode(raw) as List;
    } catch (error) {
      debugPrint('Saved data could not be read: $error');
      return null;
    }

    // One damaged record is skipped instead of throwing away the whole list.
    final items = <T>[];
    for (final item in list) {
      try {
        items.add(fromJson(item as Map<String, dynamic>));
      } catch (error) {
        debugPrint('Skipped a saved record that could not be read: $error');
      }
    }
    return items;
  }
}
