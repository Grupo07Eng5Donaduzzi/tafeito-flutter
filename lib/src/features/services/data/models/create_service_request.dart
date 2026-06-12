import '../../../../core/network/api_client.dart';

class CreateServiceRequest {
  const CreateServiceRequest({
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    this.duration = 'dia',
  });

  final String name;
  final String description;
  final String category;
  final String price;
  final String duration;

  JsonObject toJson() => {
        'name': name,
        'description': description,
        'category': category,
        'price': price,
      };
}
