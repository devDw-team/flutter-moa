import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';

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
    String? merchant,
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
      'merchant': merchant,
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
    try {
      final userId = currentUser?.id;
      if (userId == null) {
        print('User not authenticated in getMonthlyTransactions');
        return [];
      }
      
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0);
      
      final response = await supabase
          .from('transactions')
          .select('*')
          .eq('user_id', userId)
          .gte('transaction_date', startDate.toIso8601String().split('T')[0])
          .lte('transaction_date', endDate.toIso8601String().split('T')[0])
          .order('transaction_date', ascending: false);
      
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error in getMonthlyTransactions: $e');
      return [];
    }
  }
  
  Future<List<Map<String, dynamic>>> getTransactionsByDate(DateTime date) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) {
        print('User not authenticated in getTransactionsByDate');
        return [];
      }
      
      final dateStr = date.toIso8601String().split('T')[0];
      
      // Get transactions without joining categories to avoid RLS infinite recursion
      final transactions = await supabase
          .from('transactions')
          .select('*')
          .eq('user_id', userId)
          .eq('transaction_date', dateStr)
          .order('created_at', ascending: false);
      
      // Get all user's categories once
      final categories = await getCategories();
      final categoryMap = Map.fromEntries(
        categories.map((c) => MapEntry(c['id'], c))
      );
      
      // Map categories to transactions
      final transactionsWithCategories = transactions.map((transaction) {
        final categoryId = transaction['category_id'];
        if (categoryId != null && categoryMap.containsKey(categoryId)) {
          transaction['categories'] = categoryMap[categoryId];
        }
        return transaction;
      }).toList();
      
      return List<Map<String, dynamic>>.from(transactionsWithCategories);
    } catch (e) {
      print('Error in getTransactionsByDate: $e');
      return [];
    }
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
    String? merchant,
    List<String>? tags,
  }) async {
    final updateData = <String, dynamic>{};
    
    if (categoryId != null) updateData['category_id'] = categoryId;
    if (amount != null) updateData['amount'] = amount;
    if (type != null) updateData['type'] = type;
    if (date != null) updateData['transaction_date'] = date.toIso8601String().split('T')[0];
    if (description != null) updateData['description'] = description;
    if (merchant != null) updateData['merchant'] = merchant;
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
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
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
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
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
    try {
      final userId = currentUser?.id;
      if (userId == null) {
        print('User not authenticated in getMonthlySummary');
        return {
          'income': 0,
          'expense': 0,
          'balance': 0,
        };
      }
      
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0);
      
      // Get all transactions for the month
      final transactions = await supabase
          .from('transactions')
          .select('amount, type')
          .eq('user_id', userId)
          .gte('transaction_date', startDate.toIso8601String().split('T')[0])
          .lte('transaction_date', endDate.toIso8601String().split('T')[0]);
      
      double totalIncome = 0;
      double totalExpense = 0;
      
      for (final transaction in transactions) {
        final amount = (transaction['amount'] as num).toDouble();
        final type = transaction['type'] as String;
        
        if (type == 'income') {
          totalIncome += amount;
        } else if (type == 'expense') {
          totalExpense += amount;
        }
      }
      
      return {
        'income': totalIncome,
        'expense': totalExpense,
        'balance': totalIncome - totalExpense,
      };
    } catch (e) {
      print('Error in getMonthlySummary: $e');
      return {
        'income': 0,
        'expense': 0,
        'balance': 0,
      };
    }
  }
  
  // Budget Methods
  Future<Map<String, dynamic>?> getBudgetForMonth(DateTime month) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0);
      
      final response = await supabase
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .eq('period_type', 'monthly')
          .gte('start_date', startDate.toIso8601String().split('T')[0])
          .lte('start_date', endDate.toIso8601String().split('T')[0])
          .eq('is_active', true)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error getting budget for month: $e');
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> getCurrentMonthBudget() async {
    return getBudgetForMonth(DateTime.now());
  }
  
  Future<void> createOrUpdateBudget({
    required double amount,
    required DateTime month,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0);
      
      // Check if budget exists for this month
      final existing = await getBudgetForMonth(month);
      
      if (existing != null) {
        // Update existing budget
        await supabase
            .from('budgets')
            .update({
              'amount': amount,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
      } else {
        // Create new budget
        await supabase
            .from('budgets')
            .insert({
              'user_id': userId,
              'name': '${month.year}년 ${month.month}월 예산',
              'amount': amount,
              'period_type': 'monthly',
              'start_date': startDate.toIso8601String().split('T')[0],
              'end_date': endDate.toIso8601String().split('T')[0],
              'is_active': true,
            });
      }
    } catch (e) {
      print('Error creating/updating budget: $e');
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getBudgetHistory() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      
      final response = await supabase
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .eq('period_type', 'monthly')
          .order('start_date', ascending: false)
          .limit(12);
      
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error getting budget history: $e');
      return [];
    }
  }

  // Get category-wise expense summary for a month
  Future<List<Map<String, dynamic>>> getCategoryAnalysis(DateTime month) async {
    final userId = supabase.auth.currentUser!.id;
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);
    
    try {
      final response = await supabase
          .from('category_summary')
          .select()
          .eq('user_id', userId)
          .eq('category_type', 'expense')
          .gte('month', startDate.toIso8601String())
          .lt('month', endDate.add(Duration(days: 1)).toIso8601String())
          .order('total_amount', ascending: false);
      
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      print('Error getting category analysis: $e');
      return [];
    }
  }
  
  // Profile Methods
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
  
  Future<void> updateProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      
      final updateData = {
        'full_name': fullName,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
      }
      
      await supabase
          .from('profiles')
          .update(updateData)
          .eq('id', userId);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }
  
  Future<String> uploadAvatar(File imageFile) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';
      
      // Delete old avatar if exists
      try {
        final List<FileObject> files = await supabase.storage
            .from('avatars')
            .list(path: userId);
        
        for (final file in files) {
          await supabase.storage
              .from('avatars')
              .remove(['$userId/${file.name}']);
        }
      } catch (e) {
        // Ignore errors when deleting old avatars
        print('Error deleting old avatar: $e');
      }
      
      await supabase.storage
          .from('avatars')
          .uploadBinary(filePath, bytes);
      
      final String publicUrl = supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);
      
      return publicUrl;
    } catch (e) {
      print('Error uploading avatar: $e');
      rethrow;
    }
  }
  
  Future<String> uploadAvatarBytes(Uint8List bytes, {String fileExt = 'jpg'}) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';
      
      // Delete old avatar if exists
      try {
        final List<FileObject> files = await supabase.storage
            .from('avatars')
            .list(path: userId);
        
        for (final file in files) {
          await supabase.storage
              .from('avatars')
              .remove(['$userId/${file.name}']);
        }
      } catch (e) {
        // Ignore errors when deleting old avatars
        print('Error deleting old avatar: $e');
      }
      
      await supabase.storage
          .from('avatars')
          .uploadBinary(filePath, bytes);
      
      final String publicUrl = supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);
      
      return publicUrl;
    } catch (e) {
      print('Error uploading avatar: $e');
      rethrow;
    }
  }
  
  // Password Management
  Future<void> updatePassword(String newPassword) async {
    try {
      final response = await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      
      if (response.user == null) {
        throw Exception('비밀번호 변경에 실패했습니다');
      }
    } catch (e) {
      print('Error updating password: $e');
      rethrow;
    }
  }
}