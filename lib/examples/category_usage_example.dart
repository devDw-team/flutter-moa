import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Example widget showing how to fetch and display categories from Supabase
class CategoryUsageExample extends StatefulWidget {
  const CategoryUsageExample({Key? key}) : super(key: key);

  @override
  State<CategoryUsageExample> createState() => _CategoryUsageExampleState();
}

class _CategoryUsageExampleState extends State<CategoryUsageExample> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> expenseCategories = [];
  List<Map<String, dynamic>> incomeCategories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      // Fetch system categories (the ones we just added)
      final response = await supabase
          .from('categories')
          .select('id, name, type, icon, color, sort_order')
          .eq('is_system', true)
          .order('type')
          .order('sort_order');

      final categories = List<Map<String, dynamic>>.from(response);
      
      setState(() {
        expenseCategories = categories
            .where((cat) => cat['type'] == 'expense')
            .toList();
        incomeCategories = categories
            .where((cat) => cat['type'] == 'income')
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('카테고리'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '지출'),
              Tab(text: '수입'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCategoryList(expenseCategories),
            _buildCategoryList(incomeCategories),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<Map<String, dynamic>> categories) {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Color(
              int.parse(category['color'].substring(1), radix: 16) + 0xFF000000,
            ),
            child: Text(
              category['icon'] ?? '📌',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          title: Text(category['name']),
          subtitle: Text('시스템 카테고리'),
          onTap: () {
            // Handle category selection
            Navigator.pop(context, category);
          },
        );
      },
    );
  }
}

/// Example of how to use categories when adding a transaction
class AddTransactionExample extends StatefulWidget {
  const AddTransactionExample({Key? key}) : super(key: key);

  @override
  State<AddTransactionExample> createState() => _AddTransactionExampleState();
}

class _AddTransactionExampleState extends State<AddTransactionExample> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? selectedCategory;
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  String transactionType = 'expense';

  Future<void> _selectCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryUsageExample(),
      ),
    );
    
    if (result != null) {
      setState(() {
        selectedCategory = result;
        transactionType = result['type'];
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (selectedCategory == null || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리와 금액을 입력해주세요')),
      );
      return;
    }

    try {
      final userId = supabase.auth.currentUser!.id;
      
      await supabase.from('transactions').insert({
        'user_id': userId,
        'category_id': selectedCategory!['id'],
        'amount': double.parse(amountController.text),
        'type': transactionType,
        'transaction_date': selectedDate.toIso8601String().split('T')[0],
        'description': descriptionController.text.isEmpty 
            ? null 
            : descriptionController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('거래가 저장되었습니다')),
      );
      
      // Clear form
      setState(() {
        selectedCategory = null;
        amountController.clear();
        descriptionController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('거래 추가'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category selector
            Card(
              child: ListTile(
                title: Text(selectedCategory?['name'] ?? '카테고리 선택'),
                subtitle: selectedCategory != null
                    ? Text(transactionType == 'expense' ? '지출' : '수입')
                    : null,
                leading: selectedCategory != null
                    ? CircleAvatar(
                        backgroundColor: Color(
                          int.parse(selectedCategory!['color'].substring(1), 
                              radix: 16) + 0xFF000000,
                        ),
                        child: Text(selectedCategory!['icon']),
                      )
                    : const Icon(Icons.category),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selectCategory,
              ),
            ),
            const SizedBox(height: 16),
            
            // Amount input
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '금액',
                prefixText: '₩ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Description input
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '메모 (선택사항)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Date selector
            Card(
              child: ListTile(
                title: const Text('날짜'),
                subtitle: Text(
                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                ),
                leading: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
            
            // Save button
            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                '저장',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}

/// System categories that are now in your database:
/// 
/// Expense Categories (지출 카테고리):
/// - 식비 (Food)
/// - 카페/간식 (Cafe/Snacks)
/// - 유흥 (Entertainment)
/// - 생필품 (Daily Necessities)
/// - 쇼핑 (Shopping)
/// - 교통 (Transportation)
/// - 자동차/주유비 (Car/Gas)
/// - 주거/통신 (Housing/Communication)
/// - 의료/건강 (Medical/Health)
/// - 금융 (Finance)
/// - 문화/여가 (Culture/Leisure)
/// - 여행/숙박 (Travel/Accommodation)
/// - 교육 (Education)
/// - 자녀 (Children)
/// - 경조사 (Special Occasions)
/// - 기타 (Others)
/// 
/// Income Categories (수입 카테고리):
/// - 급여 (Salary)
/// - 용돈 (Allowance)
/// - 부업 (Side Job)
/// - 금융 (Finance)
/// - 기타 (Others)