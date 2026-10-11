import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprintly/core/sla/sla_status.dart';
import 'package:sprintly/models/member.dart';
import 'package:sprintly/widgets/member_avatar.dart';
import 'package:sprintly/widgets/sprintly_header.dart';
import 'package:sprintly/widgets/status_chip.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('header shows the title, subtitle and actions', (tester) async {
    await pump(
      tester,
      const SprintlyHeader(
        title: 'Team Members',
        subtitle: 'Manage your team.',
        actions: [Icon(Icons.search)],
      ),
    );

    expect(find.text('Sprintly'), findsOneWidget);
    expect(find.text('Team Members'), findsOneWidget);
    expect(find.text('Manage your team.'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('header back button only shows and fires with onBack', (
    tester,
  ) async {
    var backPresses = 0;
    await pump(
      tester,
      SprintlyHeader(
        title: 'Edit Task',
        subtitle: 'Update the task details.',
        onBack: () => backPresses++,
      ),
    );

    await tester.tap(find.byTooltip('Back'));

    expect(backPresses, 1);
  });

  testWidgets('avatar shows the member initials', (tester) async {
    await pump(
      tester,
      MemberAvatar(
        member: Member(
          id: 'm1',
          name: 'Alex Carter',
          jobTitle: 'Product Manager',
          email: 'alex@sprintly.app',
          team: 'Product',
          joinedAt: DateTime(2024, 12, 1),
        ),
      ),
    );

    expect(find.text('AC'), findsOneWidget);
  });

  testWidgets('chips show the right label for each status', (tester) async {
    await pump(
      tester,
      const Column(
        children: [
          PresenceChip(presence: MemberPresence.online),
          PresenceChip(presence: MemberPresence.away),
          PresenceChip(presence: MemberPresence.offline),
          SlaChip(status: SlaStatus.onTrack),
          SlaChip(status: SlaStatus.atRisk),
          SlaChip(status: SlaStatus.overdue),
          SlaChip(status: SlaStatus.completed),
        ],
      ),
    );

    for (final label in [
      'Online',
      'Away',
      'Offline',
      'On Track',
      'At Risk',
      'Overdue',
      'Completed',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });
}
