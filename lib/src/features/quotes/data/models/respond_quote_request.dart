import '../../../../core/network/api_client.dart';

class CreateProposalRequest {
  const CreateProposalRequest({
    required this.requestId,
    required this.estimatedHours,
  });

  final String requestId;
  final double estimatedHours;

  JsonObject toJson() => {
        'requestId': requestId,
        'estimatedHours': estimatedHours,
      };
}

// Keep old name as alias so existing imports don't break
typedef RespondQuoteRequest = CreateProposalRequest;
