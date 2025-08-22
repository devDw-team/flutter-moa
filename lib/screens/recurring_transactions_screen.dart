import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/recurring_transaction.dart';
import '../providers/recurring_transaction_provider.dart';
import '../providers/transaction_provider.dart';
import 'recurring_transaction_form_screen.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({Key? key}) : super(key: key);

  @override
  State<RecurringTransactionsScreen> createState() => _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState extends State<RecurringTransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      await context.read<TransactionProvider>().loadCategories();
      await context.read<RecurringTransactionProvider>().loadRecurringTransactions();
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Future<void> _deleteRecurringTransaction(RecurringTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('반복 거래 삭제'),
        content: const Text('이 반복 거래를 삭제하시겠습니까?\n이미 생성된 거래는 유지됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<RecurringTransactionProvider>().deleteRecurringTransaction(transaction.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('반복 거래가 삭제되었습니다')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _toggleRecurringTransaction(RecurringTransaction transaction) async {
    try {
      await context.read<RecurringTransactionProvider>()
          .toggleRecurringTransaction(transaction.id, !transaction.isActive);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            transaction.isActive ? '반복 거래가 비활성화되었습니다' : '반복 거래가 활성화되었습니다'
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상태 변경 실패: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('반복 지출 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: '오늘 반복 거래 실행',
            onPressed: () async {
              try {
                final count = await context.read<RecurringTransactionProvider>()
                    .processRecurringTransactions();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$count개의 반복 거래가 생성되었습니다')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('실행 실패: ${e.toString()}')),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<RecurringTransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.recurringTransactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.repeat,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '반복 거래가 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '정기적으로 발생하는 수입/지출을 등록하세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.recurringTransactions.length,
            itemBuilder: (context, index) {
              final transaction = provider.recurringTransactions[index];
              
              return Card(
                elevation: transaction.isActive ? 2 : 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Slidable(
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecurringTransactionFormScreen(
                                transaction: transaction,
                              ),
                            ),
                          );
                          if (result == true) {
                            await provider.loadRecurringTransactions();
                          }
                        },
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        icon: Icons.edit,
                        label: '수정',
                      ),
                      SlidableAction(
                        onPressed: (_) => _deleteRecurringTransaction(transaction),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: '삭제',
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: transaction.isActive
                          ? (transaction.type == 'income'
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1))
                          : Colors.grey.withOpacity(0.1),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: transaction.isActive ? 1.0 : 0.5,
                            child: Text(
                              transaction.category?.icon ?? 
                              (transaction.type == 'income' ? '💰' : '💸'),
                              style: const TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                          if (!transaction.isActive)
                            Icon(
                              Icons.pause_circle_outline,
                              size: 30,
                              color: Colors.grey[600],
                            ),
                        ],
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          transaction.category?.name ?? '미분류',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: transaction.isActive ? null : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: transaction.isActive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: transaction.isActive
                                  ? Colors.green.withOpacity(0.5)
                                  : Colors.grey.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            transaction.frequencyText,
                            style: TextStyle(
                              fontSize: 10,
                              color: transaction.isActive
                                  ? Colors.green[700]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
                          ),
                        if (transaction.description != null)
                          Text(
                            transaction.description!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '다음 실행: ${DateFormat('yyyy-MM-dd').format(transaction.nextDate)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: transaction.isActive
                                    ? Colors.blue[700]
                                    : Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (transaction.endDate != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '종료: ${DateFormat('yyyy-MM-dd').format(transaction.endDate!)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${transaction.type == 'income' ? '+' : '-'} ${NumberFormat('#,###').format(transaction.amount.toInt())}원',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: transaction.isActive
                                    ? (transaction.type == 'income' ? Colors.blue : Colors.red)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: transaction.isActive,
                          onChanged: (_) => _toggleRecurringTransaction(transaction),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const RecurringTransactionFormScreen(),
            ),
          );
          if (result == true) {
            await context.read<RecurringTransactionProvider>().loadRecurringTransactions();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}