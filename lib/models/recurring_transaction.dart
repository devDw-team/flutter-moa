import 'category.dart';

class RecurringTransaction {
  final String id;
  final String userId;
  final String? familyGroupId;
  final String categoryId;
  final double amount;
  final String type; // 'income' or 'expense'
  final String? description;
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final int intervalValue;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextDate;
  final bool isActive;
  final int? dayOfMonth; // 1-31 or 99 for last day of month
  final int? dayOfWeek; // 0-6 (Sunday-Saturday)
  final String? merchant;
  final String? paymentMethod; // 'card', 'transfer', 'cash'
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Related objects
  final Category? category;

  RecurringTransaction({
    required this.id,
    required this.userId,
    this.familyGroupId,
    required this.categoryId,
    required this.amount,
    required this.type,
    this.description,
    required this.frequency,
    required this.intervalValue,
    required this.startDate,
    this.endDate,
    required this.nextDate,
    required this.isActive,
    this.dayOfMonth,
    this.dayOfWeek,
    this.merchant,
    this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'],
      userId: json['user_id'],
      familyGroupId: json['family_group_id'],
      categoryId: json['category_id'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      description: json['description'],
      frequency: json['frequency'],
      intervalValue: json['interval_value'] ?? 1,
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      nextDate: DateTime.parse(json['next_date']),
      isActive: json['is_active'] ?? true,
      dayOfMonth: json['day_of_month'],
      dayOfWeek: json['day_of_week'],
      merchant: json['merchant'],
      paymentMethod: json['payment_method'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
      'amount': amount,
      'type': type,
      'description': description,
      'frequency': frequency,
      'interval_value': intervalValue,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'next_date': nextDate.toIso8601String().split('T')[0],
      'is_active': isActive,
      'day_of_month': dayOfMonth,
      'day_of_week': dayOfWeek,
      'merchant': merchant,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  RecurringTransaction copyWith({
    String? id,
    String? userId,
    String? familyGroupId,
    String? categoryId,
    double? amount,
    String? type,
    String? description,
    String? frequency,
    int? intervalValue,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextDate,
    bool? isActive,
    int? dayOfMonth,
    int? dayOfWeek,
    String? merchant,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    Category? category,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      familyGroupId: familyGroupId ?? this.familyGroupId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      intervalValue: intervalValue ?? this.intervalValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextDate: nextDate ?? this.nextDate,
      isActive: isActive ?? this.isActive,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      merchant: merchant ?? this.merchant,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
    );
  }

  String get frequencyText {
    switch (frequency) {
      case 'daily':
        return intervalValue == 1 ? '매일' : '$intervalValue일마다';
      case 'weekly':
        if (dayOfWeek != null) {
          final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
          return intervalValue == 1 ? '매주 ${weekdays[dayOfWeek!]}요일' : '$intervalValue주마다 ${weekdays[dayOfWeek!]}요일';
        }
        return intervalValue == 1 ? '매주' : '$intervalValue주마다';
      case 'monthly':
        if (dayOfMonth == 99) {
          return intervalValue == 1 ? '매월 말일' : '$intervalValue개월마다 말일';
        } else if (dayOfMonth != null) {
          return intervalValue == 1 ? '매월 $dayOfMonth일' : '$intervalValue개월마다 $dayOfMonth일';
        }
        return intervalValue == 1 ? '매월' : '$intervalValue개월마다';
      case 'yearly':
        return intervalValue == 1 ? '매년' : '$intervalValue년마다';
      default:
        return frequency;
    }
  }

  String get paymentMethodText {
    switch (paymentMethod) {
      case 'card':
        return '카드';
      case 'transfer':
        return '계좌이체';
      case 'cash':
        return '현금';
      default:
        return '';
    }
  }
}