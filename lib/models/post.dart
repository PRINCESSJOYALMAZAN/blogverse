class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.imageUrls,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final List<String> imageUrls;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatarUrl;

  factory Post.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'];
    final profileMap = profile is Map ? Map<String, dynamic>.from(profile) : {};
    return Post(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      imageUrls: List<String>.from(map['image_urls'] ?? const []),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      authorName: profileMap['name'] as String?,
      authorAvatarUrl: profileMap['avatar_url'] as String?,
    );
  }
}
