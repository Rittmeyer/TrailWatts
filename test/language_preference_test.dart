import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/main.dart';
import 'package:trailwatt/services/locale_store.dart';

import 'l10n_harness.dart';

/// The rider gets to disagree with the device about which language they
/// read training in.
void main() {
  final pt = stringsFor(const Locale('pt'));
  final en = stringsFor(const Locale('en'));

  // The store is app-wide; a test that changes it puts it back.
  tearDown(() => LocaleStore.instance.use(null));

  group('the store', () {
    test('follows the device until told otherwise', () {
      expect(LocaleStore.instance.followsDevice, isTrue);
      expect(LocaleStore.instance.locale, isNull);
    });

    test('announces a change, and only a real one', () {
      var notifications = 0;
      void count() => notifications++;
      LocaleStore.instance.addListener(count);
      addTearDown(() => LocaleStore.instance.removeListener(count));

      LocaleStore.instance.use(const Locale('pt'));
      LocaleStore.instance.use(const Locale('pt'));
      expect(notifications, 1);

      LocaleStore.instance.use(null);
      expect(notifications, 2);
      expect(LocaleStore.instance.followsDevice, isTrue);
    });
  });

  group('picking a language in the profile', () {
    Future<void> openProfile(WidgetTester tester) async {
      await tester.pumpWidget(const TrailwattApp());
      await tester.pumpAndSettle();
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pushNamed('/profile');
      await tester.pumpAndSettle();
    }

    /// Language names are written in their own language, so they read the
    /// same whichever language the app is currently in.
    Future<void> pick(WidgetTester tester, String language) async {
      final row = find.text(language);
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
    }

    testWidgets('changes the language the app is written in', (tester) async {
      await openProfile(tester);
      expect(find.text(en.profileTitle), findsOneWidget);

      await pick(tester, 'Português');

      expect(LocaleStore.instance.locale, const Locale('pt'));
      expect(find.text(pt.profileTitle), findsOneWidget);
      expect(find.text(en.profileTitle), findsNothing);
    });

    testWidgets('offers every language, plus following the device',
        (tester) async {
      await openProfile(tester);
      await tester.ensureVisible(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.text('Português'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text(en.languageSystem), findsOneWidget);
    });

    testWidgets('the device choice is reachable again after picking one',
        (tester) async {
      await openProfile(tester);
      await pick(tester, 'Português');
      expect(LocaleStore.instance.followsDevice, isFalse);

      await pick(tester, pt.languageSystem);

      expect(LocaleStore.instance.followsDevice, isTrue);
      expect(find.text(en.profileTitle), findsOneWidget);
    });
  });
}
