class UserDto {
  const UserDto({
    required this.id,
    required this.name,
    required this.email,
    this.identification,
    this.pixKey,
    this.hourlyRate,
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
      hourlyRate: json['hourlyRate'] == null
          ? null
          : (json['hourlyRate'] as num).toDouble(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  final String id;
  final String name;
  final String email;

  final String? identification;
  final String? pixKey;
  final double? hourlyRate;

  final DateTime? createdAt;
  final DateTime? updatedAt;
}
