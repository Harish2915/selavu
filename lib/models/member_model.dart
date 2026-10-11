class MemberModel {
  final String id;
  final String tripId;
  final String? userId;
  final String name;
  final String? phone;
  final bool isOwner;
  final DateTime createdAt;

  const MemberModel({
    required this.id,
    required this.tripId,
    this.userId,
    required this.name,
    this.phone,
    this.isOwner = false,
    required this.createdAt,
  });

  MemberModel copyWith({
    String? id,
    String? tripId,
    String? userId,
    String? name,
    String? phone,
    bool? isOwner,
    DateTime? createdAt,
  }) {
    return MemberModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      isOwner: isOwner ?? this.isOwner,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'is_owner': isOwner,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      isOwner: json['is_owner'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
