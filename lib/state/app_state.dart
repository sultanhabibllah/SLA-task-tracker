import 'package:flutter/foundation.dart';
import '../core/sla/sla_status.dart';
import '../data/seed_data.dart';
import '../models/member.dart';
import '../models/task.dart';
import '../services/storage_service.dart';

// Single source of truth for the app. Screens read from it with Provider and
// call its methods to change data. Each change updates the screens straight
// away and is then saved to the device.
class AppState extends ChangeNotifier {
  AppState(this._storage);

  final StorageService _storage;

  List<Member> _members = [];
  List<Task> _tasks = [];
  String? _currentUserId;

  List<Member> get members => List.unmodifiable(_members);
  List<Task> get tasks => List.unmodifiable(_tasks);

  Member? get currentUser {
    final id = _currentUserId;
    return id == null ? null : memberById(id);
  }

  // Reads saved data. On first launch the starter data is used and saved, so
  // its due dates stay fixed from then on.
  Future<void> load() async {
    final savedMembers = await _storage.loadMembers();
    final savedTasks = await _storage.loadTasks();

    _members = savedMembers ?? seedMembers();
    _tasks = savedTasks ?? seedTasks();

    if (savedMembers == null) await _storage.saveMembers(_members);
    if (savedTasks == null) await _storage.saveTasks(_tasks);

    _currentUserId = await _storage.loadCurrentUserId();
    notifyListeners();
  }

  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  // Lookups

  Member? memberById(String id) {
    for (final member in _members) {
      if (member.id == id) return member;
    }
    return null;
  }

  Task? taskById(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  List<Task> tasksFor(String memberId) {
    return _tasks.where((task) => task.assigneeId == memberId).toList();
  }

  // SLA and progress

  SlaStatus slaOf(Task task, {DateTime? now}) => classifySla(task, now: now);

  // Counts tasks per SLA status. Uses every task unless a subset is given.
  Map<SlaStatus, int> slaCounts({Iterable<Task>? subset, DateTime? now}) {
    final counts = {for (final status in SlaStatus.values) status: 0};
    for (final task in subset ?? _tasks) {
      final status = slaOf(task, now: now);
      counts[status] = counts[status]! + 1;
    }
    return counts;
  }

  // Share of tasks that are done, from 0.0 to 1.0.
  double get progress {
    if (_tasks.isEmpty) return 0;
    return _tasks.where((task) => task.isDone).length / _tasks.length;
  }

  // Session

  Future<void> signIn(String memberId) async {
    if (memberById(memberId) == null) return;

    _currentUserId = memberId;
    notifyListeners();
    await _storage.saveCurrentUserId(memberId);
  }

  Future<void> signOut() async {
    _currentUserId = null;
    notifyListeners();
    await _storage.saveCurrentUserId(null);
  }

  // Tasks

  Future<void> addTask(Task task) async {
    _tasks = [..._tasks, task];
    await _saveTasks();
  }

  Future<void> updateTask(Task updated) async {
    _tasks = [
      for (final task in _tasks)
        if (task.id == updated.id) updated else task,
    ];
    await _saveTasks();
  }

  Future<void> deleteTask(String id) async {
    _tasks = _tasks.where((task) => task.id != id).toList();
    await _saveTasks();
  }

  // Members

  Future<void> addMember(Member member) async {
    _members = [..._members, member];
    await _saveMembers();
  }

  Future<void> updateMember(Member updated) async {
    _members = [
      for (final member in _members)
        if (member.id == updated.id) updated else member,
    ];
    await _saveMembers();
  }

  // A member can only be removed when they are not signed in and have no
  // tasks, so no task is ever left pointing at a missing assignee.
  bool canRemoveMember(String id) {
    return id != _currentUserId && tasksFor(id).isEmpty;
  }

  Future<bool> removeMember(String id) async {
    if (!canRemoveMember(id)) return false;
    _members = _members.where((member) => member.id != id).toList();
    await _saveMembers();
    return true;
  }

  Future<void> _saveTasks() async {
    notifyListeners();
    await _storage.saveTasks(_tasks);
  }

  Future<void> _saveMembers() async {
    notifyListeners();
    await _storage.saveMembers(_members);
  }
}
