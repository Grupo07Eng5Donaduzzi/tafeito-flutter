class QuoteDto {
  const QuoteDto({
    required this.id,
    required this.serviceName,
    required this.status,
    required this.createdAt,
    this.otherPartyName,
    this.description,
    this.proposedValue,
    this.estimatedHoursValue,
    this.serviceDate,
    this.location,
    this.photos = const [],
  });

  final String id;
  final String serviceName;
  final String status;
  final String createdAt;
  final String? otherPartyName;
  final String? description;
  final String? proposedValue;      // monetary amount (R$)
  final String? estimatedHoursValue; // estimated hours (for provider view)
  final String? serviceDate;
  final String? location;
  final List<String> photos;

  // From BudgetRequestDto (budget-requests endpoints)
  factory QuoteDto.fromBudgetRequest(Map<String, Object?> json) {
    final photosRaw = json['photos'];
    final photos = <String>[];
    if (photosRaw is List) {
      for (final p in photosRaw) {
        if (p is String) photos.add(p);
      }
    }

    return QuoteDto(
      id: json['id']?.toString() ?? '',
      serviceName: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt']?.toString() ?? '',
      description: json['description']?.toString(),
      location: json['location']?.toString(),
      serviceDate: json['requestDate']?.toString(),
      photos: photos,
    );
  }

  // From ProposalDto (proposals endpoints)
  factory QuoteDto.fromProposal(Map<String, Object?> json) {
    final budgetRequest = json['budgetRequest'];
    String serviceName;
    String? otherPartyName;
    String? description;

    if (budgetRequest is Map) {
      final service = budgetRequest['service'];
      final rawTitle = budgetRequest['title']?.toString() ?? '';
      serviceName = (service is Map
              ? (service['title'] ?? service['name'])?.toString()
              : null) ??
          (rawTitle.isNotEmpty ? rawTitle : 'Proposta');

      final client = budgetRequest['client'];
      final provider = budgetRequest['provider'];
      otherPartyName = (client is Map ? client['name']?.toString() : null) ??
          (provider is Map ? provider['name']?.toString() : null);
      description = budgetRequest['description']?.toString();
    } else {
      final reqId = json['requestId']?.toString() ?? '';
      serviceName =
          reqId.length >= 8 ? 'Proposta #${reqId.substring(0, 8)}' : 'Proposta';
    }

    // Monetary amount shown to the client (Recebidos)
    String? proposedValue;
    final rawAmount = json['amount'];
    if (rawAmount != null) {
      final val = double.tryParse(rawAmount.toString());
      if (val != null) proposedValue = val.toStringAsFixed(2);
    }

    // Estimated hours shown to the provider (Enviados)
    String? estimatedHoursValue;
    final rawHours = json['estimatedHours'];
    if (rawHours != null) {
      final val = double.tryParse(rawHours.toString());
      if (val != null) {
        estimatedHoursValue = val == val.roundToDouble()
            ? val.toInt().toString()
            : val.toStringAsFixed(1);
      }
    }

    return QuoteDto(
      id: json['id']?.toString() ?? '',
      serviceName: serviceName,
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt']?.toString() ?? '',
      proposedValue: proposedValue,
      estimatedHoursValue: estimatedHoursValue,
      otherPartyName: otherPartyName,
      description: description,
    );
  }
}
