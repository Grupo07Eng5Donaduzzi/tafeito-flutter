import '../../../../core/network/api_client.dart';

class CreateProposalRequest {
  const CreateProposalRequest({
    required this.requestId,
    required this.amount,
  });

  final String requestId;
  final double amount;

  JsonObject toJson() => {
        'requestId': requestId,
        'amount': amount,
      };
}

// Keep old name as alias so existing imports don't break
typedef RespondQuoteRequest = CreateProposalRequest;
