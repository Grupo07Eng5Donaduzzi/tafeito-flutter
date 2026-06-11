class ServiceDto {
  const ServiceDto({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    this.duration,
    this.imageUrl,
    this.rating,
    this.ratingCount,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String price;
  final String? duration;
  final String? imageUrl;
  final double? rating;
  final int? ratingCount;

  String get displayImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl!;
    }
    final cleanCategory = category.toLowerCase().trim();
    if (cleanCategory.contains('jard') || cleanCategory.contains('plant') || cleanCategory.contains('flor') || cleanCategory.contains('árvor')) {
      return 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?q=80&w=600';
    } else if (cleanCategory.contains('limp') || cleanCategory.contains('clean') || cleanCategory.contains('faxin')) {
      return 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=600';
    } else if (cleanCategory.contains('ref') || cleanCategory.contains('obr') || cleanCategory.contains('const') || cleanCategory.contains('pint')) {
      return 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?q=80&w=600';
    } else if (cleanCategory.contains('tec') || cleanCategory.contains('assist') || cleanCategory.contains('comput') || cleanCategory.contains('cel')) {
      return 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?q=80&w=600';
    } else {
      return 'https://images.unsplash.com/photo-1521791136368-1a9b8275f340?q=80&w=600';
    }
  }

  double get displayRating {
    if (rating != null) return rating!;
    final code = id.hashCode.abs() % 11;
    return 4.0 + (code / 10);
  }

  int get displayRatingCount {
    if (ratingCount != null) return ratingCount!;
    return (id.hashCode.abs() % 240) + 10;
  }

  factory ServiceDto.fromJson(Map<String, Object?> json) {
    return ServiceDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      duration: _emptyToNull(json['duration']),
      imageUrl: _emptyToNull(json['imageUrl'] ?? json['image_url']),
      rating: _toDouble(json['rating']),
      ratingCount: _toInt(json['ratingCount'] ?? json['rating_count']),
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

double? _toDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _toInt(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
