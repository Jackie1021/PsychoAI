class ChatParticipant {
  final String id;
  final String name;
  final String? avatar;
  final String? bio;

  ChatParticipant({
    required this.id,
    required this.name,
    this.avatar,
    this.bio,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'bio': bio,
    };
  }

  factory ChatParticipant.fromMap(Map<String, dynamic> map) {
    return ChatParticipant(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown',
      avatar: map['avatar'],
      bio: map['bio'],
    );
  }
}
