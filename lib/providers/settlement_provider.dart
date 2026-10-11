import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../models/member_model.dart';
import '../models/payment_model.dart';
import '../models/settlement_model.dart';
import '../services/settlement_engine.dart';

class SettlementProvider extends ChangeNotifier {
  SettlementModel? _settlement;
  bool _isCalculating = false;

  SettlementModel? get settlement => _settlement;
  bool get isCalculating => _isCalculating;

  /// Recalculates settlement based on the current trip's members, expenses, and payments
  void recalculateSettlement({
    required String tripId,
    required List<MemberModel> members,
    required List<ExpenseModel> expenses,
    required List<PaymentModel> payments,
  }) {
    _isCalculating = true;
    notifyListeners();

    _settlement = SettlementEngine.calculateSettlement(
      tripId: tripId,
      members: members,
      expenses: expenses,
      payments: payments,
    );

    _isCalculating = false;
    notifyListeners();
  }
}
