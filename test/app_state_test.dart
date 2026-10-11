import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    expect(Task.fromJson(task.toJson()).toJson(), task.toJson());
    expect(Member.fromJson(member.toJson()).toJson(), member.toJson());
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
    final total = state.tasks.length;
    final done = state.tasks.where((task) => task.isDone).length;

    expect(state.progress, done / total);
    expect(
      state.slaCounts().values.reduce((a, b) => a + b),
      total,
    );
  });

  test('unreadable saved data falls back to the starter data', () async {
    SharedPreferences.setMockInitialValues({'sprintly.tasks': 'not json'});

    final state = await loadState();

    expect(state.tasks, isNotEmpty);
  });
}
