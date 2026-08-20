import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/services/activity_store.dart';

/// The demo activities: one already linked to 21 July, two loose rides.
const _linked = 'activity-parque';
const _loose = 'activity-serra';
final _linkedDay = DateTime(2026, 7, 21);
final _plannedDay = DateTime(2026, 7, 20);

void main() {
  late ActivityStore store;

  setUp(() => store = ActivityStore());

  group('what is linked to what', () {
    test('a linked activity is the day\'s result', () {
      expect(store.linkedTo(_linkedDay)?.id, _linked);
      expect(store.isDone(_linkedDay), isTrue);
    });

    test('a day nothing points at is not done', () {
      expect(store.linkedTo(_plannedDay), isNull);
      expect(store.isDone(_plannedDay), isFalse);
    });

    test('the time of day never decides which activity a date finds', () {
      expect(store.linkedTo(DateTime(2026, 7, 21, 18, 30))?.id, _linked);
    });

    test('unlinked lists only rides that are nobody\'s result', () {
      final ids = store.unlinked.map((a) => a.id);
      expect(ids, contains(_loose));
      expect(ids, isNot(contains(_linked)));
    });

    test('history lists every activity, linked or not, newest first', () {
      expect(store.activities, hasLength(3));
      expect(store.activities.first.date.isAfter(store.activities.last.date),
          isTrue);
    });
  });

  group('linking', () {
    test('records the ride as the day\'s result and notifies', () {
      var notifications = 0;
      store.addListener(() => notifications++);

      store.link(_loose, _plannedDay);

      expect(store.linkedTo(_plannedDay)?.id, _loose);
      expect(store.isDone(_plannedDay), isTrue);
      expect(notifications, 1);
    });

    test('a day holds one result, so linking a second frees the first', () {
      store.link(_loose, _linkedDay);

      expect(store.linkedTo(_linkedDay)?.id, _loose);
      // The ride that was there is loose again rather than a second result.
      expect(store.unlinked.map((a) => a.id), contains(_linked));
    });

    test('the activity itself is untouched apart from the link', () {
      final before = store.activities.firstWhere((a) => a.id == _loose);
      store.link(_loose, _plannedDay);
      final after = store.activities.firstWhere((a) => a.id == _loose);

      expect(after.realizedWatts, before.realizedWatts);
      expect(after.date, before.date);
      expect(after.source, before.source);
    });
  });

  group('unlinking', () {
    test('frees the day and keeps the ride', () {
      var notifications = 0;
      store.addListener(() => notifications++);

      store.unlink(_linked);

      expect(store.isDone(_linkedDay), isFalse);
      // The ride still happened - it just is not this day's result.
      expect(store.activities.map((a) => a.id), contains(_linked));
      expect(store.unlinked.map((a) => a.id), contains(_linked));
      expect(notifications, 1);
    });

    test('unlinking a ride that was not linked changes nothing', () {
      var notifications = 0;
      store.addListener(() => notifications++);

      store.unlink(_loose);

      expect(notifications, 0, reason: 'nothing changed, so nothing to report');
    });

    test('a ride can be linked again after being freed', () {
      store.unlink(_linked);
      store.link(_linked, _plannedDay);

      expect(store.linkedTo(_plannedDay)?.id, _linked);
      expect(store.isDone(_linkedDay), isFalse);
    });
  });
}
