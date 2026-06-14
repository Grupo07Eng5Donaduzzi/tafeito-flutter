import 'package:flutter/foundation.dart';

import '../../domain/models/payment_history_item.dart';
import '../../domain/repositories/profile_payments_repository.dart';

class ProfilePaymentsViewModel extends ChangeNotifier {
  ProfilePaymentsViewModel({
    required this.paymentsRepository,
  });

  final ProfilePaymentsRepository paymentsRepository;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<List<PaymentHistoryItem>> loadMyPayments() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      return await paymentsRepository.listMyPayments();
    } catch (e) {
      _errorMessage = e.toString();
      return const [];
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

