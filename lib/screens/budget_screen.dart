import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../services/supabase_service.dart';
import '../models/category.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _supabaseService = SupabaseService.instance;
  double _monthlyBudget = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  List<Map<String, dynamic>> _categoryAnalysis = [];
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();
  final PageController _pageController = PageController(initialPage: 999); // Start at a high number
  int _displayedCategoryCount = 5; // Initially show 5 categories
  
  @override
  void initState() {
    super.initState();
    _loadBudgetData();
    
    // Load initial transaction data for current month
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions(_selectedMonth);
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  Future<void> _loadBudgetData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load budget for selected month
      final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      
      final budgets = await _supabaseService.supabase
          .from('budgets')
          .select()
          .eq('user_id', _supabaseService.currentUser!.id)
          .eq('period_type', 'monthly')
          .gte('start_date', startDate.toIso8601String().split('T')[0])
          .lte('start_date', endDate.toIso8601String().split('T')[0])
          .eq('is_active', true)
          .maybeSingle();
      
      if (budgets != null) {
        _monthlyBudget = (budgets['amount'] as num).toDouble();
      } else {
        _monthlyBudget = 0;
      }
      
      // Load monthly summary
      final summary = await _supabaseService.getMonthlySummary(_selectedMonth);
      
      // Load category analysis
      final categoryData = await _supabaseService.getCategoryAnalysis(_selectedMonth);
      
      setState(() {
        _totalIncome = summary['income'] ?? 0;
        _totalExpense = summary['expense'] ?? 0;
        _categoryAnalysis = categoryData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading budget data: $e');
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadCategoryAnalysis() async {
    try {
      // Load category analysis
      final categoryData = await _supabaseService.getCategoryAnalysis(_selectedMonth);
      
      if (mounted) {
        setState(() {
          _categoryAnalysis = categoryData;
        });
      }
    } catch (e) {
      print('Error loading category analysis: $e');
    }
  }
  
  Future<void> _showBudgetDialog() async {
    final controller = TextEditingController(
      text: _monthlyBudget > 0 ? NumberFormat('#,###').format(_monthlyBudget) : '',
    );
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_selectedMonth.year}년 ${_selectedMonth.month}월 예산 설정'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _ThousandsSeparatorInputFormatter(),
          ],
          decoration: const InputDecoration(
            labelText: '예산 금액',
            suffixText: '원',
            hintText: '0',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final cleanText = controller.text.replaceAll(',', '');
              final newBudget = double.tryParse(cleanText) ?? 0;
              
              if (newBudget > 0) {
                try {
                  await _supabaseService.createOrUpdateBudget(
                    amount: newBudget,
                    month: _selectedMonth,
                  );
                  
                  setState(() {
                    _monthlyBudget = newBudget;
                  });
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('예산이 저장되었습니다')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('예산 저장 실패: $e')),
                    );
                  }
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
  
  void _changeMonth(int months) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + months,
        1,
      );
      // Reset displayed category count when changing month
      _displayedCategoryCount = 5;
    });
    _loadBudgetData();
  }
  
  @override
  Widget build(BuildContext context) {
    // Watch TransactionProvider to get real-time updates
    final transactionProvider = context.watch<TransactionProvider>();
    
    // Use monthly summary from TransactionProvider if available and for current month
    final isCurrentMonth = _selectedMonth.year == DateTime.now().year && 
                          _selectedMonth.month == DateTime.now().month;
    
    // Update totals from provider if current month
    if (isCurrentMonth && transactionProvider.monthlySummary.isNotEmpty) {
      // Update income and expense from provider
      final newIncome = transactionProvider.monthlySummary['income'] ?? 0;
      final newExpense = transactionProvider.monthlySummary['expense'] ?? 0;
      
      // If values changed, update state and reload category analysis
      if (newIncome != _totalIncome || newExpense != _totalExpense) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _totalIncome = newIncome;
            _totalExpense = newExpense;
          });
          // Reload category analysis when transactions change
          _loadCategoryAnalysis();
        });
      }
    }
    
    final budgetUsage = _monthlyBudget > 0 ? (_totalExpense / _monthlyBudget * 100) : 0.0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('예산 관리'),
        actions: [
          if (isCurrentMonth || _selectedMonth.isAfter(DateTime.now()))
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _showBudgetDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBudgetData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month Selector
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () => _changeMonth(-1),
                            ),
                            Text(
                              DateFormat('yyyy년 MM월').format(_selectedMonth),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => _changeMonth(1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Monthly Budget Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '월 예산',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                if (_monthlyBudget == 0 && (isCurrentMonth || _selectedMonth.isAfter(DateTime.now())))
                                  TextButton(
                                    onPressed: _showBudgetDialog,
                                    child: const Text('예산 설정'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('설정 예산'),
                                Text(
                                  '${NumberFormat('#,###').format(_monthlyBudget)}원',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('현재 지출'),
                                Text(
                                  '${NumberFormat('#,###').format(_totalExpense)}원',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: budgetUsage > 100 ? Colors.red : Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: budgetUsage / 100,
                              minHeight: 8,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                budgetUsage > 100 ? Colors.red : Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '예산 사용률: ${budgetUsage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: budgetUsage > 100 ? Colors.red : Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Income vs Expense Chart
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '수입 vs 지출',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 200,
                              child: (_totalIncome == 0 && _totalExpense == 0)
                                  ? Center(
                                      child: Text(
                                        '이번 달 거래 내역이 없습니다',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                    )
                                  : BarChart(
                                      BarChartData(
                                        alignment: BarChartAlignment.spaceAround,
                                        maxY: [_totalIncome, _totalExpense, 1000.0].reduce((a, b) => a > b ? a : b) * 1.2,
                                        barTouchData: BarTouchData(enabled: false),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                switch (value.toInt()) {
                                                  case 0:
                                                    return const Text('수입');
                                                  case 1:
                                                    return const Text('지출');
                                                  default:
                                                    return const Text('');
                                                }
                                              },
                                            ),
                                          ),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 80,
                                              getTitlesWidget: (value, meta) {
                                                return Text(
                                                  '${NumberFormat('#,###').format(value)}',
                                                  style: const TextStyle(fontSize: 12),
                                                );
                                              },
                                            ),
                                          ),
                                          topTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                        ),
                                        gridData: FlGridData(
                                          show: true,
                                          drawVerticalLine: false,
                                          horizontalInterval: [_totalIncome, _totalExpense, 1000.0].reduce((a, b) => a > b ? a : b) * 0.25,
                                        ),
                                        borderData: FlBorderData(show: false),
                                        barGroups: [
                                          BarChartGroupData(
                                            x: 0,
                                            barRods: [
                                              BarChartRodData(
                                                toY: _totalIncome,
                                                color: Colors.green,
                                                width: 40,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ],
                                          ),
                                          BarChartGroupData(
                                            x: 1,
                                            barRods: [
                                              BarChartRodData(
                                                toY: _totalExpense,
                                                color: Colors.red,
                                                width: 40,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Summary Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '월간 요약',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('총 수입'),
                                Text(
                                  '+${NumberFormat('#,###').format(_totalIncome)}원',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('총 지출'),
                                Text(
                                  '-${NumberFormat('#,###').format(_totalExpense)}원',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('잔액'),
                                Text(
                                  '${NumberFormat('#,###').format(_totalIncome - _totalExpense)}원',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: (_totalIncome - _totalExpense) >= 0 
                                        ? Colors.blue 
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Category Analysis Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '카테고리별 지출',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            if (_categoryAnalysis.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 32),
                                  child: Text(
                                    '이번 달 지출 내역이 없습니다',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...List.generate(
                                _categoryAnalysis.length > _displayedCategoryCount 
                                    ? _displayedCategoryCount 
                                    : _categoryAnalysis.length,
                                (index) {
                                  final categoryData = _categoryAnalysis[index];
                                  final categoryName = categoryData['category_name'] ?? '미분류';
                                  final totalAmount = (categoryData['total_amount'] as num).toDouble();
                                  final percentage = _totalExpense > 0 ? (totalAmount / _totalExpense * 100) : 0.0;
                                  final category = context.read<TransactionProvider>().categories
                                      .firstWhere((c) => c.name == categoryName,
                                          orElse: () => Category(
                                            id: '',
                                            name: categoryName,
                                            type: 'expense',
                                            icon: '💰',
                                            color: '#808080',
                                            sortOrder: 999,
                                            isSystem: true,
                                            createdAt: DateTime.now(),
                                            updatedAt: DateTime.now(),
                                          ));
                                  
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Color(
                                                int.parse(category.color?.replaceAll('#', '0xFF') ?? '0xFF808080'),
                                              ).withOpacity(0.2),
                                              child: Text(
                                                category.icon ?? '💰',
                                                style: const TextStyle(fontSize: 18),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        categoryName,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${NumberFormat('#,###').format(totalAmount.toInt())}원',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Stack(
                                                    children: [
                                                      Container(
                                                        height: 6,
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey[300],
                                                          borderRadius: BorderRadius.circular(3),
                                                        ),
                                                      ),
                                                      Container(
                                                        height: 6,
                                                        width: MediaQuery.of(context).size.width * percentage / 100 * 0.8,
                                                        decoration: BoxDecoration(
                                                          color: Color(
                                                            int.parse(category.color?.replaceAll('#', '0xFF') ?? '0xFF808080'),
                                                          ),
                                                          borderRadius: BorderRadius.circular(3),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${percentage.toStringAsFixed(1)}%',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (index < (_categoryAnalysis.length > _displayedCategoryCount 
                                            ? _displayedCategoryCount - 1 
                                            : _categoryAnalysis.length - 1))
                                          const Divider(height: 16),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            if (_categoryAnalysis.length > _displayedCategoryCount)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        '외 ${_categoryAnalysis.length - _displayedCategoryCount}개 카테고리',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _displayedCategoryCount += 5;
                                          });
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Text('더보기'),
                                            SizedBox(width: 4),
                                            Icon(Icons.expand_more, size: 20),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all commas to get the raw number
    final String newText = newValue.text.replaceAll(',', '');
    
    // Check if it's a valid number
    final number = int.tryParse(newText);
    if (number == null) {
      return oldValue;
    }

    // Format with commas
    final formattedText = NumberFormat('#,###').format(number);
    
    // Return new value with formatted text
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: formattedText.length,
      ),
    );
  }
}