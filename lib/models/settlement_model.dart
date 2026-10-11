import 'member_model.dart';

class MemberSettlementSummary {
  final MemberModel member;
  final int paidExpensesPaise; // How much this person paid for expenses
  final int shareExpensesPaise; // How much this person consumed / owes for expenses
  final int directGivenPaise; // How much this person directly transferred to others
  final int directReceivedPaise; // How much this person directly received from others

  const MemberSettlementSummary({
    required this.member,
    required this.paidExpensesPaise,
    required this.shareExpensesPaise,
    required this.directGivenPaise,
    required this.directReceivedPaise,
  });

  /// Net balance in paise:
  /// (Total Outflow: Paid for group + Transferred to others) - (Total Inflow/Debt: Consumed share + Received direct money)
  /// Positive: Group owes this member (member should receive money)
  /// Negative: Member owes the group (member should pay money)
  int get netBalancePaise =>
      (paidExpensesPaise + directGivenPaise) -
      (shareExpensesPaise + directReceivedPaise);

  double get paidExpensesRupees => paidExpensesPaise / 100.0;
  double get shareExpensesRupees => shareExpensesPaise / 100.0;
  double get directGivenRupees => directGivenPaise / 100.0;
  double get directReceivedRupees => directReceivedPaise / 100.0;
  double get netBalanceRupees => netBalancePaise / 100.0;

  bool get shouldReceive => netBalancePaise > 0;
  bool get owes => netBalancePaise < 0;
  bool get isSettled => netBalancePaise == 0;
}

class SettlementTransfer {
  final MemberModel fromMember; // Person who owes and sends money
  final MemberModel toMember; // Person who is owed and receives money
  final int amountPaise;

  const SettlementTransfer({
    required this.fromMember,
    required this.toMember,
    required this.amountPaise,
  });

  double get amountRupees => amountPaise / 100.0;
}

class SettlementModel {
  final String tripId;
  final int totalTripExpensePaise;
  final List<MemberSettlementSummary> memberSummaries;
  final List<SettlementTransfer> transfers;

  const SettlementModel({
    required this.tripId,
    required this.totalTripExpensePaise,
    required this.memberSummaries,
    required this.transfers,
  });

  double get totalTripExpenseRupees => totalTripExpensePaise / 100.0;

  MemberSettlementSummary? getOwnerSummary() {
    try {
      return memberSummaries.firstWhere((s) => s.member.isOwner);
    } catch (_) {
      return memberSummaries.isNotEmpty ? memberSummaries.first : null;
    }
  }

  /// Transfers where the current user/owner is the recipient
  List<SettlementTransfer> getTransfersToOwner() {
    final ownerSummary = getOwnerSummary();
    if (ownerSummary == null) return [];
    return transfers.where((t) => t.toMember.id == ownerSummary.member.id).toList();
  }

  /// Transfers where the current user/owner must pay someone
  List<SettlementTransfer> getTransfersFromOwner() {
    final ownerSummary = getOwnerSummary();
    if (ownerSummary == null) return [];
    return transfers.where((t) => t.fromMember.id == ownerSummary.member.id).toList();
  }
}
