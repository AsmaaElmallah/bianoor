class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String? name;
  final String? photoUrl;

  /// The name to show the mother. Profiles created without a name store the email instead.
  String? get displayName {
    final n = name?.trim();
    if (n == null || n.isEmpty || n.contains('@')) return null;
    return n;
  }
}
