import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/payment_model.dart';
import '../services/preferences_service.dart';
import '../services/supabase_service.dart';

class PaymentRepository {
  final PreferencesService _prefs;
  final _uuid = const Uuid();

  PaymentRepository(this._prefs);

  /// Gets all direct payments for a trip
  Future<List<PaymentModel>> getPayments(String tripId) async {
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      try {
        final client = SupabaseService.client!;
        final rows = await client
            .from(AppConstants.tablePayments)
            .select()
            .eq('trip_id', tripId)
            .order('payment_date', ascending: false);

        final payments = (rows as List)
            .map((p) => PaymentModel.fromJson(p as Map<String, dynamic>))
            .toList();

        await _prefs.saveLocalPayments(
          tripId,
          payments.map((p) => p.toJson()).toList(),
        );

        return payments;
      } catch (_) {
        return _getLocalPayments(tripId);
      }
    } else {
      return _getLocalPayments(tripId);
    }
  }

  List<PaymentModel> _getLocalPayments(String tripId) {
    final cached = _prefs.getLocalPayments(tripId);
    return cached.map((p) => PaymentModel.fromJson(p)).toList();
  }

  /// Adds a new direct payment
  Future<PaymentModel> addPayment({
    required String tripId,
    required String fromMemberId,
    required String toMemberId,
    required int amountPaise,
    required DateTime paymentDate,
    String? notes,
  }) async {
    final paymentId = _uuid.v4();
    final now = DateTime.now();

    final payment = PaymentModel(
      id: paymentId,
      tripId: tripId,
      fromMemberId: fromMemberId,
      toMemberId: toMemberId,
      amountPaise: amountPaise,
      paymentDate: paymentDate,
      notes: notes?.trim(),
      createdAt: now,
      updatedAt: now,
    );

    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      try {
        await SupabaseService.client!
            .from(AppConstants.tablePayments)
            .insert(payment.toJson());
      } catch (_) {}
    }

    final localList = _prefs.getLocalPayments(tripId);
    localList.insert(0, payment.toJson());
    await _prefs.saveLocalPayments(tripId, localList);

    return payment;
  }

  /// Updates an existing payment
  Future<PaymentModel> updatePayment({
    required String paymentId,
    required String tripId,
    required String fromMemberId,
    required String toMemberId,
    required int amountPaise,
    required DateTime paymentDate,
    String? notes,
  }) async {
    final now = DateTime.now();
    final updated = PaymentModel(
      id: paymentId,
      tripId: tripId,
      fromMemberId: fromMemberId,
      toMemberId: toMemberId,
      amountPaise: amountPaise,
      paymentDate: paymentDate,
      notes: notes?.trim(),
      createdAt: now,
      updatedAt: now,
    );

    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      try {
        await SupabaseService.client!
            .from(AppConstants.tablePayments)
            .update(updated.toJson())
            .eq('id', paymentId);
      } catch (_) {}
    }

    final localList = _prefs.getLocalPayments(tripId);
    for (int i = 0; i < localList.length; i++) {
      if (localList[i]['id'] == paymentId) {
        localList[i] = updated.toJson();
        break;
      }
    }
    await _prefs.saveLocalPayments(tripId, localList);

    return updated;
  }

  /// Deletes a payment
  Future<void> deletePayment({
    required String tripId,
    required String paymentId,
  }) async {
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      try {
        await SupabaseService.client!
            .from(AppConstants.tablePayments)
            .delete()
            .eq('id', paymentId);
      } catch (_) {}
    }

    final localList = _prefs.getLocalPayments(tripId);
    localList.removeWhere((p) => p['id'] == paymentId);
    await _prefs.saveLocalPayments(tripId, localList);
  }
}
