import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();
  
  final supabase = Supabase.instance.client;
  
  // Auth Methods
  User? get currentUser => supabase.auth.currentUser;
  
  Future<AuthResponse> signUp(String email, String password, String fullName) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }
  
  Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
  
  // Transaction Methods
  Future<void> addTransaction({
    required String categoryId,
    required double amount,
    required String type,
    required DateTime date,
    String? description,
    List<String>? tags,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    await supabase.from('transactions').insert({
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'type': type,
      'transaction_date': date.toIso8601String().split('T')[0],
      'description': description,
      'tags': tags,
    });
  }
  
  Future<List<Map<String, dynamic>>> getDailyTransactions(DateTime date) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    final dateStr = date.toIso8601String().split('T')[0];
    
    final response = await supabase
        .from('daily_summary')
        .select()
        .eq('user_id', userId)
        .eq('transaction_date', dateStr);
    
    return List<Map<String, dynamic>>.from(response as List);
  }
  
  Future<List<Map<String, dynamic>>> getMonthlyTransactions(DateTime month) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);
    
    final response = await supabase
        .from('transactions')
        .select('*, categories!inner(*)')
        .eq('user_id', userId)
        .gte('transaction_date', startDate.toIso8601String().split('T')[0])
        .lte('transaction_date', endDate.toIso8601String().split('T')[0])
        .order('transaction_date', ascending: false);
    
    return List<Map<String, dynamic>>.from(response as List);
  }
  
  Future<List<Map<String, dynamic>>> getTransactionsByDate(DateTime date) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    final dateStr = date.toIso8601String().split('T')[0];
    
    final response = await supabase
        .from('transactions')
        .select('*, categories!inner(*)')
        .eq('user_id', userId)
        .eq('transaction_date', dateStr)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response as List);
  }
  
  Future<void> deleteTransaction(String transactionId) async {
    await supabase
        .from('transactions')
        .delete()
        .eq('id', transactionId);
  }
  
  Future<void> updateTransaction({
    required String transactionId,
    String? categoryId,
    double? amount,
    String? type,
    DateTime? date,
    String? description,
    List<String>? tags,
  }) async {
    final updateData = <String, dynamic>{};
    
    if (categoryId != null) updateData['category_id'] = categoryId;
    if (amount != null) updateData['amount'] = amount;
    if (type != null) updateData['type'] = type;
    if (date != null) updateData['transaction_date'] = date.toIso8601String().split('T')[0];
    if (description != null) updateData['description'] = description;
    if (tags != null) updateData['tags'] = tags;
    
    await supabase
        .from('transactions')
        .update(updateData)
        .eq('id', transactionId);
  }
  
  // Category Methods
  Future<List<Map<String, dynamic>>> getCategories({String? type}) async {
    try {
      final userId = currentUser?.id;
      
      // If not authenticated, return hardcoded categories for testing
      if (userId == null) {
        return _getHardcodedCategories(type);
      }
      
      var query = supabase
          .from('categories')
          .select()
          .or('is_system.eq.true,user_id.eq.$userId');
      
      if (type != null) {
        query = query.eq('type', type);
      }
      
      final response = await query.order('sort_order');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error fetching categories: $e');
      // Fallback to hardcoded categories if query fails
      return _getHardcodedCategories(type);
    }
  }
  
  // Temporary hardcoded categories for testing
  List<Map<String, dynamic>> _getHardcodedCategories(String? type) {
    final categories = [
      // Expense categories
      {
        'id': 'bbdd3e67-3010-42b1-9e86-f17b653a1871',
        'name': '식비',
        'type': 'expense',
        'icon': '🍽️',
        'color': '#FF6B6B',
        'sort_order': 1,
        'is_system': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '150292dc-c15c-4c0f-b419-e598fd207603',
        'name': '카페/간식',
        'type': 'expense',
        'icon': '☕',
        'color': '#4ECDC4',
        'sort_order': 2,
        'is_system': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '3b6456c0-f425-481a-b511-078efc0689d1',
        'name': '유흥',
        'type': 'expense',
        'icon': '🎉',
        'color': '#FFE66D',
        'sort_order': 3,
        'is_system': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '8d1ee904-e8bb-484f-aee8-4f03396b620b',
        'name': '생필품',
        'type': 'expense',
        'icon': '🧺',
        'color': '#95E1D3',
        'sort_order': 4,
        'is_system': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'ef039dac-a33e-429e-80e8-c3555a91360d',
        'name': '쇼핑',
        'type': 'expense',
        'icon': '🛍️',
        'color': '#FF6B9D',
        'sort_order': 5,
        'is_system': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      // Income categories
      {
        'id': 'b78b5684-a822-469b-ae17-765b2339dd2e',
        'name': '급여',
        'type': 'income',
        'icon': '💵',
        'color': '#00B894',
        'sort_order': 1,
        'is_system': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '33a70165-b003-444a-b5d6-815bbc0de67f',
        'name': '용돈',
        'type': 'income',
        'icon': '💝',
        'color': '#6C5CE7',
        'sort_order': 2,
        'is_system': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '357c4214-a607-4ec6-9a26-cb8e4533c5eb',
        'name': '부업',
        'type': 'income',
        'icon': '💼',
        'color': '#0984E3',
        'sort_order': 3,
        'is_system': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '73f14055-9ae9-4127-9f5b-09918c350c9e',
        'name': '금융',
        'type': 'income',
        'icon': '📈',
        'color': '#FDCB6E',
        'sort_order': 4,
        'is_system': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '8e5d713e-0045-4921-9c46-8afa463b0347',
        'name': '기타',
        'type': 'income',
        'icon': '📌',
        'color': '#636E72',
        'sort_order': 5,
        'is_system': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];
    
    if (type != null) {
      return categories.where((c) => c['type'] == type).toList();
    }
    return categories;
  }
  
  Future<void> addCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    // TODO: Implement proper auth check
    final userId = 'test-user-id';
    
    await supabase.from('categories').insert({
      'user_id': userId,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
    });
  }
  
  // Realtime subscription
  RealtimeChannel subscribeToTransactions(Function(dynamic) onUpdate) {
    // TODO: Implement proper auth check
    final userId = 'test-user-id';
    
    return supabase
        .channel('transactions:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            onUpdate(payload);
          },
        )
        .subscribe();
  }
  
  // Monthly Summary
  Future<Map<String, double>> getMonthlySummary(DateTime month) async {
    // TODO: Implement proper auth check
    final userId = 'test-user-id';
    final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    
    final response = await supabase
        .from('monthly_summary')
        .select()
        .eq('user_id', userId)
        .ilike('month', '$monthStr%');
    
    double totalIncome = 0;
    double totalExpense = 0;
    
    for (final row in response as List) {
      if (row['type'] == 'income') {
        totalIncome = (row['total_amount'] ?? 0).toDouble();
      } else if (row['type'] == 'expense') {
        totalExpense = (row['total_amount'] ?? 0).toDouble();
      }
    }
    
    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }
}