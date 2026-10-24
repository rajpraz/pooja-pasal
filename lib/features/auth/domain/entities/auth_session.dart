/// Who is signed in: just enough to address the user's own resources.
/// The full profile (role, phone, …) is [AppUser], loaded from the API.
class AuthSession {
  final String uid;
  final String email;

  const AuthSession({required this.uid, required this.email});
}
