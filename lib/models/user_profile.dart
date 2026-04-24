class UserProfile {
  const UserProfile({
    this.id,
    required this.email,
    required this.displayName,
    this.photoPath,
    required this.preferredCurrency,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String email;
  final String displayName;
  final String? photoPath;
  final String preferredCurrency;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile copyWith({
    int? id,
    String? email,
    String? displayName,
    String? photoPath,
    bool clearPhotoPath = false,
    String? preferredCurrency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoPath: clearPhotoPath ? null : photoPath ?? this.photoPath,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'photo_path': photoPath,
      'preferred_currency': preferredCurrency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      email: map['email'] as String,
      displayName: map['display_name'] as String,
      photoPath: map['photo_path'] as String?,
      preferredCurrency: map['preferred_currency'] as String? ?? 'USD',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
