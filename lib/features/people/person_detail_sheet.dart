import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/member_model.dart';
import '../../models/payment_model.dart';
import '../../models/settlement_model.dart';
import '../../models/trip_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/payment_provider.dart';

class PersonDetailSheet extends StatelessWidget {
  final TripModel trip;
  final MemberModel member;
  final MemberSettlementSummary summary;

  const PersonDetailSheet({
    super.key,
    required this.trip,
    required this.member,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final expenseProvider = context.watch<ExpenseProvider>();
    final paymentProvider = context.watch<PaymentProvider>();

    // Expenses paid by this member
    final paidExpenses =
        expenseProvider.expenses.where((e) => e.payerId == member.id).toList();

    // Payments sent by this member
    final sentPayments =
        paymentProvider.payments.where((p) => p.fromMemberId == member.id).toList();

    // Payments received by this member
    final receivedPayments =
        paymentProvider.payments.where((p) => p.toMemberId == member.id).toList();

    final net = summary.netBalancePaise;
    final isPositive = net > 0;
    final isZero = net == 0;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppDimensions.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.borderColor,
                        borderRadius: AppDimensions.roundedFull,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Header with avatar & name
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: member.isOwner
                            ? colors.primaryColor
                            : colors.secondaryColor.withValues(alpha: 0.15),
                        child: Text(
                          member.name.substring(0, 1).toUpperCase(),
                          style: AppTypography.displayMedium.copyWith(
                            color: member.isOwner ? Colors.white : colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  member.name,
                                  style: AppTypography.headlineMedium.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (member.isOwner) ...[
                                  const SizedBox(width: 8),
                                  const StatusBadge(label: 'Trip Owner', type: BadgeType.active),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              trip.name,
                              style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.space20),

                  // Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: isZero
                          ? colors.surfaceColor
                          : isPositive
                              ? AppColors.successLight
                              : AppColors.errorLight,
                      borderRadius: AppDimensions.roundedLG,
                      border: Border.all(
                        color: isZero
                            ? colors.borderColor
                            : isPositive
                                ? AppColors.success.withValues(alpha: 0.3)
                                : AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isZero
                                  ? 'ACCOUNT SETTLED'
                                  : isPositive
                                      ? 'SHOULD RECEIVE'
                                      : 'OWES TO GROUP',
                              style: AppTypography.labelSmall.copyWith(
                                color: isZero
                                    ? colors.textSecondary
                                    : isPositive
                                        ? AppColors.success
                                        : AppColors.error,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isZero
                                  ? '₹0'
                                  : CurrencyFormatter.formatPaise(net.abs()),
                              style: AppTypography.currencyHero.copyWith(
                                color: isZero
                                    ? colors.textSecondary
                                    : isPositive
                                        ? AppColors.success
                                        : AppColors.error,
                                fontSize: 28,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          isZero
                              ? Icons.check_circle_rounded
                              : isPositive
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                          color: isZero
                              ? colors.textSecondary
                              : isPositive
                                  ? AppColors.success
                                  : AppColors.error,
                          size: 32,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.space20),

                  // Summary Breakdown Matrix
                  Text(
                    'Financial Summary',
                    style: AppTypography.titleLarge.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        _buildRow('Total Share Consumed', summary.shareExpensesPaise, colors),
                        const Divider(height: 16),
                        _buildRow('Amount Paid towards Expenses', summary.paidExpensesPaise, colors),
                        const Divider(height: 16),
                        _buildRow('Direct Money Given to Others', summary.directGivenPaise, colors),
                        const Divider(height: 16),
                        _buildRow('Direct Money Received from Others', summary.directReceivedPaise, colors),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.space24),

                  // Paid Expenses List
                  Text(
                    'Expenses Paid (${paidExpenses.length})',
                    style: AppTypography.titleLarge.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space10),
                  if (paidExpenses.isEmpty)
                    Text('No expenses paid by ${member.name}',
                        style: AppTypography.bodySmall.copyWith(color: colors.textSecondary))
                  else
                    ...paidExpenses.map((exp) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(exp.description, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                  Text(DateFormatter.formatFullDate(exp.expenseDate), style: AppTypography.bodySmall.copyWith(color: colors.textSecondary)),
                                ],
                              ),
                              Text(CurrencyFormatter.formatPaise(exp.amountPaise), style: AppTypography.currencyRegular),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: AppDimensions.space20),

                  // Direct Payments
                  if (sentPayments.isNotEmpty || receivedPayments.isNotEmpty) ...[
                    Text(
                      'Direct Transfers',
                      style: AppTypography.titleLarge.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space10),
                    ...sentPayments.map((p) => _buildTransferTile(p, isSent: true, colors: colors)),
                    ...receivedPayments.map((p) => _buildTransferTile(p, isSent: false, colors: colors)),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRow(String label, int paise, SelavuColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary)),
        Text(CurrencyFormatter.formatPaise(paise), style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: colors.textPrimary)),
      ],
    );
  }

  Widget _buildTransferTile(PaymentModel p, {required bool isSent, required SelavuColors colors}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isSent ? Icons.call_made_rounded : Icons.call_received_rounded,
                  color: isSent ? colors.errorColor : colors.successColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  isSent ? 'Sent to group member' : 'Received direct advance',
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Text(
              CurrencyFormatter.formatPaise(p.amountPaise),
              style: AppTypography.currencyRegular.copyWith(
                color: isSent ? colors.errorColor : colors.successColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
