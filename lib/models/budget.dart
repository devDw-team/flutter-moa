import 'category.dart';

class Budget {
  final String id;
  final String? userId;
  final String? familyGroupId;
  final String? categoryId;
  final String name;
  final double amount;
  final String periodType; // 'weekly', 'monthly', 'yearly'
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Calculated fields
  final double? usedAmount;
  final double? usagePercentage;
  final Category? category;

  Budget({
    required this.id,
    this.userId,
    this.familyGroupId,
    this.categoryId,
    required this.name,
    required this.amount,
    required this.periodType,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.usedAmount,
    this.usagePercentage,
    this.category,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      userId: json['user_id'],
      familyGroupId: json['family_group_id'],
      categoryId: json['category_id'],
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      periodType: json['period_type'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      usedAmount: json['used_amount'] != null 
          ? (json['used_amount'] as num).toDouble() 
          : null,
      usagePercentage: json['usage_percentage'] != null 
          ? (json['usage_percentage'] as num).toDouble() 
          : null,
      category: json['categories'] != null
          ? Category.fromJson(json['categories'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'family_group_id': familyGroupId,
      'category_id': categoryId,
      'name': name,
      'amount': amount,
      'period_type': periodType,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isOverBudget {
    if (usagePercentage == null) return false;
    return usagePercentage! > 100;
  }

  bool get isNearLimit {
    if (usagePercentage == null) return false;
    return usagePercentage! >= 80 && usagePercentage! <= 100;
  }

  double get remainingAmount {
    if (usedAmount == null) return amount;
    return amount - usedAmount!;
  }
}