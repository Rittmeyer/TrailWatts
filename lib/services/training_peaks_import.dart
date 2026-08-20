import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/rider_profile.dart';
import '../models/workout_block.dart';
import '../models/zone.dart';
import 'platform/oauth_tokens.dart';
import 'platform/platform_api_client.dart';
import 'platform/platform_credentials.dart';

/// Reads the rider's next planned workout back from TrainingPeaks, so the
/// builder can be pre-filled instead of typed out by hand.
///
/// Constitution Article II: this is a read of the planned workouts in one
/// short window - never a bulk import of the rider's whole TrainingPeaks
/// library.
///
/// TrainingPeaks' structured workouts map onto `WorkoutBlockGroup` almost
/// one-for-one, which is the whole reason the group exists: a `repetition`
/// entry with an interval step and a recovery step *is* "4x8min Z4 with 2min
/// easy" as one authored block, not eight blocks typed out.
///
/// The endpoint and field names below are PROVISIONAL in the same sense as
/// the rest of `services/platform/`: they follow the documented public shape
/// and must be verified before release. The parsing rules around them are
/// not provisional - a step this app cannot represent honestly is dropped,
/// never filled in with an invented target.
class TrainingPeaksImportService {
  final http.Client _client;
  final Duration timeout;

  TrainingPeaksImportService({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  /// The planned workouts between [from] and [days] later, as builder blocks.
  ///
  /// An empty list means TrainingPeaks has nothing structured planned in that
  /// window - which is a real answer, not a failure: the rider keeps the
  /// manual builder. Anything that genuinely went wrong throws
  /// [PlatformApiException] instead of quietly returning empty.
  Future<List<WorkoutBlockGroup>> importPreferredWorkout({
    required PlatformCredentials credentials,
    required OAuthTokens tokens,
    required RiderProfile rider,
    DateTime? from,
    int days = 7,
  }) async {
    final start = from ?? DateTime.now();
    final base = credentials.apiBaseUrl;
    final uri = base.replace(
      path: '${base.path}/workouts/planned',
      queryParameters: {
        'startDate': _day(start),
        'endDate': _day(start.add(Duration(days: days))),
      },
    );

    http.Response response;
    try {
      response = await _client.get(uri, headers: {
        'Authorization': 'Bearer ${tokens.accessToken}',
        'Accept': 'application/json',
      }).timeout(timeout);
    } catch (e) {
      throw PlatformApiException(PlatformApiFailure.network,
          detail: e.toString());
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw PlatformApiException(PlatformApiFailure.unauthorized,
          detail: 'HTTP ${response.statusCode}');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PlatformApiException(PlatformApiFailure.network,
          detail: 'HTTP ${response.statusCode}: ${response.body}');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      throw PlatformApiException(PlatformApiFailure.invalidResponse,
          detail: e.toString());
    }

    final workouts = switch (decoded) {
      List list => list,
      Map map when map['workouts'] is List => map['workouts'] as List,
      _ => throw const PlatformApiException(PlatformApiFailure.invalidResponse),
    };

    // The soonest planned workout is the "preferred" one to pre-fill with;
    // anything later is a different day's session.
    for (final workout in workouts) {
      if (workout is! Map) continue;
      final groups =
          parseStructure(workout.cast<String, dynamic>(), rider: rider);
      if (groups.isNotEmpty) return groups;
    }
    return const [];
  }

  /// Turns one TrainingPeaks workout into builder blocks.
  ///
  /// Exposed for tests: the parsing is where the real risk lives, and it is
  /// worth asserting on directly rather than only through a mocked round-trip.
  static List<WorkoutBlockGroup> parseStructure(
    Map<String, dynamic> workout, {
    required RiderProfile rider,
  }) {
    final structure = workout['structure'];
    if (structure is! Map) return const [];

    final entries = structure['structure'];
    if (entries is! List) return const [];

    // How the targets are expressed. Only power is supported: an HR-based
    // plan would need the rider's HR anchor to become absolute numbers, and
    // guessing one is exactly what Article II rules out.
    final metric = '${structure['primaryIntensityMetric'] ?? 'percentOfFtp'}';
    if (!_supportedMetrics.contains(metric)) return const [];

    final groups = <WorkoutBlockGroup>[];
    for (final entry in entries) {
      if (entry is! Map) continue;
      final steps = entry['steps'];
      if (steps is! List) continue;

      final stimuli = <WorkoutBlock>[];
      for (final step in steps) {
        if (step is! Map) continue;
        final block = _toBlock(step.cast<String, dynamic>(),
            rider: rider, metric: metric);
        // A step with no usable duration or target is dropped rather than
        // filled in: an invented target would be prescribed to the rider as
        // if TrainingPeaks had asked for it.
        if (block != null) stimuli.add(block);
      }
      if (stimuli.isEmpty) continue;

      groups.add(WorkoutBlockGroup(
        stimuli: stimuli,
        repeatCount: entry['type'] == 'repetition'
            ? (_toInt(_lengthValue(entry['length'])) ?? 1).clamp(1, 99)
            : 1,
      ));
    }
    return groups;
  }

  static const _supportedMetrics = {'percentOfFtp', 'watts'};

  static WorkoutBlock? _toBlock(
    Map<String, dynamic> step, {
    required RiderProfile rider,
    required String metric,
  }) {
    final durationMin = _durationMin(step['length']);
    // The block model is minute-resolution, so a step that rounds to zero
    // cannot be represented at all - dropping it is honest, rounding a 20s
    // effort up to a minute is not.
    if (durationMin == null || durationMin < 1) return null;

    final targets = step['targets'];
    if (targets is! List || targets.isEmpty) return null;
    final target = targets.first;
    if (target is! Map) return null;

    final min = _toWatts(target['minValue'], rider: rider, metric: metric);
    final max =
        _toWatts(target['maxValue'], rider: rider, metric: metric) ?? min;
    if (min == null || max == null) return null;

    // The zone comes from the middle of the prescribed range, which is the
    // effort actually being asked for - an edge would land on a neighbouring
    // zone whenever the range straddles a boundary.
    final zone = rider.zoneFor((min + max) / 2, ZoneMetric.power);
    if (zone == null) return null;

    return WorkoutBlock(
      role: _role('${step['intensityClass'] ?? ''}'),
      zone: zone,
      durationMin: durationMin,
      target: WorkoutTarget(
        metric: ZoneMetric.power,
        minValue: min,
        maxValue: max < min ? min : max,
      ),
    );
  }

  static WorkoutBlockRole _role(String intensityClass) =>
      switch (intensityClass.toLowerCase()) {
        'warmup' => WorkoutBlockRole.warmUp,
        'cooldown' => WorkoutBlockRole.coolDown,
        'rest' || 'recovery' => WorkoutBlockRole.recovery,
        // "active" and anything unrecognised read as work: a block that is
        // not explicitly recovery must not be treated as rest, or the
        // timeline would under-report the workout.
        _ => WorkoutBlockRole.work,
      };

  static int? _toWatts(
    Object? value, {
    required RiderProfile rider,
    required String metric,
  }) {
    final number = _toDouble(value);
    if (number == null) return null;
    return switch (metric) {
      'percentOfFtp' => (number / 100 * rider.ftpWatts).round(),
      _ => number.round(),
    };
  }

  static int? _durationMin(Object? length) {
    if (length is! Map) return null;
    final value = _toDouble(length['value']);
    if (value == null) return null;
    return switch ('${length['unit'] ?? 'second'}') {
      'minute' => value.round(),
      'hour' => (value * 60).round(),
      _ => (value / 60).round(),
    };
  }

  static Object? _lengthValue(Object? length) =>
      length is Map ? length['value'] : null;

  static int? _toInt(Object? value) => _toDouble(value)?.round();

  static double? _toDouble(Object? value) => switch (value) {
        num n => n.toDouble(),
        String s => double.tryParse(s),
        _ => null,
      };

  static String _day(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
