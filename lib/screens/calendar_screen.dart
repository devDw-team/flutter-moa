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
    
    // Load categories on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadCategories();
    });
    
    _loadMonthData(_focusedDay);
    _loadDayTransactions(_selectedDay);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터 로드 실패: ${e.toString()}')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('거래 로드 실패: ${e.toString()}')),
      );
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
      await _supabaseService.deleteTransaction(transaction.id);
      await _loadDayTransactions(_selectedDay);
      await _loadMonthData(_focusedDay);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('거래가 삭제되었습니다')),
      );
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
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              try {
                await authProvider.signOut();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('로그아웃 실패: $e')),
                  );
                }
              }
            },
          ),
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
                return _buildEventMarker(day, events);
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
                                  backgroundColor: Colors.blue,
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
                                child: Text(
                                  transaction.category?.icon ?? 
                                  (transaction.type == 'income' ? '💰' : '💸'),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              title: Text(
                                transaction.category?.name ?? '미분류',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: transaction.description != null
                                  ? Text(
                                      transaction.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
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