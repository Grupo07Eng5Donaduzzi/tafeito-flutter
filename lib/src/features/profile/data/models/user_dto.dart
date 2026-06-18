class UserDto {
  const UserDto({
    required this.id,
    required this.name,
    required this.email,
    this.identification,
    this.pixKey,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return UserDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      identification: (json['identification'] ?? '').toString().isEmpty
          ? null
          : (json['identification'] ?? '').toString(),
      pixKey: (json['pixKey'] ?? '').toString().isEmpty
          ? null
          : (json['pixKey'] ?? '').toString(),
      avatarUrl: (json['avatarUrl'] ?? '').toString().isEmpty
          ? null
          : (json['avatarUrl'] ?? '').toString(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  final String id;
  final String name;
  final String email;

  final String? identification;
  final String? pixKey;
  final String? avatarUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;
}
