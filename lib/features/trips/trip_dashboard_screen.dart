import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/fade_slide_transition.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/expense_model.dart';
import '../../models/member_model.dart';
import '../../models/settlement_model.dart';
import '../../models/trip_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/settlement_provider.dart';
import '../../providers/trip_provider.dart';
import '../expenses/add_expense_screen.dart';
import '../payments/add_payment_screen.dart';
import '../people/person_detail_sheet.dart';
import '../settlements/settlement_screen.dart';

class TripDashboardScreen extends StatefulWidget {
  final TripModel trip;

  const TripDashboardScreen({super.key, required this.trip});

  @override
  State<TripDashboardScreen> createState() => _TripDashboardScreenState();
}

class _TripDashboardScreenState extends State<TripDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TripModel _currentTrip;

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTripData();
    });
  }

  void _loadTripData() {
    final tripProvider = context.read<TripProvider>();
    final freshTrip = tripProvider.trips.firstWhere(
      (t) => t.id == _currentTrip.id,
      orElse: () => _currentTrip,
    );
    if (mounted) {
      setState(() {
        _currentTrip = freshTrip;
      });
    }

    final expenseProvider = context.read<ExpenseProvider>();
    final paymentProvider = context.read<PaymentProvider>();

    expenseProvider.loadExpenses(_currentTrip.id).then((_) {
      paymentProvider.loadPayments(_currentTrip.id).then((_) {
        _recalculateSettlement();
      });
    });
  }

  void _recalculateSettlement() {
    final expenseProvider = context.read<ExpenseProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    final settlementProvider = context.read<SettlementProvider>();

    settlementProvider.recalculateSettlement(
      tripId: _currentTrip.id,
      members: _currentTrip.members,
      expenses: expenseProvider.expenses,
      payments: paymentProvider.payments,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmEndTrip() async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'End ${_currentTrip.name}?',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You can still view the complete trip history after ending it. Settlement balances will be finalized.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End Trip'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final tripProvider = context.read<TripProvider>();
      final success = await tripProvider.endTrip(_currentTrip.id);
      if (success && mounted) {
        setState(() {
          _currentTrip = _currentTrip.copyWith(status: 'completed');
        });
        ToastUtils.showSuccess(context, 'Trip ended. Final settlements calculated.');
        _tabController.animateTo(3); // Switch to settlements tab
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final expenseProvider = context.watch<ExpenseProvider>();
    final settlementProvider = context.watch<SettlementProvider>();

    final totalSpentPaise = expenseProvider.totalSpendingPaise;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentTrip.name,
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              DateFormatter.formatTripRange(_currentTrip.fromDate, _currentTrip.toDate),
              style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
        actions: [
          if (_currentTrip.isActive)
            TextButton.icon(
              onPressed: _confirmEndTrip,
              icon: const Icon(Icons.flag_rounded, size: 16),
              label: const Text('End Trip'),
              style: TextButton.styleFrom(
                foregroundColor: colors.errorColor,
                textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: StatusBadge(label: 'Completed', type: BadgeType.completed),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primaryColor,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primaryColor,
          indicatorWeight: 3,
          labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Expenses'),
            Tab(text: 'People'),
            Tab(text: 'Settlement'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Overview
          _buildOverviewTab(totalSpentPaise, expenseProvider, colors),

          // Tab 2: Expenses
          _buildExpensesTab(expenseProvider, colors),

          // Tab 3: People
          _buildPeopleTab(settlementProvider, colors),

          // Tab 4: Settlement
          _buildSettlementTab(settlementProvider, colors),
        ],
      ),
      floatingActionButton: _currentTrip.isActive
          ? FloatingActionButton.extended(
              backgroundColor: colors.primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddExpenseScreen(trip: _currentTrip),
                  ),
                );
                if (result == true) {
                  _loadTripData();
                }
              },
            )
          : null,
    );
  }

  // --- TAB 1: OVERVIEW ---
  Widget _buildOverviewTab(
    int totalSpentPaise,
    ExpenseProvider expenseProvider,
    SelavuColors colors,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Spent Hero Card
          FadeSlideTransition(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.space24),
              decoration: BoxDecoration(
                gradient: colors.primaryGradient,
                borderRadius: AppDimensions.roundedXL,
                boxShadow: AppDimensions.orangeGlow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL SPENT',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.formatPaise(totalSpentPaise),
                    style: AppTypography.currencyHero.copyWith(
                      color: Colors.white,
                      fontSize: 40,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  Row(
                    children: [
                      _buildHeroStat(
                        Icons.group_rounded,
                        '${_currentTrip.members.length} People',
                      ),
                      const SizedBox(width: 24),
                      _buildHeroStat(
                        Icons.calendar_today_rounded,
                        '${_currentTrip.durationDays} Days',
                      ),
                      const SizedBox(width: 24),
                      _buildHeroStat(
                        Icons.receipt_rounded,
                        '${expenseProvider.expenses.length} Entries',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.space20),

          // Quick Action Buttons
          if (_currentTrip.isActive)
            FadeSlideTransition(
              delay: const Duration(milliseconds: 100),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: '+ Add Expense',
                      icon: Icons.receipt_long_rounded,
                      variant: ButtonVariant.primary,
                      height: 48,
                      onPressed: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddExpenseScreen(trip: _currentTrip),
                          ),
                        );
                        if (res == true) _loadTripData();
                      },
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: AppButton(
                      text: '+ Add Payment',
                      icon: Icons.payments_rounded,
                      variant: ButtonVariant.secondary,
                      height: 48,
                      onPressed: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddPaymentScreen(trip: _currentTrip),
                          ),
                        );
                        if (res == true) _loadTripData();
                      },
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppDimensions.space28),

          // Recent Expenses Header
          FadeSlideTransition(
            delay: const Duration(milliseconds: 150),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Expenses',
                  style: AppTypography.titleLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: Text(
                    'View All',
                    style: AppTypography.labelLarge.copyWith(color: colors.primaryColor),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.space8),

          if (expenseProvider.expenses.isEmpty)
            FadeSlideTransition(
              delay: const Duration(milliseconds: 200),
              child: EmptyStateView(
                icon: Icons.receipt_long_rounded,
                title: 'No expenses yet',
                description: 'Tap Add Expense to log the first spend for ${_currentTrip.name}.',
                buttonText: '+ Add Expense',
                onButtonPressed: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddExpenseScreen(trip: _currentTrip),
                    ),
                  );
                  if (res == true) _loadTripData();
                },
              ),
            )
          else
            ...expenseProvider.expenses.take(5).map((expense) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.space10),
                child: _buildExpenseTile(expense, colors),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildHeroStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // --- TAB 2: EXPENSES ---
  Widget _buildExpensesTab(ExpenseProvider expenseProvider, SelavuColors colors) {
    if (expenseProvider.expenses.isEmpty) {
      return EmptyStateView(
        icon: Icons.receipt_long_rounded,
        title: 'No expenses logged',
        description: 'Track fuel, food, hotels and tickets in seconds.',
        buttonText: '+ Add Expense',
        onButtonPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddExpenseScreen(trip: _currentTrip)),
          );
          if (res == true) _loadTripData();
        },
      );
    }

    // Group expenses by formatted date
    final Map<String, List<ExpenseModel>> grouped = {};
    for (final exp in expenseProvider.expenses) {
      final key = DateFormatter.formatExpenseDate(exp.expenseDate);
      grouped.putIfAbsent(key, () => []).add(exp);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.space16),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final list = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                dateKey,
                style: AppTypography.labelLarge.copyWith(
                  color: colors.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...list.map((expense) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.space10),
                  child: _buildExpenseTile(expense, colors),
                )),
          ],
        );
      },
    );
  }

  Widget _buildExpenseTile(ExpenseModel expense, SelavuColors colors) {
    final payer = _currentTrip.members.firstWhere(
      (m) => m.id == expense.payerId,
      orElse: () => MemberModel(
        id: '',
        tripId: '',
        name: 'Unknown',
        createdAt: DateTime.now(),
      ),
    );

    return AppCard(
      onTap: () => _showExpenseActions(expense),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.primaryColor.withValues(alpha: 0.12),
              borderRadius: AppDimensions.roundedMD,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: colors.primaryColor,
            ),
          ),
          const SizedBox(width: AppDimensions.space14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description.isNotEmpty ? expense.description : expense.category,
                  style: AppTypography.titleLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${expense.category} • Paid by ${payer.name}',
                  style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatPaise(expense.amountPaise),
                style: AppTypography.currencyRegular.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${expense.shares.length} sharing',
                style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showExpenseActions(ExpenseModel expense) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLG)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit_rounded, color: colors.primaryColor),
                title: const Text('Edit Expense'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddExpenseScreen(
                        trip: _currentTrip,
                        existingExpense: expense,
                      ),
                    ),
                  );
                  if (res == true) _loadTripData();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: colors.errorColor),
                title: Text('Delete Expense', style: TextStyle(color: colors.errorColor)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Delete Expense?'),
                      content: Text('Are you sure you want to delete "${expense.description}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: colors.errorColor),
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && mounted) {
                    await context.read<ExpenseProvider>().deleteExpense(
                          tripId: _currentTrip.id,
                          expenseId: expense.id,
                        );
                    if (mounted) {
                      ToastUtils.showSuccess(context, 'Expense deleted');
                      _loadTripData();
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 3: PEOPLE ---
  Widget _buildPeopleTab(SettlementProvider settlementProvider, SelavuColors colors) {
    final summaries = settlementProvider.settlement?.memberSummaries ?? [];
    final members = _currentTrip.members;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Counter (Requirements 3 & 14)
          FadeSlideTransition(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'People',
                  style: AppTypography.displayMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  members.length <= 1
                      ? 'Who is joining this trip?'
                      : '${members.length} people',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.space16),

          // Main Grouped People Card (Requirements 3, 4, 14)
          FadeSlideTransition(
            delay: const Duration(milliseconds: 100),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: List.generate(members.length, (index) {
                  final member = members[index];
                  final isCurrentOwner = member.isOwner ||
                      member.name.toLowerCase() == 'you (me)' ||
                      member.name.toLowerCase() == 'you';

                  final summary = summaries.firstWhere(
                    (s) => s.member.id == member.id,
                    orElse: () => MemberSettlementSummary(
                      member: member,
                      paidExpensesPaise: 0,
                      shareExpensesPaise: 0,
                      directGivenPaise: 0,
                      directReceivedPaise: 0,
                    ),
                  );

                  final net = summary.netBalancePaise;
                  final isPositive = net > 0;
                  final isZero = net == 0;

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space16,
                          vertical: 6,
                        ),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: isCurrentOwner
                              ? colors.primaryColor
                              : colors.secondaryColor.withValues(alpha: 0.15),
                          child: Icon(
                            isCurrentOwner
                                ? Icons.person_rounded
                                : Icons.person_outline_rounded,
                            color: isCurrentOwner ? Colors.white : colors.primaryColor,
                            size: 22,
                          ),
                        ),
                        title: isCurrentOwner
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'You',
                                        style: AppTypography.titleLarge.copyWith(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.primaryColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Me',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: colors.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Text(
                                member.name,
                                style: AppTypography.titleLarge.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        subtitle: member.phone != null && member.phone!.isNotEmpty
                            ? Text(
                                member.phone!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: colors.textSecondary,
                                ),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isZero)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  isPositive
                                      ? '+${CurrencyFormatter.formatPaise(net)}'
                                      : '-${CurrencyFormatter.formatPaise(-net)}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isPositive
                                        ? colors.successColor
                                        : colors.errorColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: colors.textSecondary,
                                size: 20,
                              ),
                              onSelected: (val) {
                                if (val == 'details') {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => PersonDetailSheet(
                                      trip: _currentTrip,
                                      member: member,
                                      summary: summary,
                                    ),
                                  );
                                } else if (val == 'edit') {
                                  _showEditPersonModal(member);
                                } else if (val == 'remove') {
                                  _confirmRemovePerson(member);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'details',
                                  child: Row(
                                    children: [
                                      Icon(Icons.receipt_long_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text('View Summary'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit Name'),
                                    ],
                                  ),
                                ),
                                if (!isCurrentOwner)
                                  PopupMenuItem(
                                    value: 'remove',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded,
                                            size: 18, color: colors.errorColor),
                                        const SizedBox(width: 8),
                                        Text('Remove',
                                            style: TextStyle(color: colors.errorColor)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => PersonDetailSheet(
                              trip: _currentTrip,
                              member: member,
                              summary: summary,
                            ),
                          );
                        },
                      ),
                      if (index < members.length - 1)
                        Divider(
                          height: 1,
                          indent: 64,
                          endIndent: 16,
                          color: colors.borderColor.withValues(alpha: 0.6),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.space16),

          // + Add People Button / Card (Requirements 3 & 4)
          FadeSlideTransition(
            delay: const Duration(milliseconds: 200),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showAddPersonModal,
                borderRadius: AppDimensions.roundedLG,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.space16,
                    horizontal: AppDimensions.space20,
                  ),
                  decoration: BoxDecoration(
                    color: colors.cardColor,
                    borderRadius: AppDimensions.roundedLG,
                    border: Border.all(
                      color: colors.primaryColor.withValues(alpha: 0.35),
                      width: 1.4,
                    ),
                    boxShadow: AppDimensions.softShadow(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: colors.primaryColor,
                        size: 22,
                      ),
                      const SizedBox(width: AppDimensions.space8),
                      Text(
                        '+ Add People',
                        style: AppTypography.titleLarge.copyWith(
                          color: colors.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space32),
        ],
      ),
    );
  }

  void _showAddPersonModal() {
    final colors = context.colors;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppDimensions.space24,
          right: AppDimensions.space24,
          top: AppDimensions.space24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDimensions.space24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                'Add Person',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add a friend or travel companion to ${_currentTrip.name}',
                style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: AppDimensions.space20),
              AppTextField(
                controller: nameController,
                label: 'Person Name *',
                hint: 'e.g. Arun, Karthi, Deepa',
                prefixIcon: Icons.person_rounded,
                autofocus: true,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Please enter person name' : null,
              ),
              const SizedBox(height: AppDimensions.space16),
              AppTextField(
                controller: phoneController,
                label: 'Phone Number (Optional)',
                hint: 'e.g. +91 98765 43210',
                prefixIcon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppDimensions.space24),
              AppButton(
                text: 'Add Person',
                icon: Icons.person_add_rounded,
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final name = nameController.text.trim();
                  final phone = phoneController.text.trim();
                  Navigator.pop(ctx);

                  final tripProvider = context.read<TripProvider>();
                  final added = await tripProvider.addMemberToTrip(
                    tripId: _currentTrip.id,
                    memberName: name,
                    phone: phone.isNotEmpty ? phone : null,
                  );

                  if (added != null && mounted) {
                    ToastUtils.showSuccess(context, '$name added to trip');
                    _loadTripData();
                  } else if (mounted) {
                    ToastUtils.showError(context, 'Failed to add person');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPersonModal(MemberModel member) {
    final colors = context.colors;
    final nameController = TextEditingController(text: member.name);
    final phoneController = TextEditingController(text: member.phone ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppDimensions.space24,
          right: AppDimensions.space24,
          top: AppDimensions.space24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDimensions.space24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                'Edit Person',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Update details for ${member.name}',
                style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: AppDimensions.space20),
              AppTextField(
                controller: nameController,
                label: 'Person Name *',
                prefixIcon: Icons.person_rounded,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Please enter person name' : null,
              ),
              const SizedBox(height: AppDimensions.space16),
              AppTextField(
                controller: phoneController,
                label: 'Phone Number (Optional)',
                hint: 'e.g. +91 98765 43210',
                prefixIcon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppDimensions.space24),
              AppButton(
                text: 'Save Changes',
                icon: Icons.check_circle_rounded,
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final newName = nameController.text.trim();
                  final newPhone = phoneController.text.trim();
                  Navigator.pop(ctx);

                  final tripProvider = context.read<TripProvider>();
                  final ok = await tripProvider.updateMember(
                    tripId: _currentTrip.id,
                    memberId: member.id,
                    name: newName,
                    phone: newPhone.isNotEmpty ? newPhone : null,
                  );

                  if (ok && mounted) {
                    ToastUtils.showSuccess(context, 'Person details updated');
                    _loadTripData();
                  } else if (mounted) {
                    ToastUtils.showError(context, 'Failed to update person');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemovePerson(MemberModel member) async {
    // Current user You (Me) must NEVER be removed
    if (member.isOwner ||
        member.name.toLowerCase() == 'you (me)' ||
        member.name.toLowerCase() == 'you') {
      ToastUtils.showError(context, 'Cannot delete the current user You (Me).');
      return;
    }

    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${member.name}?'),
        content: Text(
          'Are you sure you want to remove ${member.name} from ${_currentTrip.name}?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final tripProvider = context.read<TripProvider>();
      final ok = await tripProvider.removeMember(
        tripId: _currentTrip.id,
        memberId: member.id,
      );

      if (ok && mounted) {
        ToastUtils.showSuccess(context, '${member.name} removed from trip');
        _loadTripData();
      } else if (mounted) {
        ToastUtils.showError(context, 'Could not remove member');
      }
    }
  }


  // --- TAB 4: SETTLEMENT ---
  Widget _buildSettlementTab(SettlementProvider settlementProvider, SelavuColors colors) {
    final settlement = settlementProvider.settlement;
    if (settlement == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SettlementView(
      trip: _currentTrip,
      settlement: settlement,
    );
  }
}
