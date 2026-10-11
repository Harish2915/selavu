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
import '../../models/payment_model.dart';
import '../../models/trip_model.dart';
import '../../providers/payment_provider.dart';

class AddPaymentScreen extends StatefulWidget {
  final TripModel trip;
  final PaymentModel? existingPayment;

  const AddPaymentScreen({
    super.key,
    required this.trip,
    this.existingPayment,
  });

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late String _fromMemberId;
  late String _toMemberId;
  late DateTime _paymentDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final members = widget.trip.members;
    final payment = widget.existingPayment;

    // Find owner member ("You")
    final owner = members.firstWhere((m) => m.isOwner, orElse: () => members.first);
    // Find first non-owner member
    final nonOwner = members.firstWhere((m) => !m.isOwner, orElse: () => members.first);

    if (payment != null) {
      _amountController.text = (payment.amountPaise / 100.0).toStringAsFixed(
        payment.amountPaise % 100 == 0 ? 0 : 2,
      );
      _notesController.text = payment.notes ?? '';
      _fromMemberId = payment.fromMemberId;
      _toMemberId = payment.toMemberId;
      _paymentDate = payment.paymentDate;
    } else {
      _fromMemberId = nonOwner.id;
      _toMemberId = owner.id;
      _paymentDate = DateTime.now();
      _notesController.text = 'Advance / Direct payment';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fromMemberId == _toMemberId) {
      ToastUtils.showError(context, 'Sender and recipient cannot be the same person');
      return;
    }

    final int amountPaise = CurrencyFormatter.rupeesToPaise(_amountController.text);
    if (amountPaise <= 0) {
      ToastUtils.showError(context, 'Please enter a valid payment amount');
      return;
    }

    setState(() => _isSaving = true);
    final paymentProvider = context.read<PaymentProvider>();

    if (widget.existingPayment != null) {
      await paymentProvider.updatePayment(
        paymentId: widget.existingPayment!.id,
        tripId: widget.trip.id,
        fromMemberId: _fromMemberId,
        toMemberId: _toMemberId,
        amountPaise: amountPaise,
        paymentDate: _paymentDate,
        notes: _notesController.text.trim(),
      );
      if (mounted) {
        ToastUtils.showSuccess(context, 'Payment updated ✓');
      }
    } else {
      await paymentProvider.addPayment(
        tripId: widget.trip.id,
        fromMemberId: _fromMemberId,
        toMemberId: _toMemberId,
        amountPaise: amountPaise,
        paymentDate: _paymentDate,
        notes: _notesController.text.trim(),
      );
      if (mounted) {
        ToastUtils.showSuccess(context, 'Payment recorded ✓');
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
    final isEdit = widget.existingPayment != null;

    final fromMember = widget.trip.members.firstWhere(
      (m) => m.id == _fromMemberId,
      orElse: () => widget.trip.members.first,
    );
    final toMember = widget.trip.members.firstWhere(
      (m) => m.id == _toMemberId,
      orElse: () => widget.trip.members.first,
    );

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Payment' : 'Record Direct Payment'),
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
                // Direction Illustration Banner
                FadeSlideTransition(
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: colors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: AppDimensions.roundedLG,
                      border: Border.all(color: colors.primaryColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          fromMember.name,
                          style: AppTypography.titleLarge.copyWith(
                            color: colors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.arrow_forward_rounded, color: AppColors.orange500),
                        ),
                        Text(
                          toMember.name,
                          style: AppTypography.titleLarge.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.space20),

                // Amount
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 60),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Amount',
                          style: AppTypography.titleLarge.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space12),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: AppTypography.currencyHero.copyWith(
                            color: const Color(0xFF10AC84),
                            fontSize: 34,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 12, right: 6, top: 2),
                              child: Text(
                                AppConstants.defaultCurrencySymbol,
                                style: AppTypography.currencyHero.copyWith(
                                  color: const Color(0xFF10AC84),
                                  fontSize: 34,
                                ),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            hintText: '500',
                            hintStyle: AppTypography.currencyHero.copyWith(
                              color: colors.textSecondary.withValues(alpha: 0.4),
                              fontSize: 34,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter amount';
                            final parsed = double.tryParse(val);
                            if (parsed == null || parsed <= 0) return 'Enter valid amount';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.space20),

                // Sender & Recipient Pickers
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 120),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transfer Parties',
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
                                    'Paid By (Sender)',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: _fromMemberId,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    items: widget.trip.members.map((m) {
                                      return DropdownMenuItem(
                                        value: m.id,
                                        child: Text(m.name),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _fromMemberId = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Given To (Receiver)',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: _toMemberId,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    items: widget.trip.members.map((m) {
                                      return DropdownMenuItem(
                                        value: m.id,
                                        child: Text(m.name),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _toMemberId = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space16),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: AppDimensions.roundedMD,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: colors.borderColor),
                              borderRadius: AppDimensions.roundedMD,
                              color: colors.surfaceColor,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 16, color: colors.primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd MMM yyyy').format(_paymentDate),
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space16),
                        AppTextField(
                          controller: _notesController,
                          label: 'Notes / Reason',
                          hint: 'e.g. Advance payment, Cash handed over',
                          prefixIcon: Icons.description_outlined,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.space32),

                // Submit Button
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 180),
                  child: AppButton(
                    text: isEdit ? 'Update Payment' : 'Record Payment',
                    icon: Icons.check_circle_rounded,
                    customColor: const Color(0xFF10AC84),
                    isLoading: _isSaving,
                    onPressed: _savePayment,
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
}
