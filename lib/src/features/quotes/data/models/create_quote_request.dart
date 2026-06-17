import '../../../../core/network/api_client.dart';

class CreateQuoteRequest {
  const CreateQuoteRequest({
    required this.serviceId,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.requestDate,
    this.photos = const [],
  });

  final String serviceId;
  final String title;
  final String description;
  final String category;
  final String location;
  final String requestDate; // ISO date: "2024-01-15"
  final List<String> photos;

  JsonObject toJson() => {
        'serviceId': serviceId,
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'requestDate': requestDate,
        if (photos.isNotEmpty) 'photos': photos,
      };
}
