class UserModel {
  final String id;
  final String? phone;
  final String? displayName;
  final String? role;
  final String? avatarUrl;
  final String? avatarId;
  final bool? isActive;

  UserModel({
    required this.id,
    this.phone,
    this.displayName,
    this.role,
    this.avatarUrl,
    this.avatarId,
    this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Backend `pickUser` returns keys: _id, phone, displayName, role, avatarUrl, avatarId, isActive
    return UserModel(
      id: (json['_id'] ?? json['user_id'] ?? json['id']).toString(),
      phone: json['phone'] as String?,
      displayName:
          json['displayName'] as String? ?? json['full_name'] as String?,
      role: json['role'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      avatarId: json['avatarId'] as String? ?? json['avatar_id'] as String?,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'phone': phone,
    'displayName': displayName,
    'role': role,
    'avatarUrl': avatarUrl,
    'avatarId': avatarId,
    'isActive': isActive,
  };
}
