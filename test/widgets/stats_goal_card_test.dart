import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus/l10n/app_localizations.dart';
import 'package:focus/widgets/stats_goal_card.dart';

void main() {
  Widget buildSubject({required Locale locale}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: StatsGoalCard(
          title: 'Daily Goal',
          current: 4,
          goal: 4,
          icon: Icons.flag_rounded,
          color: Colors.green,
        ),
      ),
    );
  }

  testWidgets('goal achieved badge is localized in English mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject(locale: const Locale('en')));

    expect(find.text('Achieved'), findsOneWidget);
    expect(find.text('達成'), findsNothing);
  });
}
