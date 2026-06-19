class QuoteDto {
  const QuoteDto({
    required this.id,
    required this.serviceName,
    required this.status,
    required this.createdAt,
    this.otherPartyName,
    this.otherPartyId,
    this.description,
    this.proposedValue,
    this.estimatedHoursValue,
    this.serviceDate,
    this.location,
    this.photos = const [],
    this.paymentId,
    this.qrCode,
    this.qrCodeBase64,
    this.ticketUrl,
    this.linkedChatId,
    this.serviceId,
  });

  final String id;
  final String serviceName;
  final String status;
  final String createdAt;
  final String? otherPartyName;
  final String? otherPartyId;
  final String? description;
  final String? proposedValue; // monetary amount (R$)
  final String? estimatedHoursValue; // estimated hours (for provider view)
  final String? serviceDate;
  final String? location;
  final List<String> photos;
  final String? paymentId;
  final String? qrCode;
  final String? qrCodeBase64;
  final String? ticketUrl;
  final String? linkedChatId;
  final String? serviceId;

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
    String? otherPartyId;
    String? description;
    String? serviceId;

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
      otherPartyId = _emptyToNull(
        (client is Map ? client['id'] : null) ??
            (provider is Map ? provider['id'] : null),
      );
      description = budgetRequest['description']?.toString();
      serviceId = _emptyToNull(
        (service is Map ? service['id'] : null) ??
            budgetRequest['serviceId'],
      );
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
      otherPartyId: otherPartyId,
      description: description,
      paymentId: _emptyToNull(json['paymentId']),
      qrCode: _emptyToNull(json['qrCode']),
      qrCodeBase64: _emptyToNull(json['qrCodeBase64']),
      ticketUrl: _emptyToNull(json['ticketUrl']),
      linkedChatId: _emptyToNull(json['linkedChatId']),
      serviceId: serviceId,
    );
  }
}

class PaymentCheckDto {
  const PaymentCheckDto({
    required this.paid,
    required this.status,
    required this.proposal,
    this.paymentId,
    this.qrCode,
    this.qrCodeBase64,
    this.ticketUrl,
  });

  final bool paid;
  final String status;
  final QuoteDto proposal;
  final String? paymentId;
  final String? qrCode;
  final String? qrCodeBase64;
  final String? ticketUrl;

  factory PaymentCheckDto.fromJson(Map<String, Object?> json) {
    final proposalJson = json['proposal'];
    final proposal = proposalJson is Map
        ? QuoteDto.fromProposal(
            proposalJson.map((key, value) => MapEntry(key.toString(), value)),
          )
        : QuoteDto(
            id: '',
            serviceName: 'Pagamento',
            status: json['status']?.toString() ?? '',
            createdAt: '',
          );

    return PaymentCheckDto(
      paid: json['paid'] == true,
      status: json['status']?.toString() ?? '',
      proposal: proposal,
      paymentId: _emptyToNull(json['paymentId']),
      qrCode: _emptyToNull(json['qrCode']),
      qrCodeBase64: _emptyToNull(json['qrCodeBase64']),
      ticketUrl: _emptyToNull(json['ticketUrl']),
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
