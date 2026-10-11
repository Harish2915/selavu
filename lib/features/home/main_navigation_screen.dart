import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../settings/settings_screen.dart';
import '../statistics/statistics_screen.dart';
import '../trips/trips_screen.dart';
import 'home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    HomeScreen(),
    TripsScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.cardColor,
          border: Border(top: BorderSide(color: colors.borderColor, width: 1)),
          boxShadow: AppDimensions.softShadow(),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space12,
              vertical: AppDimensions.space8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home', colors),
                _buildNavItem(1, Icons.luggage_rounded, Icons.luggage_outlined, 'Trips', colors),
                _buildNavItem(2, Icons.pie_chart_rounded, Icons.pie_chart_outline_rounded, 'Stats', colors),
                _buildNavItem(3, Icons.settings_rounded, Icons.settings_outlined, 'Settings', colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    SelavuColors colors,
  ) {
    final bool isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: AppDimensions.roundedMD,
      child: AnimatedContainer(
        duration: AppDimensions.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: AppDimensions.roundedMD,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? colors.primaryColor : colors.textSecondary,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: AppDimensions.space8),
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: colors.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
