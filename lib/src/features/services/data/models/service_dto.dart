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

  String get providerName {
    if (name.toLowerCase().contains('plantio')) {
      return 'Ana Lima';
    }
    final names = ['Ana Lima', 'Carlos Souza', 'Bruno Alves', 'Mariana Costa', 'Daniela Reis', 'Eduardo Lima'];
    final index = id.hashCode.abs() % names.length;
    return names[index];
  }

  String get providerAvatarUrl {
    if (name.toLowerCase().contains('plantio')) {
      return 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=150';
    }
    final avatars = [
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=150',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=150',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=150',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=150',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=150',
      'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?q=80&w=150',
    ];
    final index = id.hashCode.abs() % avatars.length;
    return avatars[index];
  }

  String get displayReviewText {
    if (name.toLowerCase().contains('plantio')) {
      return 'Excelente profissional! Muito caprichoso e dedicado no plantio das flores e plantas. O serviço ficou lindo, organizado e deu outra vida ao jardim. Recomendo para quem procura alguém de confiança e que realmente gosta do que faz.';
    }
    final reviews = [
      'Excelente profissional! Muito rápido e caprichoso. O serviço ficou impecável, organizado e super limpo. Recomendo com certeza!',
      'Muito atencioso e prestativo. Realizou todo o trabalho dentro do prazo combinado com muita qualidade. Nota 10!',
      'Serviço muito bem feito e com preço justo. Comunicação fácil e transparente. Recomendo a todos!',
    ];
    return reviews[id.hashCode.abs() % reviews.length];
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
