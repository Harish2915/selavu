import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/animations/fade_slide_transition.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../models/settlement_model.dart';
import '../../models/trip_model.dart';

class SettlementView extends StatelessWidget {
  final TripModel trip;
  final SettlementModel settlement;

  const SettlementView({
    super.key,
    required this.trip,
    required this.settlement,
  });

  void _copySummaryToClipboard(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('📋 *${trip.name} - Settlement Summary*');
    buffer.writeln('💰 Total Trip Spent: ${CurrencyFormatter.formatPaise(settlement.totalTripExpensePaise)}');
    buffer.writeln('');

    buffer.writeln('👥 *Individual Shares:*');
    for (final s in settlement.memberSummaries) {
      buffer.writeln('• ${s.member.name}: ${CurrencyFormatter.formatPaise(s.shareExpensesPaise)} (Paid: ${CurrencyFormatter.formatPaise(s.paidExpensesPaise)})');
    }
    buffer.writeln('');

    buffer.writeln('🤝 *Simplified Settlements (Who pays Whom):*');
    if (settlement.transfers.isEmpty) {
      buffer.writeln('All accounts are balanced! No pending payments.');
    } else {
      for (final t in settlement.transfers) {
        buffer.writeln('• ${t.fromMember.name} ➔ ${t.toMember.name}: ${CurrencyFormatter.formatPaise(t.amountPaise)}');
      }
    }
    buffer.writeln('');
    buffer.writeln('Tracked with Selavu App');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ToastUtils.showSuccess(context, 'Settlement summary copied to clipboard! 📋');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ownerSummary = settlement.getOwnerSummary();
    final int ownerNet = ownerSummary?.netBalancePaise ?? 0;
    final bool ownerReceives = ownerNet > 0;
    final bool ownerOwes = ownerNet < 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Outcome Card: "You should receive ₹..." or "You owe ₹..."
          FadeSlideTransition(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.space20),
              decoration: BoxDecoration(
                gradient: ownerReceives
                    ? const LinearGradient(
                        colors: [Color(0xFF00B894), Color(0xFF00A082)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : ownerOwes
                        ? const LinearGradient(
                            colors: [Color(0xFFFF4757), Color(0xFFE84118)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : colors.primaryGradient,
                borderRadius: AppDimensions.roundedXL,
                boxShadow: AppDimensions.softShadow(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ownerReceives
                            ? 'YOU SHOULD RECEIVE'
                            : ownerOwes
                                ? 'YOU NEED TO PAY'
                                : 'YOUR BALANCE',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: AppDimensions.roundedFull,
                        ),
                        child: Text(
                          trip.status.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ownerNet == 0
                        ? '₹0 (Settled)'
                        : CurrencyFormatter.formatPaise(ownerNet.abs()),
                    style: AppTypography.currencyHero.copyWith(
                      color: Colors.white,
                      fontSize: 38,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total Trip Expenditure: ${CurrencyFormatter.formatPaise(settlement.totalTripExpensePaise)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.space24),

          // 2. Simplified Settlements (Who pays Whom)
          FadeSlideTransition(
            delay: const Duration(milliseconds: 100),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Settlement Transfers',
                  style: AppTypography.titleLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _copySummaryToClipboard(context),
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('Share Summary'),
                  style: TextButton.styleFrom(foregroundColor: colors.primaryColor),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.space8),

          if (settlement.transfers.isEmpty)
            FadeSlideTransition(
              delay: const Duration(milliseconds: 150),
              child: AppCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_rounded, color: colors.successColor, size: 40),
                        const SizedBox(height: 8),
                        Text('Everything is already settled! 🎉',
                            style: AppTypography.titleLarge.copyWith(color: colors.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            ...settlement.transfers.map((t) {
              final bool involvesYou = t.toMember.isOwner || t.fromMember.isOwner;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.space10),
                child: AppCard(
                  border: involvesYou
                      ? Border.all(color: colors.primaryColor.withValues(alpha: 0.5), width: 1.5)
                      : null,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: colors.primaryColor.withValues(alpha: 0.12),
                        child: Icon(Icons.arrow_forward_rounded, color: colors.primaryColor, size: 20),
                      ),
                      const SizedBox(width: AppDimensions.space14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: t.fromMember.name,
                                    style: AppTypography.titleLarge.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' pays ',
                                    style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
                                  ),
                                  TextSpan(
                                    text: t.toMember.name,
                                    style: AppTypography.titleLarge.copyWith(
                                      color: colors.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              involvesYou ? 'Direct payment to settle balance' : 'Group member settlement',
                              style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatPaise(t.amountPaise),
                        style: AppTypography.currencyCard.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: AppDimensions.space24),

          // 3. Breakdown per person (Total Paid vs Consumed Share)
          FadeSlideTransition(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Individual Breakdown',
              style: AppTypography.titleLarge.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space12),

          AppCard(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text('Person', style: AppTypography.labelSmall.copyWith(color: colors.textSecondary)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Paid', textAlign: TextAlign.end, style: AppTypography.labelSmall.copyWith(color: colors.textSecondary)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Share', textAlign: TextAlign.end, style: AppTypography.labelSmall.copyWith(color: colors.textSecondary)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Net', textAlign: TextAlign.end, style: AppTypography.labelSmall.copyWith(color: colors.textSecondary)),
                    ),
                  ],
                ),
                const Divider(height: 20),
                ...settlement.memberSummaries.map((s) {
                  final net = s.netBalancePaise;
                  final isPos = net > 0;
                  final isNeg = net < 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            s.member.name,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            CurrencyFormatter.formatPaise(s.paidExpensesPaise),
                            textAlign: TextAlign.end,
                            style: AppTypography.bodySmall.copyWith(color: colors.textPrimary),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            CurrencyFormatter.formatPaise(s.shareExpensesPaise),
                            textAlign: TextAlign.end,
                            style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            net == 0
                                ? '₹0'
                                : '${isPos ? "+" : "-"}${CurrencyFormatter.formatPaise(net.abs())}',
                            textAlign: TextAlign.end,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isPos
                                  ? colors.successColor
                                  : isNeg
                                      ? colors.errorColor
                                      : colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.space32),

          // Share button
          AppButton(
            text: 'Copy & Share Summary',
            icon: Icons.copy_rounded,
            variant: ButtonVariant.primary,
            onPressed: () => _copySummaryToClipboard(context),
          ),
          const SizedBox(height: AppDimensions.space24),
        ],
      ),
    );
  }
}
