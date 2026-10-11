import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/animations/fade_slide_transition.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../models/expense_model.dart';
import '../../models/trip_model.dart';
import '../../providers/expense_provider.dart';
import '../../services/settlement_engine.dart';

class AddExpenseScreen extends StatefulWidget {
  final TripModel trip;
  final ExpenseModel? existingExpense; // If provided, edit mode

  const AddExpenseScreen({super.key, required this.trip, this.existingExpense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  late String _selectedCategory;
  late String _selectedPayerId;
  late DateTime _expenseDate;
  bool _isCustomSplit = false;

  // Track participation and custom shares
  // memberId -> isParticipating
  final Map<String, bool> _participating = {};
  // memberId -> TextEditingController for custom amount
  final Map<String, TextEditingController> _customShareControllers = {};

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final members = widget.trip.members;
    final exp = widget.existingExpense;

    if (exp != null) {
      // Edit mode
      _amountController.text = (exp.amountPaise / 100.0).toStringAsFixed(
        exp.amountPaise % 100 == 0 ? 0 : 2,
      );
      _descController.text = exp.description;
      _selectedCategory = exp.category;
      _selectedPayerId = exp.payerId;
      _expenseDate = exp.expenseDate;
      _isCustomSplit = exp.splitType == 'custom';

      final participatingMemberIds = exp.shares.map((s) => s.memberId).toSet();
      for (final m in members) {
        _participating[m.id] = participatingMemberIds.contains(m.id);
        final existingShare = exp.shares.firstWhere(
          (s) => s.memberId == m.id,
          orElse: () => ExpenseShareModel(
            id: '',
            expenseId: '',
            memberId: m.id,
            sharePaise: 0,
          ),
        );
        _customShareControllers[m.id] = TextEditingController(
          text: existingShare.sharePaise > 0
              ? (existingShare.sharePaise / 100.0).toStringAsFixed(
                  existingShare.sharePaise % 100 == 0 ? 0 : 2,
                )
              : '',
        );
      }
    } else {
      // New Expense
      _selectedCategory = 'Hotel';
      // Default payer is 'You' (isOwner)
      final owner = members.firstWhere(
        (m) => m.isOwner,
        orElse: () => members.first,
      );
      _selectedPayerId = owner.id;
      _expenseDate = DateTime.now();

      for (final m in members) {
        _participating[m.id] = true; // All participate by default
        _customShareControllers[m.id] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    for (final c in _customShareControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onSplitEqually() {
    final int totalPaise = CurrencyFormatter.rupeesToPaise(
      _amountController.text,
    );
    if (totalPaise <= 0) {
      ToastUtils.showError(
        context,
        'Please enter a valid expense amount first',
      );
      return;
    }

    final activeMemberIds = _participating.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (activeMemberIds.isEmpty) {
      ToastUtils.showError(context, 'Select at least one participant');
      return;
    }

    final shares = SettlementEngine.calculateEqualSplit(
      totalAmountPaise: totalPaise,
      participantMemberIds: activeMemberIds,
    );

    setState(() {
      for (final memberId in activeMemberIds) {
        final sharePaise = shares[memberId] ?? 0;
        _customShareControllers[memberId]?.text = (sharePaise / 100.0)
            .toStringAsFixed(sharePaise % 100 == 0 ? 0 : 2);
      }
    });
  }

  int _calculateAllocatedCustomPaise() {
    int total = 0;
    for (final entry in _customShareControllers.entries) {
      if (_participating[entry.key] == true) {
        total += CurrencyFormatter.rupeesToPaise(entry.value.text);
      }
    }
    return total;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _expenseDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final int totalPaise = CurrencyFormatter.rupeesToPaise(
      _amountController.text,
    );
    if (totalPaise <= 0) {
      ToastUtils.showError(context, 'Enter a valid expense amount');
      return;
    }

    final activeMemberIds = _participating.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (activeMemberIds.isEmpty) {
      ToastUtils.showError(context, 'Please select who shared this expense');
      return;
    }

    final Map<String, int> memberShares = {};

    if (_isCustomSplit) {
      // Validate sum of individual custom amounts = total expense
      for (final memberId in activeMemberIds) {
        final text = _customShareControllers[memberId]?.text ?? '0';
        memberShares[memberId] = CurrencyFormatter.rupeesToPaise(text);
      }

      final isSumValid = SettlementEngine.validateCustomSplit(
        totalAmountPaise: totalPaise,
        customShares: memberShares,
      );

      if (!isSumValid) {
        final int allocated = _calculateAllocatedCustomPaise();
        final diff = (totalPaise - allocated) / 100.0;
        ToastUtils.showError(
          context,
          'Sum of individual shares (${CurrencyFormatter.formatPaise(allocated)}) does not match total (${CurrencyFormatter.formatPaise(totalPaise)}). Difference: ₹${diff.abs().toStringAsFixed(2)}',
        );
        return;
      }
    } else {
      // Calculate equal split in paise
      final calculated = SettlementEngine.calculateEqualSplit(
        totalAmountPaise: totalPaise,
        participantMemberIds: activeMemberIds,
      );
      memberShares.addAll(calculated);
    }

    setState(() => _isSaving = true);
    final expenseProvider = context.read<ExpenseProvider>();

    if (widget.existingExpense != null) {
      // Update
      await expenseProvider.updateExpense(
        expenseId: widget.existingExpense!.id,
        tripId: widget.trip.id,
        payerId: _selectedPayerId,
        category: _selectedCategory,
        description: _descController.text.trim(),
        amountPaise: totalPaise,
        expenseDate: _expenseDate,
        splitType: _isCustomSplit ? 'custom' : 'equal',
        memberShares: memberShares,
      );
      if (mounted) {
        ToastUtils.showSuccess(context, 'Expense updated ✓');
      }
    } else {
      // Add
      await expenseProvider.addExpense(
        tripId: widget.trip.id,
        payerId: _selectedPayerId,
        category: _selectedCategory,
        description: _descController.text.trim(),
        amountPaise: totalPaise,
        expenseDate: _expenseDate,
        splitType: _isCustomSplit ? 'custom' : 'equal',
        memberShares: memberShares,
      );
      if (mounted) {
        ToastUtils.showSuccess(context, 'Expense saved ✓');
      }
    }

    setState(() => _isSaving = false);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categories = context.watch<ExpenseProvider>().categories;
    final isEdit = widget.existingExpense != null;

    final int totalPaise = CurrencyFormatter.rupeesToPaise(
      _amountController.text,
    );
    final int allocatedPaise = _calculateAllocatedCustomPaise();
    final int customDiff = totalPaise - allocatedPaise;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Expense' : 'Add Expense'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Amount & Description
                FadeSlideTransition(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Expense Amount',
                          style: AppTypography.titleLarge.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space12),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: AppTypography.currencyHero.copyWith(
                            color: colors.primaryColor,
                            fontSize: 34,
                          ),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 6,
                                top: 2,
                              ),
                              child: Text(
                                AppConstants.defaultCurrencySymbol,
                                style: AppTypography.currencyHero.copyWith(
                                  color: colors.primaryColor,
                                  fontSize: 34,
                                ),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 0,
                              minHeight: 0,
                            ),
                            hintText: '0',
                            hintStyle: AppTypography.currencyHero.copyWith(
                              color: colors.textSecondary.withValues(
                                alpha: 0.4,
                              ),
                              fontSize: 34,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return 'Enter amount';
                            final parsed = double.tryParse(val);
                            if (parsed == null || parsed <= 0)
                              return 'Enter valid amount';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDimensions.space16),
                        AppTextField(
                          controller: _descController,
                          label: 'Description / Note',
                          hint: 'e.g. Hotel room, Dinner, Bus ticket',
                          prefixIcon: Icons.edit_note_rounded,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.space20),

                // 2. Category Selection
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 60),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: AppTypography.titleLarge.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories.map((cat) {
                            final bool isSelected =
                                _selectedCategory == cat.name;
                            return ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    cat.iconData,
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : colors.textPrimary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(cat.name),
                                ],
                              ),
                              selected: isSelected,
                              selectedColor: colors.primaryColor,
                              backgroundColor: colors.surfaceColor,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : colors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              onSelected: (val) {
                                if (val)
                                  setState(() => _selectedCategory = cat.name);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.space20),

                // 3. Paid By & Date
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 120),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paid By & Date',
                          style: AppTypography.titleLarge.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Who Paid?',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: _selectedPayerId,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                    ),
                                    items: widget.trip.members.map((m) {
                                      return DropdownMenuItem(
                                        value: m.id,
                                        child: Text(m.name),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null)
                                        setState(() => _selectedPayerId = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: _pickDate,
                                borderRadius: AppDimensions.roundedMD,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: colors.borderColor,
                                        ),
                                        borderRadius: AppDimensions.roundedMD,
                                        color: colors.surfaceColor,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            size: 16,
                                            color: colors.primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat(
                                              'dd MMM yyyy',
                                            ).format(_expenseDate),
                                            style: AppTypography.bodyMedium
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.space20),

                // 4. Split Sharing (Equal vs Custom)
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 180),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Who is Sharing?',
                              style: AppTypography.titleLarge.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            // Toggle Split Mode
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colors.backgroundColor,
                                borderRadius: AppDimensions.roundedMD,
                              ),
                              child: Row(
                                children: [
                                  _buildSplitModeChip(
                                    'Equal',
                                    !_isCustomSplit,
                                    () {
                                      setState(() => _isCustomSplit = false);
                                    },
                                    colors,
                                  ),
                                  _buildSplitModeChip(
                                    'Custom',
                                    _isCustomSplit,
                                    () {
                                      setState(() => _isCustomSplit = true);
                                      _onSplitEqually();
                                    },
                                    colors,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space12),

                        if (_isCustomSplit) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Allocated: ${CurrencyFormatter.formatPaise(allocatedPaise)} / ${CurrencyFormatter.formatPaise(totalPaise)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: customDiff == 0
                                      ? colors.successColor
                                      : colors.errorColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: _onSplitEqually,
                                child: Text(
                                  'Split Equally',
                                  style: TextStyle(color: colors.primaryColor),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                        ],

                        ...widget.trip.members.map((member) {
                          final isIncluded = _participating[member.id] ?? false;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isIncluded,
                                  activeColor: colors.primaryColor,
                                  onChanged: (val) {
                                    setState(() {
                                      _participating[member.id] = val ?? false;
                                      if (!val!) {
                                        _customShareControllers[member.id]
                                            ?.clear();
                                      }
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    member.name,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: isIncluded
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                      color: isIncluded
                                          ? colors.textPrimary
                                          : colors.textSecondary,
                                    ),
                                  ),
                                ),
                                if (_isCustomSplit && isIncluded) ...[
                                  SizedBox(
                                    width: 110,
                                    child: TextFormField(
                                      controller:
                                          _customShareControllers[member.id],
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      textAlign: TextAlign.end,
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        prefixText:
                                            AppConstants.defaultCurrencySymbol,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.space32),

                // Save Expense Button
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 240),
                  child: AppButton(
                    text: isEdit ? 'Update Expense' : 'Save Expense',
                    icon: Icons.check_circle_rounded,
                    isLoading: _isSaving,
                    onPressed: _saveExpense,
                  ),
                ),
                const SizedBox(height: AppDimensions.space24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplitModeChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    SelavuColors colors,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryColor : Colors.transparent,
          borderRadius: AppDimensions.roundedSM,
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : colors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
