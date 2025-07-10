import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart' as models;

class TransactionFormScreen extends StatefulWidget {
  final Transaction? transaction;
  final DateTime initialDate;
  
  const TransactionFormScreen({
    Key? key,
    this.transaction,
    required this.initialDate,
  }) : super(key: key);

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _merchantController;
  late DateTime _selectedDate;
  String _transactionType = 'expense';
  models.Category? _selectedCategory;
  
  final _formKey = GlobalKey<FormState>();
  final _amountFocusNode = FocusNode();
  final _numberFormat = NumberFormat('#,###');
  
  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController(
      text: widget.transaction?.description ?? '',
    );
    _merchantController = TextEditingController(
      text: widget.transaction?.merchant ?? '',
    );
    _selectedDate = widget.transaction?.transactionDate ?? widget.initialDate;
    _transactionType = widget.transaction?.type ?? 'expense';
    
    // Load categories
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<TransactionProvider>();
      await provider.loadCategories();
      
      // Set selected category if editing
      if (widget.transaction != null && mounted) {
        final categories = provider.categories;
        final matchingCategory = categories.firstWhere(
          (c) => c.id == widget.transaction!.categoryId,
          orElse: () => categories.first,
        );
        setState(() {
          _selectedCategory = matchingCategory;
        });
      }
    });
    
    // Format amount if editing
    if (widget.transaction != null) {
      _amountController.text = _numberFormat.format(widget.transaction!.amount.toInt());
    }
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }
  
  String _formatCurrency(String value) {
    // Remove all non-digits
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    
    // Format with thousand separators
    int number = int.parse(digits);
    return _numberFormat.format(number);
  }
  
  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryPickerSheet(
        transactionType: _transactionType,
        onCategorySelected: (category) {
          setState(() {
            _selectedCategory = category;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
  
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ko', 'KR'),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리를 선택해주세요')),
      );
      return;
    }
    
    final provider = context.read<TransactionProvider>();
    
    try {
      final amountText = _amountController.text.replaceAll(',', '');
      final amount = double.parse(amountText);
      
      if (widget.transaction == null) {
        // Create new transaction
        await provider.addTransaction(
          categoryId: _selectedCategory!.id,
          amount: amount,
          type: _transactionType,
          date: _selectedDate,
          description: _descriptionController.text.trim(),
          merchant: _merchantController.text.trim().isEmpty ? null : _merchantController.text.trim(),
        );
      } else {
        // Update existing transaction
        await provider.updateTransaction(
          transactionId: widget.transaction!.id,
          categoryId: _selectedCategory!.id,
          amount: amount,
          type: _transactionType,
          date: _selectedDate,
          description: _descriptionController.text.trim(),
          merchant: _merchantController.text.trim().isEmpty ? null : _merchantController.text.trim(),
        );
      }
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.transaction == null ? '거래 추가' : '거래 수정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: provider.isLoading ? null : _saveTransaction,
            child: Text(
              '저장',
              style: TextStyle(
                color: provider.isLoading ? Colors.grey : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Transaction Type Selector
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _transactionType = 'expense'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _transactionType == 'expense' 
                                    ? Colors.red 
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            '지출',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: _transactionType == 'expense' 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                              color: _transactionType == 'expense' 
                                  ? Colors.red 
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _transactionType = 'income'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _transactionType == 'income' 
                                    ? Colors.blue 
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            '수입',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: _transactionType == 'income' 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                              color: _transactionType == 'income' 
                                  ? Colors.blue 
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Amount Input
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '금액',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      focusNode: _amountFocusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _transactionType == 'expense' ? Colors.red : Colors.blue,
                      ),
                      decoration: InputDecoration(
                        suffixText: '원',
                        suffixStyle: TextStyle(
                          fontSize: 20,
                          color: _transactionType == 'expense' ? Colors.red : Colors.blue,
                        ),
                        border: InputBorder.none,
                        hintText: '0',
                      ),
                      onChanged: (value) {
                        final formatted = _formatCurrency(value);
                        if (formatted != value) {
                          _amountController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(
                              offset: formatted.length,
                            ),
                          );
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '금액을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Category Selector
              Container(
                color: Colors.white,
                child: ListTile(
                  title: const Text('카테고리'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedCategory != null) ...[
                        Text(
                          _selectedCategory!.icon ?? '',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedCategory!.name,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ] else
                        const Text(
                          '선택하세요',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  onTap: _showCategoryPicker,
                ),
              ),
              
              const SizedBox(height: 1),
              
              // Date Selector
              Container(
                color: Colors.white,
                child: ListTile(
                  title: const Text('날짜'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  onTap: _selectDate,
                ),
              ),
              
              const SizedBox(height: 1),
              
              // Merchant Input
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '사용처',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _merchantController,
                      decoration: const InputDecoration(
                        hintText: '사용처를 입력하세요 (선택사항)',
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Description Input
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '메모',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: '메모를 입력하세요 (선택사항)',
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Category Picker Bottom Sheet
class CategoryPickerSheet extends StatelessWidget {
  final String transactionType;
  final Function(models.Category) onCategorySelected;
  
  const CategoryPickerSheet({
    Key? key,
    required this.transactionType,
    required this.onCategorySelected,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final categories = provider.getCategoriesByType(transactionType);
    
    print('CategoryPickerSheet: transactionType=$transactionType');
    print('CategoryPickerSheet: Available categories: ${categories.length}');
    print('CategoryPickerSheet: Categories: ${categories.map((c) => '${c.name} (${c.type})').join(', ')}');
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              transactionType == 'expense' ? '지출 카테고리' : '수입 카테고리',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return GestureDetector(
                  onTap: () => onCategorySelected(category),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(int.parse(
                            category.color?.replaceAll('#', '0xFF') ?? '0xFFE0E0E0'
                          )).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            category.icon ?? '📌',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.name,
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}