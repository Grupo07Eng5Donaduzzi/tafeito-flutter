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
    this.serviceId,
    this.invoiceFile,
    this.clientId,
    this.clientName,
    this.providerId,
    this.providerName,
  });

  final String id;
  final String serviceName;
  final String status;
  final String createdAt;
  final String? otherPartyName;
  final String? otherPartyId;
  final String? description;
  final String? proposedValue;
  final String? estimatedHoursValue;
  final String? serviceDate;
  final String? location;
  final List<String> photos;
  final String? paymentId;
  final String? qrCode;
  final String? qrCodeBase64;
  final String? ticketUrl;
  final String? serviceId;
  final String? invoiceFile;
  final String? clientId;
  final String? clientName;
  final String? providerId;
  final String? providerName;

  String? partyIdFor({
    required bool isProvider,
    String? currentUserId,
  }) {
    final current = _emptyToNull(currentUserId);
    if (current != null) {
      if (current == clientId) return providerId ?? otherPartyId;
      if (current == providerId) return clientId ?? otherPartyId;
    }

    return isProvider
        ? (clientId ?? otherPartyId)
        : (providerId ?? otherPartyId);
  }

  String partyNameFor({required bool isProvider}) {
    return (isProvider ? clientName : providerName) ??
        otherPartyName ??
        (isProvider ? 'Cliente' : 'Prestador');
  }

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

  factory QuoteDto.fromProposal(Map<String, Object?> json) {
    final budgetRequest = json['budgetRequest'];
    String serviceName;
    String? otherPartyName;
    String? otherPartyId;
    String? description;
    String? serviceId;
    String? clientId;
    String? clientName;
    String? providerId;
    String? providerName;

    if (budgetRequest is Map) {
      final service = budgetRequest['service'];
      final rawTitle = budgetRequest['title']?.toString() ?? '';
      serviceName = (service is Map
              ? (service['title'] ?? service['name'])?.toString()
              : null) ??
          (rawTitle.isNotEmpty ? rawTitle : 'Proposta');

      final client = budgetRequest['client'];
      final provider = budgetRequest['provider'];
      final serviceProvider = service is Map ? service['provider'] : null;
      clientId = _emptyToNull(
        budgetRequest['clientId'] ?? (client is Map ? client['id'] : null),
      );
      clientName = _emptyToNull(client is Map ? client['name'] : null);
      providerId = _emptyToNull(
        json['providerId'] ??
            budgetRequest['providerId'] ??
            (provider is Map ? provider['id'] : null) ??
            (service is Map ? service['providerId'] : null) ??
            (serviceProvider is Map ? serviceProvider['id'] : null),
      );
      providerName = _emptyToNull(
        (provider is Map ? provider['name'] : null) ??
            (serviceProvider is Map ? serviceProvider['name'] : null),
      );
      otherPartyName = clientName ?? providerName;
      otherPartyId = _emptyToNull(
        clientId ?? providerId,
      );
      description = budgetRequest['description']?.toString();
      serviceId = _emptyToNull(
        (service is Map ? service['id'] : null) ?? budgetRequest['serviceId'],
      );
    } else {
      final reqId = json['requestId']?.toString() ?? '';
      serviceName =
          reqId.length >= 8 ? 'Proposta #${reqId.substring(0, 8)}' : 'Proposta';
    }

    final proposalClient = json['client'];
    final proposalProvider = json['provider'];
    clientId ??= _emptyToNull(
      json['clientId'] ?? (proposalClient is Map ? proposalClient['id'] : null),
    );
    clientName ??= _emptyToNull(
      proposalClient is Map ? proposalClient['name'] : null,
    );
    providerId ??= _emptyToNull(
      json['providerId'] ??
          (proposalProvider is Map ? proposalProvider['id'] : null),
    );
    providerName ??= _emptyToNull(
      proposalProvider is Map ? proposalProvider['name'] : null,
    );
    otherPartyName ??= clientName ?? providerName;
    otherPartyId ??= clientId ?? providerId;

    String? proposedValue;
    final rawAmount = json['amount'];
    if (rawAmount != null) {
      final val = double.tryParse(rawAmount.toString());
      if (val != null) proposedValue = val.toStringAsFixed(2);
    }

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
      serviceId: serviceId,
      invoiceFile: _emptyToNull(json['invoiceFile']),
      clientId: clientId,
      clientName: clientName,
      providerId: providerId,
      providerName: providerName,
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

class ContestResponseDto {
  const ContestResponseDto({
    required this.proposal,
    required this.conversationId,
    required this.isNew,
  });

  final QuoteDto proposal;
  final String conversationId;
  final bool isNew;

  factory ContestResponseDto.fromJson(Map<String, Object?> json) {
    final proposalJson = json['proposal'];
    return ContestResponseDto(
      proposal: proposalJson is Map
          ? QuoteDto.fromProposal(
              proposalJson.map((k, v) => MapEntry(k.toString(), v)),
            )
          : const QuoteDto(
              id: '', serviceName: '', status: 'NEGOTIATING', createdAt: ''),
      conversationId: json['conversationId']?.toString() ?? '',
      isNew: json['isNew'] == true,
    );
  }
}

class ReviseResponseDto {
  const ReviseResponseDto({
    required this.proposal,
    required this.conversationId,
  });

  final QuoteDto proposal;
  final String conversationId;

  factory ReviseResponseDto.fromJson(Map<String, Object?> json) {
    final proposalJson = json['proposal'];
    return ReviseResponseDto(
      proposal: proposalJson is Map
          ? QuoteDto.fromProposal(
              proposalJson.map((k, v) => MapEntry(k.toString(), v)),
            )
          : const QuoteDto(
              id: '', serviceName: '', status: 'PENDING', createdAt: ''),
      conversationId: json['conversationId']?.toString() ?? '',
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
