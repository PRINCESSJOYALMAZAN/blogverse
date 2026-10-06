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
    this.reactionCounts = const {},
    this.myReaction,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final List<String> imageUrls;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatarUrl;
  final Map<String, int> reactionCounts;
  final String? myReaction;

  int get totalReactions =>
      reactionCounts.values.fold(0, (total, count) => total + count);

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
      reactionCounts: Map<String, int>.from(
        (map['reaction_counts'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), (value as num).toInt()),
            ) ??
            const {},
      ),
      myReaction: map['my_reaction'] as String?,
    );
  }
}
