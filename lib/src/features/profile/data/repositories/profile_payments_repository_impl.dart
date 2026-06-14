import 'package:tafeito_flutter/src/core/session/session_manager.dart';

import '../../domain/models/payment_history_item.dart';
import '../../domain/repositories/profile_payments_repository.dart';
import '../datasources/profile_payments_remote_data_source.dart';

class ProfilePaymentsRepositoryImpl implements ProfilePaymentsRepository {
  ProfilePaymentsRepositoryImpl({
    required this.remoteDataSource,
    required this.sessionManager,
  });

  final ProfilePaymentsRemoteDataSource remoteDataSource;
  final SessionManager sessionManager;

  @override
  Future<List<PaymentHistoryItem>> listMyPayments() async {
    final clientId = sessionManager.session?.user.id;
    if (clientId == null) return const [];

    final proposals = await remoteDataSource.getClientPaymentHistory();

    final items = <PaymentHistoryItem>[];
    for (final p in proposals) {
      final status = p['status']?.toString() ?? '';
      if (status != 'COMPLETED') continue;

      final title = p['requestId'] != null
          ? 'Pagamento - ${p['requestId']}'
          : 'Pagamento';

      final amount = p['amount']?.toString() ?? '0';
      final createdAtString = p['createdAt']?.toString();
      final createdAt = createdAtString != null
          ? DateTime.tryParse(createdAtString)
          : null;
      final authorDate = createdAt != null
          ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}'
          : createdAtString ?? '';

      items.add(
        PaymentHistoryItem(
          title: title.trim(),
          authorDate: authorDate,
          amount: amount,
          status: status,
        ),
      );
    }

    return items;
  }
}

