import 'package:flutter/foundation.dart';
import '../models/platform_integration.dart';
import '../models/result_source.dart';

/// The rider's platform connections, shared across every screen that needs
/// to know whether Garmin, Strava or TrainingPeaks is connected: the
/// Integrations screen writes it, the workout builder's TrainingPeaks
/// import and the route export screen both read it.
///
/// This app has no backend of its own (see README - "demo data stands in
/// for the platform integrations"), so this store holds the connection
/// state in memory instead of driving it from a real OAuth callback. The
/// shape - `PlatformConnection` with a state, scopes and a connected-at
/// timestamp - is the one specs/002-platform-integration/spec.md defines,
/// so swapping this for a real persisted store later does not change any
/// caller.
class IntegrationsStore extends ChangeNotifier {
  IntegrationsStore._();
  static final IntegrationsStore instance = IntegrationsStore._();

  final Map<ResultSource, PlatformConnection> _connections = {};

  PlatformConnection? connectionFor(ResultSource platform) =>
      _connections[platform];

  bool isConnected(ResultSource platform) =>
      _connections[platform]?.state == PlatformConnectionState.connected;

  /// Article II: the connection only ever asks for read access to a single
  /// matching activity/workout, never a bulk history import.
  void connect(ResultSource platform) {
    _connections[platform] = PlatformConnection(
      platform: platform,
      state: PlatformConnectionState.connected,
      scopes: const ['activity:read', 'workout:read'],
      connectedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Disconnecting one platform MUST NOT affect the others (spec 002,
  /// Requirement 9) - this only ever touches its own map entry.
  void disconnect(ResultSource platform) {
    _connections.remove(platform);
    notifyListeners();
  }
}
