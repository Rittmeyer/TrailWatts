import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/models/rider_profile.dart';
import 'package:trailwatt/models/zone.dart';

void main() {
  group('tables are independent per metric', () {
    test('power and heart rate have their own tables and scales', () {
      final power = ZoneTables.of(ZoneMetric.power, ZoneScale.seven);
      final hr = ZoneTables.of(ZoneMetric.heartRate, ZoneScale.five);

      expect(power.zones, hasLength(7));
      expect(hr.zones, hasLength(5));
      expect(power.metric, ZoneMetric.power);
      expect(hr.metric, ZoneMetric.heartRate);
    });

    test('both metrics support both scales', () {
      for (final metric in ZoneMetric.values) {
        for (final scale in ZoneScale.values) {
          expect(ZoneTables.of(metric, scale).zones, hasLength(scale.count),
              reason: '$metric at $scale');
        }
      }
    });

    test('the same Z-number is a different zone on each table', () {
      const powerZ5 = TrainingZone(
          metric: ZoneMetric.power, scale: ZoneScale.seven, index: 5);
      const hrZ5 = TrainingZone(
          metric: ZoneMetric.heartRate, scale: ZoneScale.five, index: 5);

      expect(powerZ5 == hrZ5, isFalse);
      // Z5 of 7 power zones is a band; Z5 of 5 HR zones is open-ended.
      expect(powerZ5.definition.maxPct, isNotNull);
      expect(hrZ5.definition.maxPct, isNull);
    });

    test('a five-zone table is not equal to a seven-zone one', () {
      const five = TrainingZone(
          metric: ZoneMetric.power, scale: ZoneScale.five, index: 5);
      const seven = TrainingZone(
          metric: ZoneMetric.power, scale: ZoneScale.seven, index: 5);
      expect(five == seven, isFalse);
    });
  });

  group('table structure', () {
    test('every table is contiguous, ordered and open-ended at the top', () {
      for (final metric in ZoneMetric.values) {
        for (final scale in ZoneScale.values) {
          for (final anchor in HeartRateAnchor.values) {
            final table = ZoneTables.of(metric, scale, anchor: anchor);
            final zones = table.zones;
            expect(zones.first.minPct, 0, reason: '$metric/$scale bottom');
            expect(zones.last.maxPct, isNull, reason: '$metric/$scale top');
            for (var i = 0; i < zones.length; i++) {
              expect(zones[i].index, i + 1);
              if (i > 0) {
                expect(zones[i].minPct, zones[i - 1].maxPct,
                    reason: 'gap between Z$i and Z${i + 1} on $metric/$scale');
              }
            }
            if (metric == ZoneMetric.power) break; // anchor is HR-only
          }
        }
      }
    });

    test('every percentage resolves to exactly one zone', () {
      final table = ZoneTables.of(ZoneMetric.power, ZoneScale.seven);
      for (var pct = 0; pct <= 200; pct++) {
        final matches = table.zones.where((z) => z.containsPct(pct.toDouble()));
        expect(matches, hasLength(1), reason: 'at $pct% of FTP');
      }
    });

    test('heart rate anchored on LTHR differs from anchored on HR max', () {
      final lthr = ZoneTables.of(ZoneMetric.heartRate, ZoneScale.five,
          anchor: HeartRateAnchor.lactateThreshold);
      final max = ZoneTables.of(ZoneMetric.heartRate, ZoneScale.five,
          anchor: HeartRateAnchor.maximum);
      expect(lthr.byIndex(4).minPct, isNot(max.byIndex(4).minPct));
    });
  });

  group('resolving a value against a rider profile', () {
    const rider = RiderProfile(
      weightKg: 74,
      ftpWatts: 200,
      powerZones: PowerZoneSettings(scale: ZoneScale.seven),
      heartRateZones: HeartRateZoneSettings(
        scale: ZoneScale.five,
        anchor: HeartRateAnchor.lactateThreshold,
        lthrBpm: 170,
      ),
    );

    test('watts land on the power table', () {
      // 200 W = 100% FTP -> Z4 (91-106%)
      expect(rider.zoneFor(200, ZoneMetric.power)!.index, 4);
      // 100 W = 50% FTP -> Z1
      expect(rider.zoneFor(100, ZoneMetric.power)!.index, 1);
      // 400 W = 200% FTP -> Z7
      expect(rider.zoneFor(400, ZoneMetric.power)!.index, 7);
      expect(rider.zoneFor(200, ZoneMetric.power)!.metric, ZoneMetric.power);
    });

    test('bpm land on the heart-rate table', () {
      // 170 bpm = 100% LTHR -> Z5 on the five-zone table
      expect(rider.zoneFor(170, ZoneMetric.heartRate)!.index, 5);
      // 120 bpm = 71% LTHR -> Z1
      expect(rider.zoneFor(120, ZoneMetric.heartRate)!.index, 1);
      expect(rider.zoneFor(170, ZoneMetric.heartRate)!.metric,
          ZoneMetric.heartRate);
    });

    test('an unknown heart-rate anchor yields no zone rather than a guess', () {
      const noAnchor = RiderProfile(
        weightKg: 74,
        ftpWatts: 200,
        heartRateZones: HeartRateZoneSettings(scale: ZoneScale.five),
      );
      expect(noAnchor.zoneFor(150, ZoneMetric.heartRate), isNull);
      // Power still resolves - the tables are independent.
      expect(noAnchor.zoneFor(200, ZoneMetric.power), isNotNull);
    });
  });

  group('absolute bounds', () {
    test('power bounds come from FTP', () {
      const zones = PowerZoneSettings(scale: ZoneScale.seven);
      // Z4 is 91-106% of a 200 W FTP.
      expect(zones.lowerBoundWatts(4, 200), 182);
      expect(zones.upperBoundWatts(4, 200), 212);
      // The top zone is open-ended.
      expect(zones.upperBoundWatts(7, 200), isNull);
    });

    test('rider-entered bounds win over the percentage table', () {
      const zones = PowerZoneSettings(
        scale: ZoneScale.five,
        customLowerBoundsWatts: [0, 120, 160, 190, 230],
      );
      expect(zones.isCustom, isTrue);
      expect(zones.lowerBoundWatts(4, 200), 190);
      expect(zones.upperBoundWatts(4, 200), 229);
      expect(zones.upperBoundWatts(5, 200), isNull);
    });

    test('heart-rate bounds need an anchor and report when they lack one', () {
      const withAnchor =
          HeartRateZoneSettings(scale: ZoneScale.five, lthrBpm: 170);
      expect(withAnchor.isResolvable, isTrue);
      expect(withAnchor.lowerBoundBpm(4), 162); // 95% of 170

      const without = HeartRateZoneSettings(scale: ZoneScale.five);
      expect(without.isResolvable, isFalse);
      expect(without.lowerBoundBpm(4), isNull);
    });

    test('the HR max anchor uses its own table, not the LTHR one', () {
      const lthr = HeartRateZoneSettings(
          scale: ZoneScale.five,
          anchor: HeartRateAnchor.lactateThreshold,
          lthrBpm: 180);
      const hrMax = HeartRateZoneSettings(
          scale: ZoneScale.five,
          anchor: HeartRateAnchor.maximum,
          hrMaxBpm: 180);
      expect(lthr.lowerBoundBpm(4), isNot(hrMax.lowerBoundBpm(4)));
    });
  });

  group('rider-edited bounds', () {
    test('accepts a table that starts at zero and strictly increases', () {
      expect(
          isValidZoneBounds([0, 120, 160, 190, 230], ZoneScale.five), isTrue);
    });

    test('rejects a wrong number of bounds for the scale', () {
      expect(isValidZoneBounds([0, 120, 160], ZoneScale.five), isFalse);
      expect(isValidZoneBounds([0, 1, 2, 3, 4, 5, 6], ZoneScale.five), isFalse);
    });

    test('rejects a table that does not start at zero', () {
      expect(
          isValidZoneBounds([50, 120, 160, 190, 230], ZoneScale.five), isFalse);
    });

    test('rejects overlapping or repeated bounds', () {
      // Z3 would start below Z2 - a value could land in two zones.
      expect(
          isValidZoneBounds([0, 160, 120, 190, 230], ZoneScale.five), isFalse);
      // Equal bounds leave Z3 empty.
      expect(
          isValidZoneBounds([0, 120, 120, 190, 230], ZoneScale.five), isFalse);
    });

    test('null means the generic table, which is always valid', () {
      expect(isValidZoneBounds(null, ZoneScale.seven), isTrue);
      expect(const PowerZoneSettings().hasValidCustomBounds, isTrue);
    });

    test('settings report their own validity', () {
      const good = PowerZoneSettings(
          scale: ZoneScale.five,
          customLowerBoundsWatts: [0, 120, 160, 190, 230]);
      const bad = PowerZoneSettings(
          scale: ZoneScale.five,
          customLowerBoundsWatts: [0, 200, 160, 190, 230]);
      expect(good.hasValidCustomBounds, isTrue);
      expect(bad.hasValidCustomBounds, isFalse);

      const hrGood = HeartRateZoneSettings(
          scale: ZoneScale.five,
          lthrBpm: 170,
          customLowerBoundsBpm: [0, 140, 150, 160, 168]);
      expect(hrGood.hasValidCustomBounds, isTrue);
    });

    test('derived bounds seed the editor from the generic table', () {
      const zones = PowerZoneSettings(scale: ZoneScale.seven);
      final seed = zones.derivedBounds(200);
      expect(seed, hasLength(7));
      expect(seed.first, 0);
      expect(isValidZoneBounds(seed, ZoneScale.seven), isTrue);
      // Z4 of a 200 W FTP starts at 91%.
      expect(seed[3], 182);
    });

    test('heart-rate derived bounds need an anchor', () {
      expect(const HeartRateZoneSettings(scale: ZoneScale.five).derivedBounds(),
          isNull);
      expect(
          const HeartRateZoneSettings(scale: ZoneScale.five, lthrBpm: 170)
              .derivedBounds(),
          hasLength(5));
    });

    test('edited bounds override the percentage table end to end', () {
      const rider = RiderProfile(
        weightKg: 74,
        ftpWatts: 200,
        powerZones: PowerZoneSettings(
            scale: ZoneScale.five,
            customLowerBoundsWatts: [0, 120, 160, 190, 230]),
      );
      // 195 W is Z4 under the rider's own table (190-229), not the generic
      // one, where 195 W = 97.5% FTP would also be Z4 but with other edges.
      expect(rider.powerZones.lowerBoundWatts(4, 200), 190);
      expect(rider.powerZones.upperBoundWatts(4, 200), 229);
    });
  });
}
