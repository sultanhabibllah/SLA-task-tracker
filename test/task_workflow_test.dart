import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sprintly/models/task.dart';
import 'package:sprintly/services/storage_service.dart';
import 'package:sprintly/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppState appState;

  setUp(() async {
    // Start each test with fresh local storage.
    SharedPreferences.setMockInitialValues({});

    appState = AppState(StorageService());
    await appState.load();
  });

  Task makeTask({
    String? id,
    String title = 'Test Sprintly Integration',
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.high,
    TaskStatus status = TaskStatus.todo,
  }) {
    return Task(
      id: id ?? appState.newId(),
      title: title,
      description: 'Automated task workflow test',
      assigneeId: appState.members.first.id,
      dueDate: dueDate ?? DateTime.now().add(const Duration(days: 5)),
      priority: priority,
      status: status,
      project: 'Mobile App',
      createdAt: DateTime.now(),
    );
  }

  group('Task creation', () {
    test('Creates a task successfully', () async {
      final initialCount = appState.tasks.length;
      final task = makeTask();

      await appState.addTask(task);

      expect(appState.tasks.length, initialCount + 1);
      expect(appState.taskById(task.id), isNotNull);
      expect(appState.taskById(task.id)?.title, task.title);
    });

    test('Preserves task details', () async {
      final task = makeTask(
        title: 'Build Login Screen',
        priority: TaskPriority.high,
      );

      await appState.addTask(task);

      final savedTask = appState.taskById(task.id);

      expect(savedTask, isNotNull);
      expect(savedTask!.title, 'Build Login Screen');
      expect(savedTask.priority, TaskPriority.high);
      expect(savedTask.status, TaskStatus.todo);
      expect(savedTask.project, 'Mobile App');
      expect(savedTask.assigneeId, appState.members.first.id);
    });

    test('Notifies listeners when a task is added', () async {
      var notificationCount = 0;

      void listener() {
        notificationCount++;
      }

      appState.addListener(listener);

      await appState.addTask(makeTask());

      expect(notificationCount, greaterThan(0));

      appState.removeListener(listener);
    });
  });

  group('SLA classification', () {
    test('Future tasks are On Track', () {
      final task = makeTask(
        dueDate: DateTime.now().add(const Duration(days: 5)),
      );

      expect(appState.slaOf(task).name, 'onTrack');
    });

    test('Tasks approaching their deadline are At Risk', () {
      final task = makeTask(
        dueDate: DateTime.now().add(const Duration(hours: 12)),
      );

      expect(appState.slaOf(task).name, 'atRisk');
    });

    test('Tasks past their deadline are Overdue', () {
      final task = makeTask(
        dueDate: DateTime.now().subtract(const Duration(days: 3)),
      );

      expect(appState.slaOf(task).name, 'overdue');
    });

    test('Completed tasks remain Completed', () {
      final task = makeTask(
        status: TaskStatus.done,
        dueDate: DateTime.now().subtract(const Duration(days: 5)),
      );

      expect(appState.slaOf(task).name, 'completed');
    });
  });

  group('Task management', () {
    test('Updates an existing task', () async {
      final task = makeTask();

      await appState.addTask(task);

      final updated = task.copyWith(
        title: 'Updated Task Title',
        status: TaskStatus.inProgress,
      );

      await appState.updateTask(updated);

      final savedTask = appState.taskById(task.id);

      expect(savedTask?.title, 'Updated Task Title');
      expect(savedTask?.status, TaskStatus.inProgress);
    });

    test('Deletes a task', () async {
      final task = makeTask();

      await appState.addTask(task);

      expect(appState.taskById(task.id), isNotNull);

      await appState.deleteTask(task.id);

      expect(appState.taskById(task.id), isNull);
    });
  });

  group('Local persistence', () {
    test('Tasks survive reloading application state', () async {
      final task = makeTask(title: 'Persistent Test Task');

      await appState.addTask(task);

      // Simulate restarting the application state.
      final restartedState = AppState(StorageService());
      await restartedState.load();

      final restoredTask = restartedState.taskById(task.id);

      expect(restoredTask, isNotNull);
      expect(restoredTask!.title, 'Persistent Test Task');
      expect(restoredTask.priority, TaskPriority.high);
      expect(restoredTask.project, 'Mobile App');
      expect(restoredTask.assigneeId, appState.members.first.id);
    });

    test('Task updates persist after reload', () async {
      final task = makeTask();

      await appState.addTask(task);

      await appState.updateTask(task.copyWith(status: TaskStatus.done));

      final restartedState = AppState(StorageService());
      await restartedState.load();

      expect(restartedState.taskById(task.id)?.status, TaskStatus.done);
    });

    test('Deleted tasks remain deleted after reload', () async {
      final task = makeTask();

      await appState.addTask(task);
      await appState.deleteTask(task.id);

      final restartedState = AppState(StorageService());
      await restartedState.load();

      expect(restartedState.taskById(task.id), isNull);
    });
  });
}
