import 'package:tafeito_flutter/src/core/network/api_paths.dart';

class UserDto {
  const UserDto({
    required this.id,
    required this.name,
    required this.email,
    this.identification,
    this.pixKey,
    this.hourlyRate,
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

    String? resolveAvatar(dynamic raw) {
      final value = (raw ?? '').toString();
      if (value.isEmpty) return null;
      if (value.startsWith('http')) return value;
      return '${ApiPaths.mainBaseUrl}/uploads/avatars/$value';
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
      avatarUrl: resolveAvatar(json['avatarUrl']),
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
  final String? avatarUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;
}
