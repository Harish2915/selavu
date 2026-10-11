import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final bool isDefault;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = true,
  });

  static IconData getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'hotel':
        return Icons.hotel_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'bus':
        return Icons.directions_bus_rounded;
      case 'train':
        return Icons.train_rounded;
      case 'auto':
        return Icons.electric_rickshaw_rounded;
      case 'cab':
        return Icons.local_taxi_rounded;
      case 'fuel':
        return Icons.local_gas_station_rounded;
      case 'tickets':
        return Icons.confirmation_number_rounded;
      case 'temple':
        return Icons.temple_hindu_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'snacks':
        return Icons.fastfood_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  IconData get iconData => getIconData(icon);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
      'is_default': isDefault,
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    Color parsedColor = const Color(0xFFFC8019);
    if (json['color'] != null) {
      final hex = (json['color'] as String).replaceAll('#', '');
      parsedColor = Color(int.parse('FF$hex', radix: 16));
    }
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: parsedColor,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}
