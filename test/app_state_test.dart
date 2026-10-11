import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintly/core/sla/sla_status.dart';
import 'package:sprintly/models/member.dart';
import 'package:sprintly/models/task.dart';
import 'package:sprintly/services/storage_service.dart';
import 'package:sprintly/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AppState> loadState() async {
    final state = AppState(StorageService());
    await state.load();
    return state;
  }

  Task newTask(String id) {
    return Task(
      id: id,
      title: 'Write tests',
      description: 'Cover the app state',
      assigneeId: 'm1',
      dueDate: DateTime(2026, 10, 20),
      priority: TaskPriority.high,
      status: TaskStatus.inProgress,
      project: 'Mobile App',
      tags: const ['QA'],
      createdAt: DateTime(2026, 10, 10),
    );
  }

  test('first launch starts with the starter data and nobody signed in', () async {
    final state = await loadState();

    expect(state.members, isNotEmpty);
    expect(state.tasks, isNotEmpty);
    expect(state.currentUser, isNull);
  });

  test('models survive a JSON round trip', () {
    final task = newTask('t-json');
    final member = Member(
      id: 'm-json',
      name: 'Sam Doe',
      jobTitle: 'Developer',
      email: 'sam@sprintly.app',
      team: 'Engineering',
      role: MemberRole.admin,
      presence: MemberPresence.away,
      joinedAt: DateTime(2026, 1, 1),
    );

    final loadedTask = Task.fromJson(task.toJson());
    final loadedMember = Member.fromJson(member.toJson());

    expect(loadedTask.title, 'Write tests');
    expect(loadedTask.assigneeId, 'm1');
    expect(loadedTask.dueDate, DateTime(2026, 10, 20));
    expect(loadedTask.priority, TaskPriority.high);
    expect(loadedTask.status, TaskStatus.inProgress);
    expect(loadedTask.project, 'Mobile App');
    expect(loadedTask.tags, ['QA']);
    expect(loadedMember.name, 'Sam Doe');
    expect(loadedMember.role, MemberRole.admin);
    expect(loadedMember.presence, MemberPresence.away);
    expect(loadedMember.joinedAt, DateTime(2026, 1, 1));
    expect(member.initials, 'SD');
  });

  test('task changes are still there after the app restarts', () async {
    final state = await loadState();
    await state.addTask(newTask('t-new'));
    await state.updateTask(
      state.taskById('t-new')!.copyWith(status: TaskStatus.done),
    );
    await state.deleteTask('t1');

    final restarted = await loadState();

    expect(restarted.taskById('t-new')!.status, TaskStatus.done);
    expect(restarted.taskById('t1'), isNull);
  });

  test('the signed-in member is remembered until sign out', () async {
    final state = await loadState();
    await state.signIn('m2');

    expect((await loadState()).currentUser!.id, 'm2');

    await state.signOut();

    expect((await loadState()).currentUser, isNull);
  });

  test('a member with tasks or the signed-in member cannot be removed', () async {
    final state = await loadState();
    await state.addMember(
      Member(
        id: 'm-free',
        name: 'New Person',
        jobTitle: 'Intern',
        email: 'new@sprintly.app',
        team: 'Engineering',
        joinedAt: DateTime(2026, 10, 10),
      ),
    );
    await state.signIn('m-free');

    expect(await state.removeMember('m1'), isFalse);
    expect(await state.removeMember('m-free'), isFalse);

    await state.signIn('m1');

    expect(await state.removeMember('m-free'), isTrue);
    expect(state.memberById('m-free'), isNull);
  });

  test('progress and SLA counts follow the task list', () async {
    final state = await loadState();

    // Starter data: 6 tasks, 1 done, 1 overdue, 1 due tomorrow,
    // 1 high priority due in 2 days and 2 due later.
    expect(state.progress, 1 / 6);
    expect(state.slaCounts(), {
      SlaStatus.completed: 1,
      SlaStatus.overdue: 1,
      SlaStatus.atRisk: 2,
      SlaStatus.onTrack: 2,
    });

    final tomorrowTask = state.taskById('t1')!;
    await state.updateTask(tomorrowTask.copyWith(status: TaskStatus.done));

    expect(state.progress, 2 / 6);
    expect(state.slaCounts()[SlaStatus.completed], 2);
    expect(state.slaCounts()[SlaStatus.atRisk], 1);
    expect(state.slaCounts(subset: state.tasksFor('m2')), {
      SlaStatus.completed: 1,
      SlaStatus.overdue: 0,
      SlaStatus.atRisk: 0,
      SlaStatus.onTrack: 0,
    });
  });

  test('starter due dates stay fixed once the app has been opened', () async {
    final first = await loadState();
    final dueDates = [for (final task in first.tasks) task.dueDate];

    final restarted = await loadState();

    expect([for (final task in restarted.tasks) task.dueDate], dueDates);
    expect(
      (await SharedPreferences.getInstance()).getString('sprintly.tasks'),
      isNotNull,
    );
  });

  test('signing in as an unknown member does nothing', () async {
    final state = await loadState();
    await state.signIn('nobody');

    expect(state.currentUser, isNull);
    expect((await loadState()).currentUser, isNull);
  });

  test('unreadable saved data starts again from the starter data', () async {
    SharedPreferences.setMockInitialValues({'sprintly.tasks': 'not json'});

    final state = await loadState();

    expect(state.taskById('t1'), isNotNull);
  });

  test('one damaged saved task does not lose the others', () async {
    final good = newTask('t-good').toJson();
    final damaged = {'id': 't-bad', 'title': 'No other fields'};
    final older = Map<String, dynamic>.from(newTask('t-older').toJson())
      ..remove('project')
      ..remove('tags');
    SharedPreferences.setMockInitialValues({
      'sprintly.tasks': jsonEncode([good, damaged, older]),
    });

    final state = await loadState();

    expect([for (final task in state.tasks) task.id], ['t-good', 't-older']);
    expect(state.taskById('t-older')!.project, '');
    expect(state.taskById('t-older')!.tags, isEmpty);
  });
}
