enum AuthProvider { email, google, apple, microsoft }

/// Identity only. Passwords, refresh tokens and provider secrets never belong here.
class UserAccount {
  final String id;
  final String name;
  final String email;
  final DateTime birthDate;
  final AuthProvider authProvider;

  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.birthDate,
    this.authProvider = AuthProvider.email,
  });
}
