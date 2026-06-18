class ServiceDto {
  const ServiceDto({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    this.duration,
    this.unit,
    this.imageUrl,
    this.providerName,
    this.providerId,
    this.rating,
    this.reviewCount,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String price;
  final String? duration;
  final String? unit;
  final String? imageUrl;
  final String? providerName;
  final String? providerId;
  final String? rating;
  final String? reviewCount;

  factory ServiceDto.fromJson(Map<String, Object?> json) {
    final provider = json['provider'];
    String? providerName;
    String? providerId;
    if (provider is Map) {
      providerName = provider['name']?.toString();
      providerId = provider['id']?.toString();
    }

    return ServiceDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      duration: _emptyToNull(json['duration'] ?? json['pricingType']),
      unit: _unitFromPricingType(
        _emptyToNull(json['unit'] ?? json['duration'] ?? json['pricingType']),
      ),
      imageUrl: _toServicePhotoUrl(_emptyToNull(
        json['imageUrl'] ??
            json['image_url'] ??
            json['image'] ??
            json['photoUrl'] ??
            json['photo'],
      )),
      providerName: _emptyToNull(
        providerName ?? json['providerName'] ?? json['userName'],
      ),
      providerId: _emptyToNull(
        providerId ?? json['providerId'] ?? json['userId'] ?? json['user_id'],
      ),
      rating: _emptyToNull(
        json['rating'] ?? json['averageRating'] ?? json['ratingAverage'],
      ),
      reviewCount: _emptyToNull(
        json['reviewCount'] ?? json['review_count'] ?? json['reviewsCount'],
      ),
    );
  }
}

String? _toServicePhotoUrl(String? value) {
  if (value == null) return null;
  if (value.startsWith('http')) return value;
  return 'https://tafeito.rietto.com/main/uploads/services/$value';
}

String? _emptyToNull(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }

  return text;
}

String? _unitFromPricingType(String? value) {
  return switch (value?.toUpperCase()) {
    'HOURLY' => 'hora',
    'MONTHLY' => 'mês',
    'DAILY' => 'dia',
    _ => value,
  };
}
