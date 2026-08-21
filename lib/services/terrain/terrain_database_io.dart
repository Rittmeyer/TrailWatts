import 'terrain_database.dart';

/// Native has no store yet: the app-documents directory needs a plugin this
/// project has not taken, and shipping a half-working one would be worse
/// than the in-memory index it already has. Documented in the README next
/// to the token-persistence decision.
TerrainDatabase createTerrainDatabase() => const NoTerrainDatabase();
