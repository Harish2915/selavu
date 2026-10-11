import 'package:flutter/foundation.dart';
import '../models/payment_model.dart';
import '../repositories/payment_repository.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentRepository _repository;

  List<PaymentModel> _payments = [];
  bool _isLoading = false;
  String? _errorMessage;

  PaymentProvider(this._repository);

  List<PaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Loads payments for a trip
  Future<void> loadPayments(String tripId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _payments = await _repository.getPayments(tripId);
    } catch (e) {
      _errorMessage = "Couldn't load payments.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new direct payment
  Future<PaymentModel?> addPayment({
    required String tripId,
    required String fromMemberId,
    required String toMemberId,
    required int amountPaise,
    required DateTime paymentDate,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payment = await _repository.addPayment(
        tripId: tripId,
        fromMemberId: fromMemberId,
        toMemberId: toMemberId,
        amountPaise: amountPaise,
        paymentDate: paymentDate,
        notes: notes,
      );
      _payments.insert(0, payment);
      return payment;
    } catch (e) {
      _errorMessage = "Couldn't record payment.";
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates an existing payment
  Future<PaymentModel?> updatePayment({
    required String paymentId,
    required String tripId,
    required String fromMemberId,
    required String toMemberId,
    required int amountPaise,
    required DateTime paymentDate,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updatePayment(
        paymentId: paymentId,
        tripId: tripId,
        fromMemberId: fromMemberId,
        toMemberId: toMemberId,
        amountPaise: amountPaise,
        paymentDate: paymentDate,
        notes: notes,
      );

      final index = _payments.indexWhere((p) => p.id == paymentId);
      if (index != -1) {
        _payments[index] = updated;
      }
      return updated;
    } catch (e) {
      _errorMessage = "Couldn't update payment.";
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes a payment
  Future<bool> deletePayment({
    required String tripId,
    required String paymentId,
  }) async {
    try {
      await _repository.deletePayment(tripId: tripId, paymentId: paymentId);
      _payments.removeWhere((p) => p.id == paymentId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Couldn't delete payment.";
      notifyListeners();
      return false;
    }
  }
}
