import 'member_model.dart';

class TripModel {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final DateTime fromDate;
  final DateTime? toDate;
  final String status; // 'active', 'completed'
  final String currency;
  final List<MemberModel> members;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TripModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.fromDate,
    this.toDate,
    this.status = 'active',
    this.currency = 'INR',
    this.members = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';

  int get durationDays {
    if (toDate == null) {
      final now = DateTime.now();
      final diff = now.difference(fromDate).inDays;
      return diff < 1 ? 1 : diff + 1;
    }
    final diff = toDate!.difference(fromDate).inDays;
    return diff < 1 ? 1 : diff + 1;
  }

  TripModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? currency,
    List<MemberModel>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      status: status ?? this.status,
      currency: currency ?? this.currency,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'from_date': fromDate.toIso8601String().split('T').first,
      'to_date': toDate?.toIso8601String().split('T').first,
      'status': status,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TripModel.fromJson(Map<String, dynamic> json, {List<MemberModel>? members}) {
    return TripModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      fromDate: DateTime.parse(json['from_date'] as String),
      toDate: json['to_date'] != null ? DateTime.parse(json['to_date'] as String) : null,
      status: json['status'] as String? ?? 'active',
      currency: json['currency'] as String? ?? 'INR',
      members: members ?? const [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
