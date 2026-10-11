import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/fade_slide_transition.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/trip_model.dart';
import '../../providers/trip_provider.dart';
import '../expenses/add_expense_screen.dart';
import '../payments/add_payment_screen.dart';
import '../trips/create_trip_screen.dart';
import '../trips/trip_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tripProvider = context.read<TripProvider>();
      tripProvider.loadTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tripProvider = context.watch<TripProvider>();
    final activeTrip = tripProvider.latestActiveTrip;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: colors.primaryColor,
          onRefresh: () => tripProvider.loadTrips(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space20,
              vertical: AppDimensions.space16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header with greeting (Stagger 1)
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 50),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: AppTypography.headlineMedium.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Let's track your Selavu.",
                            style: AppTypography.bodyMedium.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.primaryColor, width: 1.5),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person_rounded,
                              color: colors.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.space20),

                // 2. Current Active Trip Card (Stagger 2)
                if (tripProvider.isLoading && tripProvider.trips.isEmpty)
                  const ShimmerLoader(width: double.infinity, height: 180)
                else if (activeTrip != null)
                  FadeSlideTransition(
                    delay: const Duration(milliseconds: 120),
                    child: _buildActiveTripCard(context, activeTrip, colors),
                  )
                else
                  FadeSlideTransition(
                    delay: const Duration(milliseconds: 120),
                    child: _buildNoActiveTripBanner(context, colors),
                  ),

                const SizedBox(height: AppDimensions.space24),

                // 3. Quick Actions (Stagger 3)
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: AppTypography.titleLarge.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              title: '+ Add Expense',
                              icon: Icons.receipt_long_rounded,
                              color: colors.primaryColor,
                              onTap: () {
                                if (activeTrip != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddExpenseScreen(trip: activeTrip),
                                    ),
                                  );
                                } else {
                                  _promptCreateTrip(context);
                                }
                              },
                              colors: colors,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: _buildQuickActionButton(
                              title: '+ Add Payment',
                              icon: Icons.payments_rounded,
                              color: const Color(0xFF10AC84),
                              onTap: () {
                                if (activeTrip != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddPaymentScreen(trip: activeTrip),
                                    ),
                                  );
                                } else {
                                  _promptCreateTrip(context);
                                }
                              },
                              colors: colors,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: _buildQuickActionButton(
                              title: '+ New Trip',
                              icon: Icons.add_location_alt_rounded,
                              color: const Color(0xFF54A0FF),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CreateTripScreen(),
                                  ),
                                );
                              },
                              colors: colors,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.space28),

                // 4. Recent Trips Section (Stagger 4)
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 240),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Trips',
                        style: AppTypography.titleLarge.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to full trips tab or screen
                        },
                        child: Text(
                          'View All',
                          style: AppTypography.labelLarge.copyWith(
                            color: colors.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),

                if (tripProvider.trips.isEmpty && !tripProvider.isLoading)
                  FadeSlideTransition(
                    delay: const Duration(milliseconds: 300),
                    child: EmptyStateView(
                      icon: Icons.luggage_rounded,
                      title: 'No trips yet',
                      description: 'Start your first trip and keep every Selavu organized.',
                      buttonText: '+ Create Trip',
                      onButtonPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateTripScreen(),
                          ),
                        );
                      },
                    ),
                  )
                else
                  ...tripProvider.trips.take(4).map((trip) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.space12),
                      child: _buildRecentTripCard(context, trip, colors),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTripCard(BuildContext context, TripModel trip, SelavuColors colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: colors.primaryGradient,
        borderRadius: AppDimensions.roundedXL,
        boxShadow: AppDimensions.orangeGlow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.read<TripProvider>().selectTrip(trip.id);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TripDashboardScreen(trip: trip),
              ),
            );
          },
          borderRadius: AppDimensions.roundedXL,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: AppDimensions.roundedFull,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, color: Colors.white, size: 8),
                          const SizedBox(width: 6),
                          Text(
                            'ACTIVE TRIP',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormatter.formatTripRange(trip.fromDate, trip.toDate),
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space16),
                Text(
                  trip.name,
                  style: AppTypography.displayMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                Row(
                  children: [
                    const Icon(Icons.group_rounded, color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${trip.members.length} people',
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${trip.durationDays} ${trip.durationDays == 1 ? "day" : "days"}',
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: AppDimensions.space12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Manage & View Expenses',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'View Trip',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoActiveTripBanner(BuildContext context, SelavuColors colors) {
    return AppCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateTripScreen()),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: BoxDecoration(
              color: colors.primaryColor.withValues(alpha: 0.12),
              borderRadius: AppDimensions.roundedMD,
            ),
            child: Icon(Icons.add_location_alt_rounded, color: colors.primaryColor, size: 32),
          ),
          const SizedBox(width: AppDimensions.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Active Trip',
                  style: AppTypography.titleLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Plan a getaway and track group expenses easily',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required SelavuColors colors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimensions.roundedMD,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: colors.cardColor,
            borderRadius: AppDimensions.roundedMD,
            border: Border.all(color: colors.borderColor, width: 1),
            boxShadow: AppDimensions.softShadow(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTripCard(BuildContext context, TripModel trip, SelavuColors colors) {
    return AppCard(
      onTap: () {
        context.read<TripProvider>().selectTrip(trip.id);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TripDashboardScreen(trip: trip)),
        );
      },
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: trip.isActive
                  ? colors.primaryColor.withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.12),
              borderRadius: AppDimensions.roundedMD,
            ),
            child: Icon(
              trip.isActive ? Icons.flight_takeoff_rounded : Icons.check_circle_outline_rounded,
              color: trip.isActive ? colors.primaryColor : Colors.grey,
            ),
          ),
          const SizedBox(width: AppDimensions.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        trip.name,
                        style: AppTypography.titleLarge.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusBadge(
                      label: trip.isActive ? 'Active' : 'Completed',
                      type: trip.isActive ? BadgeType.active : BadgeType.completed,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormatter.formatTripRange(trip.fromDate, trip.toDate)} • ${trip.members.length} people',
                  style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _promptCreateTrip(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No Active Trip'),
        content: const Text('Please create a trip first before adding expenses or payments.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateTripScreen()),
              );
            },
            child: const Text('+ Create Trip'),
          ),
        ],
      ),
    );
  }
}
