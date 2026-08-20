import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trailwatt/models/result_source.dart';
import 'package:trailwatt/models/rider_profile.dart';
import 'package:trailwatt/models/workout_block.dart';
import 'package:trailwatt/models/zone.dart';
import 'package:trailwatt/services/platform/oauth_tokens.dart';
import 'package:trailwatt/services/platform/platform_api_client.dart';
import 'package:trailwatt/services/platform/platform_credentials.dart';
import 'package:trailwatt/services/training_peaks_import.dart';

const _tokens = OAuthTokens(accessToken: 'access-1');

/// FTP 200 keeps the percent-of-FTP arithmetic readable: 95% is 190 w.
const _rider = RiderProfile(
  weightKg: 74,
  ftpWatts: 200,
  powerZones: PowerZoneSettings(scale: ZoneScale.seven),
);

final _credentials = PlatformCredentials(
  platform: ResultSource.trainingPeaks,
  clientId: 'client-123',
  authorizationEndpoint: Uri.parse('https://example.test/oauth/authorize'),
  tokenEndpoint: Uri.parse('https://example.test/oauth/token'),
  apiBaseUrl: Uri.parse('https://example.test/v1'),
  scopes: const ['workouts:read'],
  redirectUri: Uri.parse('trailwatt://oauth/trainingpeaks'),
);

TrainingPeaksImportService _serviceReturning(
  Object body, {
  int status = 200,
  void Function(http.Request request)? onRequest,
}) =>
    TrainingPeaksImportService(
      client: MockClient((req) async {
        onRequest?.call(req);
        return http.Response(jsonEncode(body), status,
            headers: {'content-type': 'application/json'});
      }),
    );

/// One step of a TrainingPeaks structured workout.
Map<String, dynamic> _step({
  required int seconds,
  required num minPct,
  required num maxPct,
  String intensityClass = 'active',
}) =>
    {
      'length': {'value': seconds, 'unit': 'second'},
      'targets': [
        {'minValue': minPct, 'maxValue': maxPct}
      ],
      'intensityClass': intensityClass,
    };

/// The worked example: 10min warm-up, 4x(8min @ 95% / 2min easy), 8min down.
Map<String, dynamic> _plannedWorkout() => {
      'workoutId': 4321,
      'title': '4x8 threshold',
      'structure': {
        'primaryIntensityMetric': 'percentOfFtp',
        'structure': [
          {
            'type': 'step',
            'steps': [
              _step(
                  seconds: 600,
                  minPct: 55,
                  maxPct: 65,
                  intensityClass: 'warmUp')
            ],
          },
          {
            'type': 'repetition',
            'length': {'value': 4, 'unit': 'repetition'},
            'steps': [
              _step(seconds: 480, minPct: 91, maxPct: 99),
              _step(
                  seconds: 120, minPct: 45, maxPct: 55, intensityClass: 'rest'),
            ],
          },
          {
            'type': 'step',
            'steps': [
              _step(
                  seconds: 480,
                  minPct: 45,
                  maxPct: 55,
                  intensityClass: 'coolDown')
            ],
          },
        ],
      },
    };

Future<List<WorkoutBlockGroup>> _import(TrainingPeaksImportService service) =>
    service.importPreferredWorkout(
      credentials: _credentials,
      tokens: _tokens,
      rider: _rider,
      from: DateTime.utc(2026, 8, 20),
    );

void main() {
  group('the request', () {
    test('reads a bounded window of planned workouts, authorized', () async {
      http.Request? sent;
      final service =
          _serviceReturning(const [], onRequest: (req) => sent = req);

      await _import(service);

      expect(sent!.method, 'GET');
      expect(sent!.url.path, '/v1/workouts/planned');
      expect(sent!.headers['Authorization'], 'Bearer access-1');
      // Article II: a short window, never the whole library.
      expect(sent!.url.queryParameters['startDate'], '2026-08-20');
      expect(sent!.url.queryParameters['endDate'], '2026-08-27');
    });
  });

  group('mapping a structured workout onto builder blocks', () {
    test('a repetition becomes one block with two stimuli, not eight blocks',
        () async {
      final groups = await _import(_serviceReturning([_plannedWorkout()]));

      expect(groups, hasLength(3));

      final intervals = groups[1];
      expect(intervals.repeatCount, 4);
      expect(intervals.isMultiStimulus, isTrue);
      expect(intervals.stimuli.map((s) => s.durationMin), [8, 2]);
      expect(intervals.stimuli.map((s) => s.role),
          [WorkoutBlockRole.work, WorkoutBlockRole.recovery]);

      // The whole point of the group: it expands to the real sequence.
      expect(intervals.expanded, hasLength(8));
      expect(intervals.totalDurationMin, 40);
    });

    test('percent of FTP becomes absolute watts against the rider profile',
        () async {
      final groups = await _import(_serviceReturning([_plannedWorkout()]));
      final work = groups[1].stimuli.first;

      // 91-99% of a 200 w FTP.
      expect(work.target.minValue, 182);
      expect(work.target.maxValue, 198);
      expect(work.target.metric, ZoneMetric.power);
    });

    test('the zone is resolved from the middle of the prescribed range',
        () async {
      final groups = await _import(_serviceReturning([_plannedWorkout()]));

      // 190 w against a 200 w FTP is threshold; the block invariant also
      // requires the zone metric to agree with the target metric.
      expect(
          groups[1].stimuli.first.zone, _rider.zoneFor(190, ZoneMetric.power));
      expect(groups[1].stimuli.first.zone.metric, ZoneMetric.power);
    });

    test('warm-up and cool-down keep their own roles', () async {
      final groups = await _import(_serviceReturning([_plannedWorkout()]));

      expect(groups.first.stimuli.single.role, WorkoutBlockRole.warmUp);
      expect(groups.last.stimuli.single.role, WorkoutBlockRole.coolDown);
      expect(groups.first.repeatCount, 1);
    });

    test('the flattened workout is the timeline the route engine matches',
        () async {
      final groups = await _import(_serviceReturning([_plannedWorkout()]));
      final blocks = flattenBlockGroups(groups);

      expect(workoutDurationMin(blocks), 10 + 40 + 8);
      // Only the four work stimuli are intervals to match a segment against.
      final steps = expandWorkout(blocks);
      expect(steps.where((s) => s.intervalId != null), hasLength(4));
    });
  });

  group('what it refuses to invent', () {
    test('a step with no target is dropped rather than given one', () async {
      final groups = await _import(_serviceReturning([
        {
          'structure': {
            'primaryIntensityMetric': 'percentOfFtp',
            'structure': [
              {
                'type': 'step',
                'steps': [
                  {
                    'length': {'value': 600, 'unit': 'second'},
                    'intensityClass': 'active',
                  },
                  _step(seconds: 480, minPct: 91, maxPct: 99),
                ],
              },
            ],
          },
        }
      ]));

      // The untargeted step is gone; the one that carried a target survives.
      expect(groups.single.stimuli, hasLength(1));
      expect(groups.single.stimuli.single.durationMin, 8);
    });

    test('a step shorter than the block model can express is dropped',
        () async {
      final groups = await _import(_serviceReturning([
        {
          'structure': {
            'primaryIntensityMetric': 'percentOfFtp',
            'structure': [
              {
                'type': 'step',
                'steps': [
                  // 20s rounds to zero minutes - rounding it up to a minute
                  // would prescribe 40 seconds nobody asked for.
                  _step(seconds: 20, minPct: 120, maxPct: 130),
                  _step(seconds: 480, minPct: 91, maxPct: 99),
                ],
              },
            ],
          },
        }
      ]));

      expect(groups.single.stimuli, hasLength(1));
      expect(groups.single.stimuli.single.durationMin, 8);
    });

    test('an HR-based plan is not imported as if it were watts', () async {
      final groups = await _import(_serviceReturning([
        {
          'structure': {
            'primaryIntensityMetric': 'percentOfThresholdHr',
            'structure': [
              {
                'type': 'step',
                'steps': [_step(seconds: 480, minPct: 91, maxPct: 99)],
              },
            ],
          },
        }
      ]));

      // Turning %LTHR into watts would need an anchor the app does not have.
      expect(groups, isEmpty);
    });

    test('an unstructured workout imports as nothing, not as a guess',
        () async {
      final groups = await _import(_serviceReturning([
        {'workoutId': 1, 'title': 'Endurance ride', 'description': '2h easy'}
      ]));

      expect(groups, isEmpty);
    });

    test('the first workout that actually has structure is the one used',
        () async {
      final groups = await _import(_serviceReturning([
        {'workoutId': 1, 'title': 'Rest day'},
        _plannedWorkout(),
      ]));

      expect(groups, hasLength(3));
    });
  });

  group('failures are reported, never returned as an empty plan', () {
    test('nothing planned is an empty list, which is a real answer', () async {
      expect(await _import(_serviceReturning(const [])), isEmpty);
    });

    test('a rejected token is unauthorized', () async {
      await expectLater(
        _import(_serviceReturning(const {}, status: 401)),
        throwsA(isA<PlatformApiException>().having(
            (e) => e.failure, 'failure', PlatformApiFailure.unauthorized)),
      );
    });

    test('a server error is a network failure, not an empty plan', () async {
      await expectLater(
        _import(_serviceReturning(const {}, status: 500)),
        throwsA(isA<PlatformApiException>()
            .having((e) => e.failure, 'failure', PlatformApiFailure.network)),
      );
    });

    test('a body that is not a workout collection is reported', () async {
      await expectLater(
        _import(_serviceReturning('just a string')),
        throwsA(isA<PlatformApiException>().having(
            (e) => e.failure, 'failure', PlatformApiFailure.invalidResponse)),
      );
    });

    test('an unreachable API is a network failure', () async {
      final service = TrainingPeaksImportService(
        client: MockClient((_) async => throw http.ClientException('down')),
      );
      await expectLater(
        _import(service),
        throwsA(isA<PlatformApiException>()
            .having((e) => e.failure, 'failure', PlatformApiFailure.network)),
      );
    });
  });

  group('parseStructure directly', () {
    test('a wrapped collection is read like a bare array', () async {
      final groups = await _import(_serviceReturning({
        'workouts': [_plannedWorkout()]
      }));
      expect(groups, hasLength(3));
    });

    test('minutes and hours are read as well as seconds', () {
      final groups = TrainingPeaksImportService.parseStructure({
        'structure': {
          'primaryIntensityMetric': 'percentOfFtp',
          'structure': [
            {
              'type': 'step',
              'steps': [
                {
                  'length': {'value': 12, 'unit': 'minute'},
                  'targets': [
                    {'minValue': 91, 'maxValue': 99}
                  ],
                },
              ],
            },
          ],
        },
      }, rider: _rider);

      expect(groups.single.stimuli.single.durationMin, 12);
    });

    test('absolute watts are taken as given rather than scaled by FTP', () {
      final groups = TrainingPeaksImportService.parseStructure({
        'structure': {
          'primaryIntensityMetric': 'watts',
          'structure': [
            {
              'type': 'step',
              'steps': [
                {
                  'length': {'value': 600, 'unit': 'second'},
                  'targets': [
                    {'minValue': 250, 'maxValue': 270}
                  ],
                },
              ],
            },
          ],
        },
      }, rider: _rider);

      expect(groups.single.stimuli.single.target.minValue, 250);
      expect(groups.single.stimuli.single.target.maxValue, 270);
    });
  });
}
