import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/models/rider_profile.dart';
import 'package:trailwatt/models/zone.dart';
import 'package:trailwatt/services/rider_profile_store.dart';

void main() {
  test('defaults to the documented pairing until the rider saves', () {
    final store = RiderProfileStore();
    // Seven power / five heart-rate, per DECISIONS_REQUIRED.md.
    expect(store.powerScale, ZoneScale.seven);
    expect(store.heartRateZones?.scale, ZoneScale.five);
  });

  test('saving a five-zone table is what every other screen then reads', () {
    final store = RiderProfileStore();

    store.save(const RiderProfile(
      weightKg: 74,
      ftpWatts: 210,
      powerZones: PowerZoneSettings(scale: ZoneScale.five),
    ));

    expect(store.powerScale, ZoneScale.five);
    expect(store.profile.ftpWatts, 210);
  });

  test('saving notifies, so screens holding the profile rebuild', () {
    final store = RiderProfileStore();
    var notifications = 0;
    store.addListener(() => notifications++);

    store.save(const RiderProfile(
      weightKg: 70,
      ftpWatts: 250,
      powerZones: PowerZoneSettings(scale: ZoneScale.five),
    ));

    expect(notifications, 1);
  });

  test('a profile with no heart-rate table reports absence, not five zones',
      () {
    final store = RiderProfileStore(
      profile: const RiderProfile(weightKg: 74, ftpWatts: 210),
    );
    // An absent HR table and a five-zone one are different things: a screen
    // that needs an anchor has to see the difference rather than guess.
    expect(store.heartRateZones, isNull);
  });

  group('the zone a wattage falls into follows the saved table', () {
    // 280 w against a 210 w FTP is 133% - anaerobic Z6 on the seven-zone
    // table, but VO2max Z5 on the five-zone one, where Coggan's top three
    // zones are collapsed into one. This is exactly the difference the
    // calendar and route legend were ignoring.
    test('seven zones put 280 w in Z6', () {
      final store = RiderProfileStore();
      expect(store.profile.zoneFor(280, ZoneMetric.power)?.index, 6);
    });

    test('five zones put the same 280 w in Z5', () {
      final store = RiderProfileStore(
        profile: const RiderProfile(
          weightKg: 74,
          ftpWatts: 210,
          powerZones: PowerZoneSettings(scale: ZoneScale.five),
        ),
      );
      final zone = store.profile.zoneFor(280, ZoneMetric.power)!;
      expect(zone.index, 5);
      expect(zone.scale, ZoneScale.five);
    });
  });
}
