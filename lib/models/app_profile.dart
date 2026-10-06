class AppProfile {
  const AppProfile({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.bio,
    this.course,
    this.location,
    this.joinedYear,
  });

  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? bio;
  final String? course;
  final String? location;
  final int? joinedYear;

  factory AppProfile.fromMap(Map<String, dynamic> map) {
    return AppProfile(
      id: map['id'] as String,
      email: (map['email'] ?? '') as String,
      name: map['name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      course: map['course'] as String?,
      location: map['location'] as String?,
      joinedYear: (map['joined_year'] as num?)?.toInt(),
    );
  }
}
