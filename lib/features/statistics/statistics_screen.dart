import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/fade_slide_transition.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../providers/expense_provider.dart';
import '../../providers/trip_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tripProvider = context.watch<TripProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();

    final trips = tripProvider.trips;
    final expenses = expenseProvider.expenses;
    final totalSpentPaise = expenseProvider.totalSpendingPaise;
    final categoryMap = expenseProvider.categorySpendingPaise;
    final mostUsedCat = expenseProvider.mostUsedCategory;

    final avgTripSpentPaise = trips.isNotEmpty
        ? (totalSpentPaise ~/ trips.length)
        : 0;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Expense Analytics',
          style: AppTypography.headlineLarge.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: expenses.isEmpty
            ? EmptyStateView(
                icon: Icons.pie_chart_outline_rounded,
                title: 'No expense analytics yet',
                description:
                    'Record expenses across trips to see visual charts and insights.',
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Overview Metric Cards
                    FadeSlideTransition(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: 'TOTAL SPENT',
                              value: CurrencyFormatter.formatPaise(
                                totalSpentPaise,
                              ),
                              icon: Icons.payments_rounded,
                              color: colors.primaryColor,
                              colors: colors,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'AVG PER TRIP',
                              value: CurrencyFormatter.formatPaise(
                                avgTripSpentPaise,
                              ),
                              icon: Icons.trending_up_rounded,
                              color: const Color(0xFF10AC84),
                              colors: colors,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimensions.space12),

                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 60),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colors.primaryColor.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: AppDimensions.roundedMD,
                              ),
                              child: Icon(
                                Icons.star_rounded,
                                color: colors.primaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Top Expense Category',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    mostUsedCat,
                                    style: AppTypography.titleLarge.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              categoryMap[mostUsedCat] != null
                                  ? CurrencyFormatter.formatPaise(
                                      categoryMap[mostUsedCat]!,
                                    )
                                  : '₹0',
                              style: AppTypography.titleLarge.copyWith(
                                color: colors.primaryColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimensions.space24),

                    // 2. Spending by Category (Interactive Donut Chart)
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 120),
                      child: Text(
                        'Spending by Category',
                        style: AppTypography.titleLarge.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space12),

                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 160),
                      child: AppCard(
                        padding: const EdgeInsets.all(AppDimensions.space20),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 220,
                              child: PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback: (event, pieTouchResponse) {
                                      setState(() {
                                        if (!event
                                                .isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection ==
                                                null) {
                                          _touchedPieIndex = -1;
                                          return;
                                        }
                                        _touchedPieIndex = pieTouchResponse
                                            .touchedSection!
                                            .touchedSectionIndex;
                                      });
                                    },
                                  ),
                                  borderData: FlBorderData(show: false),
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 50,
                                  sections: _buildCategoryPieSections(
                                    categoryMap,
                                    totalSpentPaise,
                                    colors,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppDimensions.space16),
                            const Divider(),
                            const SizedBox(height: AppDimensions.space12),
                            // Category breakdown legend
                            ...categoryMap.entries.map((entry) {
                              final catColor = _getCategoryColor(entry.key);
                              final double percent = totalSpentPaise > 0
                                  ? (entry.value / totalSpentPaise) * 100
                                  : 0.0;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: catColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colors.textPrimary,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      '${percent.toStringAsFixed(1)}%',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      CurrencyFormatter.formatPaise(
                                        entry.value,
                                      ),
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimensions.space24),

                    // 3. Trip Summary
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        'Trips Monitored (${trips.length})',
                        style: AppTypography.titleLarge.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space12),

                    ...trips.map((trip) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppDimensions.space10,
                        ),
                        child: AppCard(
                          padding: const EdgeInsets.all(AppDimensions.space14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trip.name,
                                    style: AppTypography.titleMedium.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${trip.members.length} members • ${trip.status}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                trip.isActive
                                    ? Icons.flight_takeoff_rounded
                                    : Icons.check_circle_rounded,
                                color: trip.isActive
                                    ? colors.primaryColor
                                    : Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: AppDimensions.space24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required SelavuColors colors,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.currencyCard.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildCategoryPieSections(
    Map<String, int> categoryMap,
    int totalSpentPaise,
    SelavuColors colors,
  ) {
    int index = 0;
    return categoryMap.entries.map((entry) {
      final isTouched = index == _touchedPieIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 65.0 : 55.0;
      final color = _getCategoryColor(entry.key);
      index++;

      final double percent = totalSpentPaise > 0
          ? (entry.value / totalSpentPaise) * 100
          : 0.0;

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: percent >= 8 ? '${percent.toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'hotel':
        return const Color(0xFFFF7A00);
      case 'food':
        return const Color(0xFFFC8019);
      case 'bus':
        return const Color(0xFFFF9F43);
      case 'train':
        return const Color(0xFF54A0FF);
      case 'auto':
        return const Color(0xFF10AC84);
      case 'cab':
        return const Color(0xFFEE5253);
      case 'fuel':
        return const Color(0xFFFF6B6B);
      case 'tickets':
        return const Color(0xFF48DBFB);
      case 'temple':
        return const Color(0xFFFFA502);
      case 'shopping':
        return const Color(0xFF9B59B6);
      case 'snacks':
        return const Color(0xFFE67E22);
      default:
        return const Color(0xFF7F8C8D);
    }
  }
}
