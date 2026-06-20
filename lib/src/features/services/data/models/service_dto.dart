class ReviewDto {
  const ReviewDto({
    required this.id,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  final String id;
  final int rating;
  final String? comment;
  final String createdAt;

  factory ReviewDto.fromJson(Map<String, Object?> json) {
    return ReviewDto(
      id: json['id']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: _emptyToNull(json['comment']),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

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
    this.reviews = const [],
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
  final List<ReviewDto> reviews;

  factory ServiceDto.fromJson(Map<String, Object?> json) {
    final provider = json['provider'];
    String? providerName;
    String? providerId;
    if (provider is Map) {
      providerName = provider['name']?.toString();
      providerId = provider['id']?.toString();
    }

    // Parse reviews block (from findByIdWithDetails response)
    String? rating = _emptyToNull(
      json['rating'] ?? json['averageRating'] ?? json['ratingAverage'],
    );
    String? reviewCount = _emptyToNull(
      json['reviewCount'] ?? json['review_count'] ?? json['reviewsCount'],
    );
    List<ReviewDto> reviews = const [];

    final reviewsBlock = json['reviews'];
    if (reviewsBlock is Map) {
      final avg = reviewsBlock['average'];
      final total = reviewsBlock['total'];
      if (avg != null) rating = _emptyToNull(avg);
      if (total != null) reviewCount = _emptyToNull(total);

      final dataList = reviewsBlock['data'];
      if (dataList is List) {
        reviews = dataList
            .whereType<Map>()
            .map((r) => ReviewDto.fromJson(
                  r.map((k, v) => MapEntry(k.toString(), v)),
                ))
            .toList();
      }
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
      imageUrl: _emptyToNull(
        json['imageUrl'] ??
            json['image_url'] ??
            json['image'] ??
            json['photoUrl'] ??
            json['photo'],
      ),
      providerName: _emptyToNull(
        providerName ?? json['providerName'] ?? json['userName'],
      ),
      providerId: _emptyToNull(
        providerId ?? json['providerId'] ?? json['userId'] ?? json['user_id'],
      ),
      rating: rating,
      reviewCount: reviewCount,
      reviews: reviews,
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

String? _unitFromPricingType(String? value) {
  return switch (value?.toUpperCase()) {
    'HOURLY' => 'hora',
    'MONTHLY' => 'mes',
    'DAILY' => 'dia',
    _ => value,
  };
}
