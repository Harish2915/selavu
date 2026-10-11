import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/fade_slide_transition.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/trip_model.dart';
import '../../providers/trip_provider.dart';
import 'create_trip_screen.dart';
import 'trip_dashboard_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tripProvider = context.watch<TripProvider>();

    final activeTrips = tripProvider.activeTrips;
    final completedTrips = tripProvider.completedTrips;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Trips',
          style: AppTypography.headlineLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, color: colors.primaryColor),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateTripScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primaryColor,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primaryColor,
          indicatorWeight: 3,
          labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: 'Active (${activeTrips.length})'),
            Tab(text: 'Completed (${completedTrips.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active Trips Tab
          _buildTripList(activeTrips, isActiveTab: true, colors: colors),

          // Completed Trips Tab
          _buildTripList(completedTrips, isActiveTab: false, colors: colors),
        ],
      ),
    );
  }

  Widget _buildTripList(
    List<TripModel> trips, {
    required bool isActiveTab,
    required SelavuColors colors,
  }) {
    if (trips.isEmpty) {
      return EmptyStateView(
        icon: isActiveTab ? Icons.explore_rounded : Icons.check_circle_outline_rounded,
        title: isActiveTab ? 'No active trips' : 'No completed trips yet',
        description: isActiveTab
            ? 'Start a new trip to track group travel expenses.'
            : 'Trips you mark as completed will appear here.',
        buttonText: isActiveTab ? '+ Create Trip' : null,
        onButtonPressed: isActiveTab
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateTripScreen()),
                );
              }
            : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.space20),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.space14),
          child: FadeSlideTransition(
            delay: Duration(milliseconds: index * 60),
            child: _buildTripCard(trip, colors),
          ),
        );
      },
    );
  }

  Widget _buildTripCard(TripModel trip, SelavuColors colors) {
    return AppCard(
      onTap: () {
        context.read<TripProvider>().selectTrip(trip.id);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TripDashboardScreen(trip: trip)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  trip.name,
                  style: AppTypography.headlineMedium.copyWith(
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
          const SizedBox(height: AppDimensions.space8),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: colors.primaryColor),
              const SizedBox(width: 6),
              Text(
                DateFormatter.formatTripRange(trip.fromDate, trip.toDate),
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 14),
              Icon(Icons.people_rounded, size: 15, color: colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '${trip.members.length} people',
                style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
          if (trip.description != null && trip.description!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.space10),
            Text(
              trip.description!,
              style: AppTypography.bodySmall.copyWith(
                color: colors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppDimensions.space14),
          const Divider(),
          const SizedBox(height: AppDimensions.space10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'View details & settlements',
                style: AppTypography.labelSmall.copyWith(
                  color: colors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.primaryColor),
            ],
          ),
        ],
      ),
    );
  }
}
