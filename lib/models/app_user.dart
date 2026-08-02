/// The signed-in identity, whether it came from Firebase Auth or the offline
/// demo login used when Firebase is not configured.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.isFirebaseUser,
  });

  final String uid;
  final String email;
  final bool isFirebaseUser;

  String get displayName => email.split('@').first;
}
