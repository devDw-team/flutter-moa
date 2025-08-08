import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/category.dart' as models;
import '../services/supabase_service.dart';

class TransactionProvider extends ChangeNotifier {
  final _supabaseService = SupabaseService.instance;
  
  List<Transaction> _transactions = [];
  List<models.Category> _categories = [];
  Map<String, double> _monthlySummary = {};
  bool _isLoading = false;
  String? _error;

  List<Transaction> get transactions => _transactions;
  List<models.Category> get categories => _categories;
  Map<String, double> get monthlySummary => _monthlySummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<models.Category> getCategoriesByType(String type) {
    return _categories.where((c) => c.type == type).toList();
  }

  Future<void> loadTransactions(DateTime month) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabaseService.getMonthlyTransactions(month);
      _transactions = response.map((e) => Transaction.fromJson(e)).toList();
      
      // Load monthly summary
      _monthlySummary = await _supabaseService.getMonthlySummary(month);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      print('Loading categories...');
      final response = await _supabaseService.getCategories();
      print('Fetched ${response.length} categories from Supabase');
      _categories = response.map((e) => models.Category.fromJson(e)).toList();
      print('Categories loaded: ${_categories.map((c) => '${c.name} (${c.type})').join(', ')}');
      notifyListeners();
    } catch (e) {
      print('Error loading categories: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addTransaction({
    required String categoryId,
    required double amount,
    required String type,
    required DateTime date,
    String? description,
    String? merchant,
    List<String>? tags,
  }) async {
    try {
      await _supabaseService.addTransaction(
        categoryId: categoryId,
        amount: amount,
        type: type,
        date: date,
        description: description,
        merchant: merchant,
        tags: tags,
      );
      
      // Reload transactions for the month
      await loadTransactions(date);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
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
    try {
      // Get the original transaction to know which month to reload
      final originalTransaction = _transactions.firstWhere((t) => t.id == transactionId);
      final originalDate = originalTransaction.transactionDate;
      
      await _supabaseService.updateTransaction(
        transactionId: transactionId,
        categoryId: categoryId,
        amount: amount,
        type: type,
        date: date,
        description: description,
        merchant: merchant,
        tags: tags,
      );
      
      // Reload transactions for the month
      final dateToReload = date ?? originalDate;
      await loadTransactions(dateToReload);
      
      // Also reload if the month changed
      if (date != null && 
          (date.year != originalDate.year || date.month != originalDate.month)) {
        await loadTransactions(originalDate);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      // Get the transaction date before deleting to know which month to reload
      final transaction = _transactions.firstWhere((t) => t.id == transactionId);
      final transactionDate = transaction.transactionDate;
      
      await _supabaseService.deleteTransaction(transactionId);
      
      // Remove from local list
      _transactions.removeWhere((t) => t.id == transactionId);
      
      // Reload monthly summary for the affected month
      _monthlySummary = await _supabaseService.getMonthlySummary(transactionDate);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    try {
      await _supabaseService.addCategory(
        name: name,
        type: type,
        icon: icon,
        color: color,
      );
      
      // Reload categories
      await loadCategories();
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