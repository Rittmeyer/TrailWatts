import 'auth_session_store.dart';

/// Everywhere that is not the web the app process survives the trip to the
/// browser and back, so memory is enough.
AuthSessionStore createAuthSessionStore() => InMemoryAuthSessionStore();
