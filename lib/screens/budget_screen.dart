import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../services/supabase_service.dart';

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
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }
  
  Future<void> _loadBudgetData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load current month budget
      final budget = await _supabaseService.getCurrentMonthBudget();
      if (budget != null) {
        _monthlyBudget = (budget['amount'] as num).toDouble();
      }
      
      // Load monthly summary
      final summary = await _supabaseService.getMonthlySummary(DateTime.now());
      
      setState(() {
        _totalIncome = summary['income'] ?? 0;
        _totalExpense = summary['expense'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading budget data: $e');
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _showBudgetDialog() async {
    final controller = TextEditingController(
      text: _monthlyBudget > 0 ? NumberFormat('#,###').format(_monthlyBudget) : '',
    );
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('월 예산 설정'),
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
                    month: DateTime.now(),
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
  
  @override
  Widget build(BuildContext context) {
    final budgetUsage = _monthlyBudget > 0 ? (_totalExpense / _monthlyBudget * 100) : 0.0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('예산 관리'),
        actions: [
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
                    // Monthly Budget Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${DateFormat('yyyy년 MM월').format(DateTime.now())} 예산',
                              style: Theme.of(context).textTheme.titleLarge,
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