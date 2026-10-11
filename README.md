# Sprintly

**A mobile project and SLA task tracker built with Flutter.**

Sprintly helps small software development teams organize tasks, assign responsibilities, manage deadlines, monitor project progress, and identify work that needs immediate attention.

The application combines task management, team collaboration, performance analytics, and automated SLA monitoring in a clean, mobile-first interface.

Built as a collaborative software development project, Sprintly demonstrates Flutter UI development, reusable widgets, navigation, form validation, state management, business logic, automated testing, and local data persistence.

## Features

### User Selection and Sign In
- Select a team member profile to access the application.
- Validate email and password form inputs.
- Maintain the selected user session across application restarts.
- Sign out and switch between team profiles.
- Demonstrate authentication flow without requiring a backend.

### Project Dashboard
- View project and task activity in one place.
- Monitor total tasks, on-track tasks, at-risk tasks, and overdue tasks.
- Review overall SLA health and task progress.
- See upcoming deadlines and recent activity.
- Navigate to relevant task-management screens.

### Task Management
- Browse tasks with assignees, deadlines, priorities, and SLA indicators.
- Search tasks by title, project, or team member.
- Filter tasks by SLA classification.
- Create tasks with validated inputs.
- Assign tasks to existing team members.
- Set deadlines, priorities, project associations, and workflow statuses.
- View detailed task information.
- Edit existing tasks and delete tasks.
- Mark tasks as completed.

### Deadline Calendar
- View task deadlines in a calendar interface.
- Identify scheduled work and approaching deadlines.
- Review tasks associated with selected dates.
- Use visual indicators to distinguish task conditions.
- Move between months, jump back to today, and mark a task done or reopen it from the selected day.

### Team Management
- Browse and search team members.
- Filter by All, Admins, and Members.
- View individual member profiles and assigned tasks.
- Monitor team workloads.
- Allow administrators to add members, update roles, and remove eligible members.
- Prevent removal of members who still have assigned tasks.

### Task Analytics
- Monitor task distribution across SLA classifications.
- View overall completion statistics.
- Review project progress and task performance.
- Identify overdue and at-risk workloads.
- Switch between This Month and All Time. Opened from the chart button on Home.

### Alerts and Attention
- Identify tasks requiring immediate attention.
- Highlight overdue work and approaching deadlines.
- Review prioritized task alerts.
- Navigate to relevant tasks.
- See on-track deadlines due in the next 7 days. Opened from the bell on Home.

### User Profile
- View and update profile information.
- Manage presence and account settings.
- Review personal task assignments and workload.
- Sign out of the application.

### Local Data Persistence
- Save tasks, team members, and user-session information locally.
- Restore saved data when the application restarts.
- Preserve task updates and deletions.
- Recalculate SLA classifications using current dates and task statuses.
- Operate without a backend or internet connection for core task-management functionality.

## SLA Classification

Sprintly automatically classifies tasks using deadlines, workflow statuses, and priorities.

| SLA Status | Rule |
|---|---|
| Completed | The task is marked Done, regardless of its deadline. |
| Overdue | The task is incomplete and its deadline has passed. |
| At Risk | An incomplete task is due within 48 hours, or within 72 hours for High-priority tasks. |
| On Track | The task is incomplete and does not meet the At Risk or Overdue conditions. |

Tasks are due at **11:59:59 PM on their selected due date**, rather than at the beginning of the day.

SLA classifications are evaluated in the following order:

1. Completed
2. Overdue
3. At Risk
4. On Track

The classification rules are centralized in `lib/core/sla/sla_status.dart` through the `classifySla()` function.

### Workflow Status vs. SLA Status

Sprintly distinguishes between two kinds of task status.

**Workflow status** describes the task's progress:
- To Do
- In Progress
- Done

**SLA status** describes its deadline condition:
- On Track
- At Risk
- Overdue
- Completed

For example, a task may be In Progress while simultaneously being At Risk.

This separation allows the application to monitor deadlines independently of task progress.

## Technical Architecture

### Framework

Sprintly is developed using **Flutter and Dart**, with reusable widgets and Material Design components.

The UI uses widgets such as `Scaffold`, `AppBar`, `ListView`, `Column`, `Row`, `Card`, `Form`, `TextFormField`, `DropdownButtonFormField`, `NavigationBar`, and `FloatingActionButton`.

A shared theme maintains consistency across screens.

### State Management: Provider

Sprintly uses the Provider package with a central `AppState` class extending `ChangeNotifier`.

`AppState` manages:
- Team members
- Tasks
- Current signed-in user
- Task creation, updates, and deletion
- Team-member management
- SLA calculations and progress statistics

Widgets subscribe to application state using Provider, and changes automatically update dependent screens.

### Local Storage: SharedPreferences

Sprintly uses SharedPreferences instead of SQLite because the application manages a relatively small amount of structured local data.

Tasks and team members are serialized into JSON and stored on the device.

The `StorageService` handles reading and writing data, while `AppState` coordinates updates and restores saved information when the application launches.

This approach avoids unnecessary database complexity while satisfying the assignment's persistence requirement.

### Navigation

Sprintly uses:
- An authentication gate to switch between Sign In and the main application.
- A five-tab bottom navigation structure for Home, Tasks, Calendar, Team, and Profile.
- Flutter's `Navigator` for opening detail screens and forms.
- An `IndexedStack` to preserve tab state when switching between major sections.

Alerts opens from the bell on the Home screen and Task Statistics from the chart button beside it.

### Validation and Error Handling

Flutter forms provide input validation and user feedback.

Validation includes:
- Required task titles and form fields
- Minimum task-title length
- Valid email formatting
- Password length checks for the demonstration sign-in flow
- Valid team-member selection
- Deadline selection
- Project selection

Application logic also enforces rules such as preventing the removal of members with assigned tasks.

## Project Structure

```text
lib/
├── main.dart
├── core/
│   ├── sla/
│   └── theme/
├── data/
│   └── seed_data.dart
├── models/
│   ├── member.dart
│   └── task.dart
├── screens/
│   ├── auth/
│   ├── shell/
│   ├── home/
│   ├── tasks/
│   ├── team/
│   ├── profile/
│   ├── calendar/
│   ├── alerts/
│   └── statistics/
├── services/
│   └── storage_service.dart
├── state/
│   └── app_state.dart
└── widgets/

test/
integration_test/
```

The application separates UI presentation, domain models, business logic, state management, and storage to support maintainability and parallel team development.

## Getting Started

### Prerequisites

- Flutter SDK 3.44 or newer
- Dart SDK included with Flutter
- VS Code or Android Studio
- Android emulator or physical Android device
- Git

### Clone the Repository

```bash
git clone https://github.com/sultanhabibllah/SLA-task-tracker.git
cd SLA-task-tracker
```

### Install Dependencies

```bash
flutter pub get
```

### Verify Flutter Installation

```bash
flutter doctor
```

### Run the Application

```bash
flutter run
```

To list available devices:

```bash
flutter devices
```

To run on a specific device:

```bash
flutter run -d <device-id>
```

## Testing

Sprintly includes unit tests, widget tests, and integration testing.

### Static Analysis

```bash
flutter analyze
```

### Unit and Widget Tests

```bash
flutter test
```

Timing checks for the Alerts, Calendar and Statistics helpers live in `test/perf/`:

```bash
flutter test test/perf/
```

### Integration Tests

```bash
flutter test integration_test/app_test.dart -d <device-id>
```

The automated tests cover application logic and UI behaviors, including task creation, updates, deletion, SLA classification, form validation, filtering, and local persistence.

The end-to-end test exercises the application's user workflow on an emulator or device.

## Collaborative Development

Sprintly was developed collaboratively using Git and GitHub.

The team uses feature branches and pull requests to organize development across different screens and functional areas.

The workflow includes:
- Independent screen implementation
- Shared models and reusable widgets
- Feature-specific commits
- Pull request reviews
- Merge conflict resolution
- Integration testing

This approach supports parallel development while maintaining a consistent application architecture.

## Assignment Demonstration

The application demonstrates the following workflow:

1. Select a team member and sign in.
2. View project progress on the Dashboard.
3. Browse and filter tasks.
4. Create a task and assign it to a team member.
5. Select its priority, status, project, and deadline.
6. Save the task and confirm it appears in the Task List.
7. Edit the task or update its workflow status.
8. Review its automatically calculated SLA classification.
9. Close and reopen the application to demonstrate local persistence.
10. Review the Calendar, Team Members, Analytics, Alerts, and Profile screens.

The demonstration also explains Flutter widgets, navigation, validation, Provider state management, SLA calculations, SharedPreferences persistence, and collaborative Git development.

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform mobile UI |
| Dart | Application development |
| Material Design | UI widgets and components |
| Provider | State management |
| SharedPreferences | Local data persistence |
| Flutter Test | Unit and widget testing |
| Git | Version control |
| GitHub | Collaboration and pull requests |

## Project Status

**All 12 planned screens have been implemented.**

The application includes task management, team management, deadline tracking, SLA monitoring, local persistence, and automated testing.

Developed as a group Flutter software development assignment.