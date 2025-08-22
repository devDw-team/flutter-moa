import 'category.dart';

class Transaction {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final String type; // 'income' or 'expense'
  final String? description;
  final String? merchant;
  final String? paymentMethod; // 'card', 'transfer', 'cash'
  final String? installmentId;
  final int? installmentMonths;
  final DateTime transactionDate;
  final DateTime? transactionTime;
  final List<String>? tags;
  final bool isRecurring;
  final String? recurringId;
  final String? receiptId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Related objects
  final Category? category;

  Transaction({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.type,
    this.description,
    this.merchant,
    this.paymentMethod,
    this.installmentId,
    this.installmentMonths,
    required this.transactionDate,
    this.transactionTime,
    this.tags,
    this.isRecurring = false,
    this.recurringId,
    this.receiptId,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['user_id'],
      categoryId: json['category_id'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      description: json['description'],
      merchant: json['merchant'],
      paymentMethod: json['payment_method'],
      installmentId: json['installment_id'],
      installmentMonths: json['installment_months'],
      transactionDate: DateTime.parse(json['transaction_date']),
      transactionTime: json['transaction_time'] != null
          ? DateTime.parse('1970-01-01 ${json['transaction_time']}')
          : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isRecurring: json['is_recurring'] ?? false,
      recurringId: json['recurring_id'],
      receiptId: json['receipt_id'],
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
      'category_id': categoryId,
      'amount': amount,
      'type': type,
      'description': description,
      'merchant': merchant,
      'payment_method': paymentMethod,
      'installment_id': installmentId,
      'installment_months': installmentMonths,
      'transaction_date': transactionDate.toIso8601String().split('T')[0],
      'transaction_time': transactionTime?.toIso8601String().split('T')[1],
      'tags': tags,
      'is_recurring': isRecurring,
      'recurring_id': recurringId,
      'receipt_id': receiptId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Transaction copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? amount,
    String? type,
    String? description,
    String? merchant,
    String? paymentMethod,
    String? installmentId,
    int? installmentMonths,
    DateTime? transactionDate,
    DateTime? transactionTime,
    List<String>? tags,
    bool? isRecurring,
    String? recurringId,
    String? receiptId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Category? category,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      merchant: merchant ?? this.merchant,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      installmentId: installmentId ?? this.installmentId,
      installmentMonths: installmentMonths ?? this.installmentMonths,
      transactionDate: transactionDate ?? this.transactionDate,
      transactionTime: transactionTime ?? this.transactionTime,
      tags: tags ?? this.tags,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
      receiptId: receiptId ?? this.receiptId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
    );
  }
}

class DailySummary {
  final String userId;
  final String? familyGroupId;
  final DateTime transactionDate;
  final String type;
  final double totalAmount;
  final int transactionCount;
  final List<String> transactionIds;

  DailySummary({
    required this.userId,
    this.familyGroupId,
    required this.transactionDate,
    required this.type,
    required this.totalAmount,
    required this.transactionCount,
    required this.transactionIds,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      userId: json['user_id'],
      familyGroupId: json['family_group_id'],
      transactionDate: DateTime.parse(json['transaction_date']),
      type: json['type'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      transactionCount: json['transaction_count'],
      transactionIds: List<String>.from(json['transaction_ids'] ?? []),
    );
  }
}