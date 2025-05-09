class UserTag {
  final String name;
  final bool isFavorite;

  UserTag({required this.name, this.isFavorite = false});

  factory UserTag.fromFirestore(String id, Map<String, dynamic> data) {
    return UserTag(
      name: id,
      isFavorite: data['favorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'favorite': isFavorite,
    };
  }

  UserTag copyWith({String? name, bool? isFavorite}) {
    return UserTag(
      name: name ?? this.name,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
