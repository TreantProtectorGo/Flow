import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus/l10n/app_localizations.dart';
import 'package:focus/models/chat_message.dart';
import 'package:focus/widgets/task_plan_editor.dart';

void main() {
  Widget buildSubject(TaskPlan plan) {
    return ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TaskPlanEditor(initialPlan: plan),
      ),
    );
  }

  testWidgets('bottom statistics do not overflow on phone width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final plan = TaskPlan(
      mainGoal: 'Learn React Basics',
      estimatedTime: '3 hour 35 min',
      tasks: <TaskPlanItem>[
        TaskPlanItem(
          title: 'React Core Concepts Overview',
          description: '',
          steps: <String>[],
          pomodoroCount: 1,
          priority: 'high',
        ),
        TaskPlanItem(
          title: 'React Dev Environment Setup',
          description: '',
          steps: <String>[],
          pomodoroCount: 1,
          priority: 'high',
        ),
        TaskPlanItem(
          title: 'Build First React Component',
          description: '',
          steps: <String>[],
          pomodoroCount: 3,
          priority: 'high',
        ),
        TaskPlanItem(
          title: 'Add State and Event Handling',
          description: '',
          steps: <String>[],
          pomodoroCount: 2,
          priority: 'medium',
        ),
      ],
    );

    await tester.pumpWidget(buildSubject(plan));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
