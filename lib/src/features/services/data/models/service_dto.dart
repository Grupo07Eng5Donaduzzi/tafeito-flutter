class ServiceDto {
  const ServiceDto({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.providerId,
    this.pricingType,
    this.photo,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String price;
  final String providerId;
  final String? pricingType;
  final String? photo;

  factory ServiceDto.fromJson(Map<String, Object?> json) {
    return ServiceDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      providerId: (json['userId'] ?? json['user_id'])?.toString() ?? '',
      pricingType:
          _emptyToNull(json['pricingType'] ?? json['pricing_type']),
      photo: _emptyToNull(json['photo']),
    );
  }

  ServiceDto copyWith({
    String? name,
    String? description,
    String? category,
    String? price,
    String? pricingType,
  }) {
    return ServiceDto(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      providerId: providerId,
      pricingType: pricingType ?? this.pricingType,
      photo: photo,
    );
  }
}

String? _emptyToNull(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }

  return text;
}
