class UserTag {
  final String name;
  final bool isFavorite;
  final bool isBuiltin;

  UserTag({required this.name, this.isFavorite = false,this.isBuiltin = false,});

  factory UserTag.fromFirestore(String id, Map<String, dynamic> data) {
    return UserTag(
      name: id,
      isFavorite: data['favorite'] ?? false,
      isBuiltin: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'favorite': isFavorite,
    };
  }

  UserTag copyWith({String? name, bool? isFavorite, bool? isBuiltin}) {
    return UserTag(
      name: name ?? this.name,
      isFavorite: isFavorite ?? this.isFavorite,
      isBuiltin: isBuiltin ?? this.isBuiltin,
    );
  }
}
