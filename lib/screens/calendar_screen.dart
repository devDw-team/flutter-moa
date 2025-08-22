import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/transaction.dart';
import '../services/supabase_service.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import 'transaction_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _supabaseService = SupabaseService.instance;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late DateTime _firstDay;
  late DateTime _lastDay;
  Map<DateTime, List<DailySummary>> _dailySummaries = {};
  List<Transaction> _selectedDayTransactions = [];
  bool _isLoadingMonth = false;
  bool _isLoadingDay = false;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _firstDay = DateTime.now().subtract(const Duration(days: 365));
    _lastDay = DateTime.now().add(const Duration(days: 365));
    
    // Load categories and data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // First load categories
        await context.read<TransactionProvider>().loadCategories();
        
        // Then load transaction data
        await _loadMonthData(_focusedDay);
        await _loadDayTransactions(_selectedDay);
      } catch (e) {
        print('Error during initial data load: $e');
      }
    });
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _loadMonthData(DateTime month) async {
    setState(() => _isLoadingMonth = true);
    
    try {
      final transactions = await _supabaseService.getMonthlyTransactions(month);
      final summaries = <DateTime, List<DailySummary>>{};
      
      for (final transaction in transactions) {
        final date = _normalizeDate(DateTime.parse(transaction['transaction_date']));
        final type = transaction['type'] as String;
        final amount = (transaction['amount'] as num).toDouble();
        
        if (!summaries.containsKey(date)) {
          summaries[date] = [];
        }
        
        final existingSummary = summaries[date]!.firstWhere(
          (s) => s.type == type,
          orElse: () => DailySummary(
            userId: transaction['user_id'],
            transactionDate: date,
            type: type,
            totalAmount: 0,
            transactionCount: 0,
            transactionIds: [],
          ),
        );
        
        if (!summaries[date]!.contains(existingSummary)) {
          summaries[date]!.add(existingSummary);
        }
        
        summaries[date] = summaries[date]!.map((s) {
          if (s.type == type) {
            return DailySummary(
              userId: s.userId,
              transactionDate: s.transactionDate,
              type: s.type,
              totalAmount: s.totalAmount + amount,
              transactionCount: s.transactionCount + 1,
              transactionIds: [...s.transactionIds, transaction['id']],
            );
          }
          return s;
        }).toList();
      }
      
      setState(() {
        _dailySummaries = summaries;
        _isLoadingMonth = false;
      });
    } catch (e) {
      setState(() => _isLoadingMonth = false);
      print('Error loading month data: $e');
    }
  }

  Future<void> _loadDayTransactions(DateTime day) async {
    setState(() => _isLoadingDay = true);
    
    try {
      final transactions = await _supabaseService.getTransactionsByDate(day);
      setState(() {
        _selectedDayTransactions = transactions
            .map((e) => Transaction.fromJson(e))
            .toList();
        _isLoadingDay = false;
      });
    } catch (e) {
      setState(() => _isLoadingDay = false);
      print('Error loading day transactions: $e');
    }
  }

  List<DailySummary> _getEventsForDay(DateTime day) {
    return _dailySummaries[_normalizeDate(day)] ?? [];
  }

  Widget _buildEventMarker(DateTime day, List<DailySummary> summaries) {
    if (summaries.isEmpty) return const SizedBox.shrink();
    
    double income = 0;
    double expense = 0;
    
    for (final summary in summaries) {
      if (summary.type == 'income') {
        income = summary.totalAmount;
      } else if (summary.type == 'expense') {
        expense = summary.totalAmount;
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 5),
      child: Column(
        children: [
          if (income > 0)
            Text(
              '+${NumberFormat('#,###').format(income.toInt())}',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (expense > 0)
            Text(
              '-${NumberFormat('#,###').format(expense.toInt())}',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    try {
      // Check if this is an installment transaction
      if (transaction.installmentId != null) {
        // Show dialog for installment transaction deletion
        final result = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('할부 거래 삭제'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${transaction.installmentMonths}개월 할부 거래입니다.'),
                  const SizedBox(height: 8),
                  const Text('어떻게 삭제하시겠습니까?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop('cancel'),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop('single'),
                  child: const Text('이번 달만 삭제'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop('all'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('전체 할부 삭제'),
                ),
              ],
            );
          },
        );
        
        if (result == 'single') {
          // Delete only this transaction
          await context.read<TransactionProvider>().deleteTransaction(transaction.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('해당 거래가 삭제되었습니다')),
          );
        } else if (result == 'all') {
          // Delete all installment transactions
          await context.read<TransactionProvider>().deleteInstallmentTransactions(
            transaction.installmentId!,
            transaction.transactionDate,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('전체 할부 거래가 삭제되었습니다')),
          );
        } else {
          // User cancelled
          return;
        }
      } else {
        // Regular transaction - delete normally
        await context.read<TransactionProvider>().deleteTransaction(transaction.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('거래가 삭제되었습니다')),
        );
      }
      
      // Reload local data
      await _loadDayTransactions(_selectedDay);
      await _loadMonthData(_focusedDay);
      
      // Also reload transactions in provider for current month
      await context.read<TransactionProvider>().loadTransactions(_focusedDay);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('캘린더'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionFormScreen(
                    initialDate: _selectedDay,
                  ),
                ),
              );
              if (result == true) {
                await _loadMonthData(_focusedDay);
                await _loadDayTransactions(_selectedDay);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          TableCalendar<DailySummary>(
            firstDay: _firstDay,
            lastDay: _lastDay,
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            locale: 'ko_KR',
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: const TextStyle(color: Colors.red),
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                return Positioned(
                  bottom: 1,
                  child: _buildEventMarker(day, events),
                );
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadDayTransactions(selectedDay);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadMonthData(focusedDay);
            },
          ),
          const Divider(height: 1),
          
          // Selected Day Summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('yyyy년 MM월 dd일').format(_selectedDay),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isLoadingMonth)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          
          // Transaction List
          Expanded(
            child: _isLoadingDay
                ? const Center(child: CircularProgressIndicator())
                : _selectedDayTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '거래 내역이 없습니다',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _selectedDayTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _selectedDayTransactions[index];
                          return Slidable(
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (_) async {
                                    // Check if this is an installment transaction
                                    if (transaction.installmentId != null) {
                                      // Show message that installment transactions cannot be edited
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('할부 거래는 수정할 수 없습니다. 전체 할부를 삭제 후 다시 등록해주세요.'),
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                      return;
                                    }
                                    
                                    final result = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TransactionFormScreen(
                                          transaction: transaction,
                                          initialDate: _selectedDay,
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      await _loadMonthData(_focusedDay);
                                      await _loadDayTransactions(_selectedDay);
                                    }
                                  },
                                  backgroundColor: transaction.installmentId != null 
                                      ? Colors.grey 
                                      : Colors.blue,
                                  foregroundColor: Colors.white,
                                  icon: Icons.edit,
                                  label: '수정',
                                ),
                                SlidableAction(
                                  onPressed: (_) => _deleteTransaction(transaction),
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: '삭제',
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: transaction.type == 'income'
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text(
                                      transaction.category?.icon ?? 
                                      (transaction.type == 'income' ? '💰' : '💸'),
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    if (transaction.installmentMonths != null)
                                      Positioned(
                                        right: -2,
                                        bottom: -2,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${transaction.installmentMonths}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    transaction.category?.name ?? '미분류',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  if (transaction.installmentMonths != null) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.orange.withOpacity(0.5)),
                                      ),
                                      child: Text(
                                        '할부',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.orange[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (transaction.paymentMethod != null) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      transaction.paymentMethod == 'card' ? Icons.credit_card :
                                      transaction.paymentMethod == 'transfer' ? Icons.account_balance :
                                      Icons.money,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (transaction.merchant != null)
                                    Text(
                                      transaction.merchant!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (transaction.description != null)
                                    Text(
                                      transaction.description!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              trailing: Text(
                                '${transaction.type == 'income' ? '+' : '-'} ${NumberFormat('#,###').format(transaction.amount.toInt())}원',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: transaction.type == 'income'
                                      ? Colors.blue
                                      : Colors.red,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionFormScreen(
                initialDate: _selectedDay,
              ),
            ),
          );
          if (result == true) {
            await _loadMonthData(_focusedDay);
            await _loadDayTransactions(_selectedDay);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}