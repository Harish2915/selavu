import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/animations/fade_slide_transition.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../providers/trip_provider.dart';
import 'trip_dashboard_screen.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  DateTime _fromDate = DateTime.now();
  DateTime? _toDate;
  bool _isOpenEnded = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(_fromDate)) {
          _toDate = _fromDate;
        }
      });
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate.add(const Duration(days: 2)),
      firstDate: _fromDate,
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _toDate = picked;
        _isOpenEnded = false;
      });
    }
  }

  Future<void> _submitTrip() async {
    // Trip Name: do not force. If empty, automatically default to "New Trip"
    final inputName = _nameController.text.trim();
    final effectiveName = inputName.isEmpty ? 'New Trip' : inputName;

    setState(() => _isSubmitting = true);

    final tripProvider = context.read<TripProvider>();
    final newTrip = await tripProvider.createTrip(
      name: effectiveName,
      fromDate: _fromDate,
      toDate: _isOpenEnded ? null : _toDate,
      description: _descController.text.trim(),
      memberNames: const [], // Member list initially contains only 'You (Me)'
    );

    setState(() => _isSubmitting = false);

    if (newTrip != null && mounted) {
      ToastUtils.showSuccess(context, 'Trip created successfully!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TripDashboardScreen(trip: newTrip),
        ),
      );
    } else if (mounted) {
      ToastUtils.showError(
        context,
        tripProvider.errorMessage ?? 'Could not create trip. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        title: const Text('Create New Trip'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Trip Details
              FadeSlideTransition(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip Information',
                        style: AppTypography.titleLarge.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space16),
                      AppTextField(
                        controller: _nameController,
                        label: 'Trip Name',
                        hint: 'e.g. Goa Vacation (Default: "New Trip")',
                        prefixIcon: Icons.luggage_rounded,
                      ),
                      const SizedBox(height: AppDimensions.space16),
                      AppTextField(
                        controller: _descController,
                        label: 'Notes / Description (Optional)',
                        hint: 'Weekend getaways, road trips, food tours...',
                        prefixIcon: Icons.notes_rounded,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space20),

              // Section 2: Dates (From Date required, To Date optional)
              FadeSlideTransition(
                delay: const Duration(milliseconds: 100),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip Duration',
                        style: AppTypography.titleLarge.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _pickFromDate,
                              borderRadius: AppDimensions.roundedMD,
                              child: Container(
                                padding: const EdgeInsets.all(AppDimensions.space12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: colors.borderColor),
                                  borderRadius: AppDimensions.roundedMD,
                                  color: colors.surfaceColor,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'From Date * (Required)',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded,
                                            size: 16, color: colors.primaryColor),
                                        const SizedBox(width: 8),
                                        Text(
                                          dateFormat.format(_fromDate),
                                          style: AppTypography.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() => _isOpenEnded = false);
                                _pickToDate();
                              },
                              borderRadius: AppDimensions.roundedMD,
                              child: Container(
                                padding: const EdgeInsets.all(AppDimensions.space12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: colors.borderColor),
                                  borderRadius: AppDimensions.roundedMD,
                                  color: colors.surfaceColor,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'To Date (Optional)',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.event_available_rounded,
                                            size: 16, color: colors.primaryColor),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isOpenEnded || _toDate == null
                                              ? 'Ongoing'
                                              : dateFormat.format(_toDate!),
                                          style: AppTypography.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      Row(
                        children: [
                          Checkbox(
                            value: _isOpenEnded,
                            activeColor: colors.primaryColor,
                            onChanged: (val) {
                              setState(() {
                                _isOpenEnded = val ?? true;
                                if (_isOpenEnded) _toDate = null;
                              });
                            },
                          ),
                          Text(
                            'Open-ended / Ongoing trip (no fixed end date)',
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space32),

              // Submit Button
              FadeSlideTransition(
                delay: const Duration(milliseconds: 200),
                child: AppButton(
                  text: 'Create Trip',
                  icon: Icons.check_circle_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _submitTrip,
                ),
              ),
              const SizedBox(height: AppDimensions.space24),
            ],
          ),
        ),
      ),
    );
  }
}
