import '../models/member.dart';
import '../models/task.dart';

// Starter data used the first time the app runs, before anything is saved.

const projects = ['Mobile App', 'Web Dashboard', 'Backend API', 'Documentation'];

List<Member> seedMembers() {
  final joined = DateTime(2024, 12, 1);

  return [
    Member(
      id: 'm1',
      name: 'Alex Carter',
      jobTitle: 'Product Manager',
      email: 'alex@sprintly.app',
      team: 'Product',
      role: MemberRole.admin,
      presence: MemberPresence.online,
      joinedAt: joined,
    ),
    Member(
      id: 'm2',
      name: 'Priya Sharma',
      jobTitle: 'Mobile Developer',
      email: 'priya@sprintly.app',
      team: 'Engineering',
      role: MemberRole.admin,
      presence: MemberPresence.online,
      joinedAt: joined,
    ),
    Member(
      id: 'm3',
      name: 'Marcus Lee',
      jobTitle: 'QA Engineer',
      email: 'marcus@sprintly.app',
      team: 'Engineering',
      presence: MemberPresence.away,
      joinedAt: joined,
    ),
    Member(
      id: 'm4',
      name: 'Emily Wong',
      jobTitle: 'UI/UX Designer',
      email: 'emily@sprintly.app',
      team: 'Design',
      presence: MemberPresence.online,
      joinedAt: joined,
    ),
    Member(
      id: 'm5',
      name: 'David Liu',
      jobTitle: 'Backend Engineer',
      email: 'david@sprintly.app',
      team: 'Engineering',
      joinedAt: joined,
    ),
    Member(
      id: 'm6',
      name: 'Sarah Kim',
      jobTitle: 'Technical Writer',
      email: 'sarah@sprintly.app',
      team: 'Product',
      presence: MemberPresence.online,
      joinedAt: joined,
    ),
  ];
}

// Due dates are relative to today so every SLA status shows up on first run
List<Task> seedTasks() {
  final now = DateTime.now();
  DateTime inDays(int days) => DateTime(now.year, now.month, now.day + days);

  return [
    Task(
      id: 't1',
      title: 'Design Login Screen',
      description:
          'Create a clean login screen with proper validation and error handling.',
      assigneeId: 'm2',
      dueDate: inDays(1),
      priority: TaskPriority.high,
      status: TaskStatus.inProgress,
      project: 'Mobile App',
      tags: ['UI/UX', 'Design', 'Frontend'],
      attachments: [TaskAttachment(name: 'login-design.fig', size: '2.4 MB')],
      createdAt: inDays(-5),
    ),
    Task(
      id: 't2',
      title: 'Set up project API routes',
      description: 'Define the REST endpoints for tasks and team members.',
      assigneeId: 'm5',
      dueDate: inDays(-2),
      priority: TaskPriority.high,
      status: TaskStatus.inProgress,
      project: 'Backend API',
      tags: ['Backend'],
      createdAt: inDays(-9),
    ),
    Task(
      id: 't3',
      title: 'Write onboarding guide',
      description: 'Document how a new team member sets up the project locally.',
      assigneeId: 'm6',
      dueDate: inDays(10),
      priority: TaskPriority.low,
      project: 'Documentation',
      tags: ['Docs'],
      createdAt: inDays(-1),
    ),
    Task(
      id: 't4',
      title: 'Test sign-in flow',
      description: 'Run through sign-in on Android and iOS and log any defects.',
      assigneeId: 'm3',
      dueDate: inDays(-1),
      status: TaskStatus.done,
      project: 'Mobile App',
      tags: ['QA'],
      createdAt: inDays(-6),
    ),
    Task(
      id: 't5',
      title: 'Dashboard wireframes',
      description: 'Sketch the dashboard layout with progress and SLA summary.',
      assigneeId: 'm4',
      // 2 days out: at Risk only because the task is high priority
      dueDate: inDays(2),
      priority: TaskPriority.high,
      project: 'Web Dashboard',
      tags: ['Design'],
      createdAt: inDays(-3),
    ),
    Task(
      id: 't6',
      title: 'Plan sprint backlog',
      description: 'Prioritise the backlog and assign tasks for the next sprint.',
      assigneeId: 'm1',
      dueDate: inDays(6),
      project: 'Mobile App',
      tags: ['Planning'],
      createdAt: inDays(-2),
    ),
  ];
}
