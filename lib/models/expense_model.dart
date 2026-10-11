class ExpenseShareModel {
  final String id;
  final String expenseId;
  final String memberId;
  final int sharePaise; // smallest monetary unit (1 Rupee = 100 Paise)

  const ExpenseShareModel({
    required this.id,
    required this.expenseId,
    required this.memberId,
    required this.sharePaise,
  });

  double get shareRupees => sharePaise / 100.0;

  ExpenseShareModel copyWith({
    String? id,
    String? expenseId,
    String? memberId,
    int? sharePaise,
  }) {
    return ExpenseShareModel(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      memberId: memberId ?? this.memberId,
      sharePaise: sharePaise ?? this.sharePaise,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'member_id': memberId,
      'share_paise': sharePaise,
    };
  }

  factory ExpenseShareModel.fromJson(Map<String, dynamic> json) {
    return ExpenseShareModel(
      id: json['id'] as String,
      expenseId: json['expense_id'] as String,
      memberId: json['member_id'] as String,
      sharePaise: (json['share_paise'] as num).toInt(),
    );
  }
}

class ExpenseModel {
  final String id;
  final String tripId;
  final String payerId; // ID of the member who paid
  final String category;
  final String description;
  final int amountPaise; // integer smallest monetary unit
  final DateTime expenseDate;
  final String splitType; // 'equal', 'custom'
  final List<ExpenseShareModel> shares;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseModel({
    required this.id,
    required this.tripId,
    required this.payerId,
    required this.category,
    required this.description,
    required this.amountPaise,
    required this.expenseDate,
    this.splitType = 'equal',
    this.shares = const [],
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  double get amountRupees => amountPaise / 100.0;

  ExpenseModel copyWith({
    String? id,
    String? tripId,
    String? payerId,
    String? category,
    String? description,
    int? amountPaise,
    DateTime? expenseDate,
    String? splitType,
    List<ExpenseShareModel>? shares,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      payerId: payerId ?? this.payerId,
      category: category ?? this.category,
      description: description ?? this.description,
      amountPaise: amountPaise ?? this.amountPaise,
      expenseDate: expenseDate ?? this.expenseDate,
      splitType: splitType ?? this.splitType,
      shares: shares ?? this.shares,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'payer_id': payerId,
      'category': category,
      'description': description,
      'amount_paise': amountPaise,
      'expense_date': expenseDate.toIso8601String(),
      'split_type': splitType,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ExpenseModel.fromJson(
    Map<String, dynamic> json, {
    List<ExpenseShareModel>? shares,
  }) {
    return ExpenseModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      payerId: json['payer_id'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      amountPaise: (json['amount_paise'] as num).toInt(),
      expenseDate: json['expense_date'] != null
          ? DateTime.parse(json['expense_date'] as String)
          : DateTime.now(),
      splitType: json['split_type'] as String? ?? 'equal',
      shares: shares ?? const [],
      createdBy: json['created_by'] as String?,
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
      other is ExpenseModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
