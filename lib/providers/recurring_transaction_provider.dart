import 'package:flutter/foundation.dart';
import '../models/recurring_transaction.dart';
import '../models/category.dart' as models;
import '../services/supabase_service.dart';

class RecurringTransactionProvider extends ChangeNotifier {
  final _supabaseService = SupabaseService.instance;
  
  List<RecurringTransaction> _recurringTransactions = [];
  bool _isLoading = false;
  String? _error;

  List<RecurringTransaction> get recurringTransactions => _recurringTransactions;
  List<RecurringTransaction> get activeRecurringTransactions => 
      _recurringTransactions.where((rt) => rt.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRecurringTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabaseService.getRecurringTransactions();
      _recurringTransactions = response.map((e) => RecurringTransaction.fromJson(e)).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
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
    try {
      await _supabaseService.addRecurringTransaction(
        categoryId: categoryId,
        amount: amount,
        type: type,
        frequency: frequency,
        startDate: startDate,
        intervalValue: intervalValue,
        dayOfMonth: dayOfMonth,
        dayOfWeek: dayOfWeek,
        endDate: endDate,
        description: description,
        merchant: merchant,
        paymentMethod: paymentMethod,
      );
      
      // Reload recurring transactions
      await loadRecurringTransactions();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
    try {
      await _supabaseService.updateRecurringTransaction(
        id: id,
        categoryId: categoryId,
        amount: amount,
        type: type,
        frequency: frequency,
        startDate: startDate,
        intervalValue: intervalValue,
        dayOfMonth: dayOfMonth,
        dayOfWeek: dayOfWeek,
        endDate: endDate,
        isActive: isActive,
        description: description,
        merchant: merchant,
        paymentMethod: paymentMethod,
      );
      
      // Reload recurring transactions
      await loadRecurringTransactions();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRecurringTransaction(String id) async {
    try {
      await _supabaseService.deleteRecurringTransaction(id);
      
      // Remove from local list
      _recurringTransactions.removeWhere((rt) => rt.id == id);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleRecurringTransaction(String id, bool isActive) async {
    try {
      await _supabaseService.updateRecurringTransaction(
        id: id,
        isActive: isActive,
      );
      
      // Update local list
      final index = _recurringTransactions.indexWhere((rt) => rt.id == id);
      if (index != -1) {
        _recurringTransactions[index] = _recurringTransactions[index].copyWith(
          isActive: isActive,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<int> processRecurringTransactions() async {
    try {
      final count = await _supabaseService.processRecurringTransactions();
      
      // Reload recurring transactions to get updated next dates
      await loadRecurringTransactions();
      
      return count;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}