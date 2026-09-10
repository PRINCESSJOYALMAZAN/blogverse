class AppProfile {
  const AppProfile({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.coverUrl,
  });

  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? coverUrl;

  factory AppProfile.fromMap(Map<String, dynamic> map) {
    return AppProfile(
      id: map['id'] as String,
      email: (map['email'] ?? '') as String,
      name: map['name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      coverUrl: map['cover_url'] as String?,
    );
  }
}
