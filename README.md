# Sprintly

A mobile project and SLA task tracker for a small software team, built with Flutter.
Team members sign in, manage tasks and teammates, and see at a glance which tasks
are on track, at risk, overdue or completed.

## Features

- **Sign in** by choosing a team profile.
- **Team Members**: browse, filter (All / Admins / Members) and search the team, and
  view any member's tasks. Admins can also add members, change roles and remove members.
- **Edit Task**: change title, description, assignee, due date, priority, status,
  project and tags, with a live preview of the task's SLA status. Delete a task.
- **Profile**: edit your details and status, see your own workload by SLA status,
  and sign out.
- **Calendar**: a month view with a coloured dot for each SLA status on days that have
  tasks due. Tap a day to list its tasks, and mark a task done or reopen it from its menu.
- **Alerts & Attention**: opened from the bell on Home. Lists overdue tasks, at-risk tasks
  and on-track deadlines in the next 7 days, with View all to expand each section.
- **Task Statistics**: opened from the chart button on Home. Totals per SLA status, a
  status donut with percentages, progress per project and the next three deadlines,
  for This Month or All Time.
- **Data is saved on the device** and is still there after the app is closed.

## SLA rules

Every task gets one status, decided in this order:

| Status    | Rule                                                              |
|-----------|-------------------------------------------------------------------|
| Completed | The task is marked Done, whatever its due date.                   |
| Overdue   | Not done, and the due date has passed.                            |
| At Risk   | Not done, and due within 48 hours (72 hours for High priority).   |
| On Track  | Every other open task.                                            |

A task is due at the end of its due day, so a task due today is At Risk, not Overdue.
The rules live in one function, `classifySla` in `lib/core/sla/sla_status.dart`.

## Technical decisions

- **State management: Provider.** One `ChangeNotifier`, `AppState`, holds the members,
  tasks and signed-in user. Screens read it with `context.watch` and call its methods
  to make changes.
- **Storage: SharedPreferences.** Members and tasks are each saved as one JSON list.
  The data is small and flat, so a database would add schema code for no benefit.
- **Navigation.** An auth gate in `main.dart` shows the sign-in screen or the app
  depending on who is signed in. Inside the app, a bottom navigation bar switches
  between five tabs, and detail screens are opened with `Navigator.push`.
- **Validation.** Forms use `Form` and `TextFormField` validators; business rules such
  as "a member with tasks cannot be removed" are checked before any change is saved.

## Project structure

```
lib/
  main.dart                 App entry point and auth gate
  core/
    sla/sla_status.dart     SLA rules, labels and colours
    sla/task_insights.dart  Grouping and counts for Alerts, Calendar and Statistics
    theme/                  Colours and app theme
  data/seed_data.dart       Starter members, tasks and project names
  models/                   Member and Task
  services/                 StorageService (SharedPreferences)
  state/app_state.dart      AppState (Provider)
  screens/
    auth/                   Sign in
    shell/                  Bottom navigation
    team/                   Team Members, add member, member tasks
    profile/                Profile
    tasks/                  Edit Task
    alerts/                 Alerts & Attention
    calendar/               Calendar month grid and day tasks
    statistics/             Task Statistics
  widgets/                  Shared header, avatar, status chips, edit dialog
test/                       Unit and widget tests
test/perf/                  Timing checks for the insight helpers
integration_test/           End-to-end test for a device or emulator
```

## Running the app

Requires Flutter 3.44 or newer.

```
flutter pub get
flutter run
```

Run it on an Android emulator, an iOS simulator or a physical device.

## Tests

```
flutter analyze
flutter test
flutter test integration_test/app_test.dart -d <device id>
```

`flutter test` runs the unit and widget tests. The integration test drives the real
app on a device: sign in, mark an overdue task as done, check the change survives a
restart, and sign out.

## Running the tests

```
flutter test
flutter test test/task_insights_test.dart
flutter test test/perf/
```
