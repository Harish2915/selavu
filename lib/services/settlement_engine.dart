import '../models/expense_model.dart';
import '../models/member_model.dart';
import '../models/payment_model.dart';
import '../models/settlement_model.dart';

/// Reusable, Decimal-Safe Settlement Calculation Engine
/// Uses integer arithmetic (paise) to guarantee 100% precision with no floating-point inaccuracies
class SettlementEngine {
  /// Splits an expense equally among selected participants without losing single paise.
  /// Example: 1000 paise among 3 people -> 334, 333, 333 (Sum = 1000)
  static Map<String, int> calculateEqualSplit({
    required int totalAmountPaise,
    required List<String> participantMemberIds,
  }) {
    if (participantMemberIds.isEmpty || totalAmountPaise <= 0) {
      return {};
    }

    final int count = participantMemberIds.length;
    final int baseShare = totalAmountPaise ~/ count;
    final int remainder = totalAmountPaise % count;

    final Map<String, int> shares = {};
    for (int i = 0; i < count; i++) {
      final memberId = participantMemberIds[i];
      // Distribute the remainder 1 paise at a time to the first remainder members
      final int share = baseShare + (i < remainder ? 1 : 0);
      shares[memberId] = share;
    }

    return shares;
  }

  /// Validates if custom shares add up exactly to the total expense amount.
  static bool validateCustomSplit({
    required int totalAmountPaise,
    required Map<String, int> customShares,
  }) {
    final int sum = customShares.values.fold(0, (prev, curr) => prev + curr);
    return sum == totalAmountPaise;
  }

  /// Calculates the complete settlement breakdown for a trip
  static SettlementModel calculateSettlement({
    required String tripId,
    required List<MemberModel> members,
    required List<ExpenseModel> expenses,
    required List<PaymentModel> payments,
  }) {
    // 1. Calculate Total Trip Expense
    final int totalTripExpensePaise = expenses.fold(
      0,
      (sum, e) => sum + e.amountPaise,
    );

    // 2. Initialize tracking maps for each member
    final Map<String, int> paidExpenses = {};
    final Map<String, int> shareExpenses = {};
    final Map<String, int> directGiven = {};
    final Map<String, int> directReceived = {};

    for (final member in members) {
      paidExpenses[member.id] = 0;
      shareExpenses[member.id] = 0;
      directGiven[member.id] = 0;
      directReceived[member.id] = 0;
    }

    // 3. Accumulate paid expenses
    for (final expense in expenses) {
      if (paidExpenses.containsKey(expense.payerId)) {
        paidExpenses[expense.payerId] = paidExpenses[expense.payerId]! + expense.amountPaise;
      }

      // Accumulate individual consumed shares
      for (final share in expense.shares) {
        if (shareExpenses.containsKey(share.memberId)) {
          shareExpenses[share.memberId] =
              shareExpenses[share.memberId]! + share.sharePaise;
        }
      }
    }

    // 4. Accumulate direct payments (e.g. Arun gave You ₹500)
    for (final payment in payments) {
      if (directGiven.containsKey(payment.fromMemberId)) {
        directGiven[payment.fromMemberId] =
            directGiven[payment.fromMemberId]! + payment.amountPaise;
      }
      if (directReceived.containsKey(payment.toMemberId)) {
        directReceived[payment.toMemberId] =
            directReceived[payment.toMemberId]! + payment.amountPaise;
      }
    }

    // 5. Build member summaries
    final List<MemberSettlementSummary> summaries = [];
    final Map<String, MemberModel> memberMap = {for (final m in members) m.id: m};

    for (final member in members) {
      summaries.add(
        MemberSettlementSummary(
          member: member,
          paidExpensesPaise: paidExpenses[member.id] ?? 0,
          shareExpensesPaise: shareExpenses[member.id] ?? 0,
          directGivenPaise: directGiven[member.id] ?? 0,
          directReceivedPaise: directReceived[member.id] ?? 0,
        ),
      );
    }

    // 6. Simplify debts to compute minimal settlement transfers
    // Creditors (Net > 0: group owes them money, they receive)
    // Debtors (Net < 0: they owe money, they pay)
    final List<_DebtNode> creditors = [];
    final List<_DebtNode> debtors = [];

    for (final summary in summaries) {
      final net = summary.netBalancePaise;
      if (net > 0) {
        creditors.add(_DebtNode(memberId: summary.member.id, balance: net));
      } else if (net < 0) {
        debtors.add(_DebtNode(memberId: summary.member.id, balance: -net)); // positive debt
      }
    }

    // Sort to optimize settlement pairings
    creditors.sort((a, b) => b.balance.compareTo(a.balance));
    debtors.sort((a, b) => b.balance.compareTo(a.balance));

    final List<SettlementTransfer> transfers = [];
    int cIdx = 0;
    int dIdx = 0;

    while (cIdx < creditors.length && dIdx < debtors.length) {
      final creditor = creditors[cIdx];
      final debtor = debtors[dIdx];

      final int transferAmount = debtor.balance < creditor.balance
          ? debtor.balance
          : creditor.balance;

      if (transferAmount > 0) {
        final fromMember = memberMap[debtor.memberId];
        final toMember = memberMap[creditor.memberId];

        if (fromMember != null && toMember != null) {
          transfers.add(
            SettlementTransfer(
              fromMember: fromMember,
              toMember: toMember,
              amountPaise: transferAmount,
            ),
          );
        }
      }

      debtor.balance -= transferAmount;
      creditor.balance -= transferAmount;

      if (debtor.balance == 0) dIdx++;
      if (creditor.balance == 0) cIdx++;
    }

    return SettlementModel(
      tripId: tripId,
      totalTripExpensePaise: totalTripExpensePaise,
      memberSummaries: summaries,
      transfers: transfers,
    );
  }
}

class _DebtNode {
  final String memberId;
  int balance;

  _DebtNode({required this.memberId, required this.balance});
}
