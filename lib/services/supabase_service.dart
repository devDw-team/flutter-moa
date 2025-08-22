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
    String? paymentMethod,
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
      'payment_method': paymentMethod,
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
    String? paymentMethod,
    List<String>? tags,
  }) async {
    final updateData = <String, dynamic>{};
    
    if (categoryId != null) updateData['category_id'] = categoryId;
    if (amount != null) updateData['amount'] = amount;
    if (type != null) updateData['type'] = type;
    if (date != null) updateData['transaction_date'] = date.toIso8601String().split('T')[0];
    if (description != null) updateData['description'] = description;
    if (merchant != null) updateData['merchant'] = merchant;
    if (paymentMethod != null) updateData['payment_method'] = paymentMethod;
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
  
  // Installment Methods
  Future<String> createInstallmentTransactions({
    required String categoryId,
    required double totalAmount,
    required int installmentMonths,
    required DateTime startDate,
    required String paymentMethod,
    String? description,
    String? merchant,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    try {
      // Format date string properly
      final dateStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      
      print('Creating installment with params:');
      print('  user_id: $userId');
      print('  category_id: $categoryId');
      print('  total_amount: $totalAmount (type: ${totalAmount.runtimeType})');
      print('  installment_months: $installmentMonths (type: ${installmentMonths.runtimeType})');
      print('  start_date: $dateStr');
      print('  payment_method: $paymentMethod');
      print('  merchant: ${merchant ?? 'null'}');
      print('  description: ${description ?? 'null'}');
      
      // Call RPC with properly formatted parameters
      final response = await supabase.rpc('create_installment_transactions', params: {
        'p_user_id': userId,
        'p_category_id': categoryId,
        'p_total_amount': totalAmount,
        'p_installment_months': installmentMonths,
        'p_start_date': dateStr,
        'p_payment_method': paymentMethod,
        'p_merchant': merchant ?? '',
        'p_description': description ?? '',
      });
      
      return response?.toString() ?? '';
    } catch (e) {
      print('Error creating installment transactions: $e');
      rethrow;
    }
  }
  
  Future<bool> deleteInstallmentTransactions({
    required String installmentId,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    try {
      final response = await supabase.rpc('delete_installment_transactions', params: {
        'p_installment_id': installmentId,
        'p_user_id': userId,
      });
      
      return response as bool;
    } catch (e) {
      print('Error deleting installment transactions: $e');
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getInstallmentSummary({
    DateTime? month,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    try {
      final params = {
        'p_user_id': userId,
      };
      
      if (month != null) {
        params['p_month'] = month.toIso8601String().split('T')[0];
      }
      
      final response = await supabase.rpc('get_installment_summary', params: params);
      
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error getting installment summary: $e');
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
  
  // Recurring Transaction Methods
  Future<List<Map<String, dynamic>>> getRecurringTransactions() async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    try {
      final response = await supabase
          .from('recurring_transactions')
          .select('*, categories(*)')
          .eq('user_id', userId)
          .order('next_date', ascending: true);
      
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error getting recurring transactions: $e');
      return [];
    }
  }
  
  Future<void> addRecurringTransaction({
    required String categoryId,
    required double amount,
    required String type,
    required String frequency,
    required DateTime startDate,
    int intervalValue = 1,
    int? dayOfMonth,
    int? dayOfWeek,
    DateTime? endDate,
    String? description,
    String? merchant,
    String? paymentMethod,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    try {
      // Calculate next_date based on frequency and parameters
      DateTime nextDate = startDate;
      final now = DateTime.now();
      
      if (frequency == 'monthly' && dayOfMonth != null) {
        if (dayOfMonth == 99) {
          // Last day of month
          nextDate = DateTime(startDate.year, startDate.month + 1, 0);
          // If the calculated date is in the past, move to next month
          while (nextDate.isBefore(now)) {
            nextDate = DateTime(nextDate.year, nextDate.month + 2, 0);
          }
        } else {
          // Specific day of month
          nextDate = DateTime(startDate.year, startDate.month, dayOfMonth);
          // Handle if the day doesn't exist in the month
          if (nextDate.day != dayOfMonth) {
            nextDate = DateTime(startDate.year, startDate.month + 1, 0);
          }
          // If the calculated date is in the past, move to next month
          while (nextDate.isBefore(now)) {
            final nextMonth = nextDate.month == 12 ? 1 : nextDate.month + 1;
            final nextYear = nextDate.month == 12 ? nextDate.year + 1 : nextDate.year;
            nextDate = DateTime(nextYear, nextMonth, dayOfMonth);
            // Handle if the day doesn't exist in the next month
            if (nextDate.day != dayOfMonth) {
              nextDate = DateTime(nextYear, nextMonth + 1, 0);
            }
          }
        }
      } else if (frequency == 'weekly' && dayOfWeek != null) {
        // Find next occurrence of the specified weekday
        while (nextDate.weekday != dayOfWeek % 7 || nextDate.isBefore(now)) {
          nextDate = nextDate.add(const Duration(days: 1));
        }
      } else if (frequency == 'daily') {
        // For daily frequency, ensure next date is not in the past
        while (nextDate.isBefore(now)) {
          nextDate = nextDate.add(Duration(days: intervalValue));
        }
      } else if (frequency == 'yearly') {
        // For yearly frequency, ensure next date is not in the past
        while (nextDate.isBefore(now)) {
          nextDate = DateTime(nextDate.year + intervalValue, nextDate.month, nextDate.day);
        }
      }
      
      await supabase.from('recurring_transactions').insert({
        'user_id': userId,
        'category_id': categoryId,
        'amount': amount,
        'type': type,
        'frequency': frequency,
        'interval_value': intervalValue,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
        'next_date': nextDate.toIso8601String().split('T')[0],
        'day_of_month': dayOfMonth,
        'day_of_week': dayOfWeek,
        'description': description,
        'merchant': merchant,
        'payment_method': paymentMethod,
        'is_active': true,
      });
    } catch (e) {
      print('Error adding recurring transaction: $e');
      rethrow;
    }
  }
  
  Future<void> updateRecurringTransaction({
    required String id,
    String? categoryId,
    double? amount,
    String? type,
    String? frequency,
    DateTime? startDate,
    int? intervalValue,
    int? dayOfMonth,
    int? dayOfWeek,
    DateTime? endDate,
    bool? isActive,
    String? description,
    String? merchant,
    String? paymentMethod,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (categoryId != null) updateData['category_id'] = categoryId;
      if (amount != null) updateData['amount'] = amount;
      if (type != null) updateData['type'] = type;
      if (frequency != null) updateData['frequency'] = frequency;
      if (intervalValue != null) updateData['interval_value'] = intervalValue;
      if (dayOfMonth != null) updateData['day_of_month'] = dayOfMonth;
      if (dayOfWeek != null) updateData['day_of_week'] = dayOfWeek;
      if (startDate != null) updateData['start_date'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) updateData['end_date'] = endDate.toIso8601String().split('T')[0];
      if (isActive != null) updateData['is_active'] = isActive;
      if (description != null) updateData['description'] = description;
      if (merchant != null) updateData['merchant'] = merchant;
      if (paymentMethod != null) updateData['payment_method'] = paymentMethod;
      
      // If frequency, startDate, dayOfMonth, or dayOfWeek changed, recalculate next_date
      if (frequency != null || startDate != null || dayOfMonth != null || dayOfWeek != null || intervalValue != null) {
        // Fetch current data to fill in missing values
        final currentData = await supabase
            .from('recurring_transactions')
            .select()
            .eq('id', id)
            .eq('user_id', userId)
            .single();
        
        final actualFrequency = frequency ?? currentData['frequency'] as String;
        final actualStartDate = startDate ?? DateTime.parse(currentData['start_date']);
        final actualIntervalValue = intervalValue ?? currentData['interval_value'] as int;
        final actualDayOfMonth = dayOfMonth ?? currentData['day_of_month'] as int?;
        final actualDayOfWeek = dayOfWeek ?? currentData['day_of_week'] as int?;
        
        // Calculate next_date
        DateTime nextDate = actualStartDate;
        final now = DateTime.now();
        
        if (actualFrequency == 'monthly' && actualDayOfMonth != null) {
          if (actualDayOfMonth == 99) {
            // Last day of month
            nextDate = DateTime(actualStartDate.year, actualStartDate.month + 1, 0);
            // If the calculated date is in the past, move to next month
            while (nextDate.isBefore(now)) {
              nextDate = DateTime(nextDate.year, nextDate.month + 2, 0);
            }
          } else {
            // Specific day of month
            nextDate = DateTime(actualStartDate.year, actualStartDate.month, actualDayOfMonth);
            // Handle if the day doesn't exist in the month
            if (nextDate.day != actualDayOfMonth) {
              nextDate = DateTime(actualStartDate.year, actualStartDate.month + 1, 0);
            }
            // If the calculated date is in the past, move to next month
            while (nextDate.isBefore(now)) {
              final nextMonth = nextDate.month == 12 ? 1 : nextDate.month + 1;
              final nextYear = nextDate.month == 12 ? nextDate.year + 1 : nextDate.year;
              nextDate = DateTime(nextYear, nextMonth, actualDayOfMonth);
              // Handle if the day doesn't exist in the next month
              if (nextDate.day != actualDayOfMonth) {
                nextDate = DateTime(nextYear, nextMonth + 1, 0);
              }
            }
          }
        } else if (actualFrequency == 'weekly' && actualDayOfWeek != null) {
          // Find next occurrence of the specified weekday
          while (nextDate.weekday != actualDayOfWeek % 7 || nextDate.isBefore(now)) {
            nextDate = nextDate.add(const Duration(days: 1));
          }
        } else if (actualFrequency == 'daily') {
          // For daily frequency, ensure next date is not in the past
          while (nextDate.isBefore(now)) {
            nextDate = nextDate.add(Duration(days: actualIntervalValue));
          }
        } else if (actualFrequency == 'yearly') {
          // For yearly frequency, ensure next date is not in the past
          while (nextDate.isBefore(now)) {
            nextDate = DateTime(nextDate.year + actualIntervalValue, nextDate.month, nextDate.day);
          }
        }
        
        updateData['next_date'] = nextDate.toIso8601String().split('T')[0];
      }
      
      await supabase
          .from('recurring_transactions')
          .update(updateData)
          .eq('id', id)
          .eq('user_id', userId);
    } catch (e) {
      print('Error updating recurring transaction: $e');
      rethrow;
    }
  }
  
  Future<void> deleteRecurringTransaction(String id) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    try {
      await supabase
          .from('recurring_transactions')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
    } catch (e) {
      print('Error deleting recurring transaction: $e');
      rethrow;
    }
  }
  
  Future<int> processRecurringTransactions() async {
    try {
      final response = await supabase.rpc('process_recurring_transactions_for_date', params: {
        'p_date': DateTime.now().toIso8601String().split('T')[0],
      });
      
      return response as int;
    } catch (e) {
      print('Error processing recurring transactions: $e');
      return 0;
    }
  }
}