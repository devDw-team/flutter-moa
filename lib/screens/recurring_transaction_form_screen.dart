import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/recurring_transaction.dart';
import '../models/category.dart' as models;
import '../providers/recurring_transaction_provider.dart';
import '../providers/transaction_provider.dart';

class RecurringTransactionFormScreen extends StatefulWidget {
  final RecurringTransaction? transaction;

  const RecurringTransactionFormScreen({
    Key? key,
    this.transaction,
  }) : super(key: key);

  @override
  State<RecurringTransactionFormScreen> createState() => _RecurringTransactionFormScreenState();
}

class _RecurringTransactionFormScreenState extends State<RecurringTransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _merchantController = TextEditingController();
  
  String _type = 'expense';
  String? _selectedCategoryId;
  models.Category? _selectedCategory;
  String _frequency = 'monthly';
  int _intervalValue = 1;
  int? _dayOfMonth;
  int? _dayOfWeek;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String? _paymentMethod;
  bool _isLastDayOfMonth = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _type = t.type;
      _selectedCategoryId = t.categoryId;
      _selectedCategory = t.category;
      _frequency = t.frequency;
      _intervalValue = t.intervalValue;
      _dayOfMonth = t.dayOfMonth;
      _dayOfWeek = t.dayOfWeek;
      _startDate = t.startDate;
      _endDate = t.endDate;
      _paymentMethod = t.paymentMethod;
      _isLastDayOfMonth = t.dayOfMonth == 99;
      _amountController.text = t.amount.toInt().toString();
      _descriptionController.text = t.description ?? '';
      _merchantController.text = t.merchant ?? '';
    } else {
      // Set default day values
      _dayOfMonth = DateTime.now().day;
      _dayOfWeek = DateTime.now().weekday % 7; // Convert to 0-6 (Sunday-Saturday)
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  String _formatCurrency(String value) {
    if (value.isEmpty) return '';
    final number = int.tryParse(value.replaceAll(',', '')) ?? 0;
    return NumberFormat('#,###').format(number);
  }

  Future<void> _selectCategory() async {
    final categories = context.read<TransactionProvider>().getCategoriesByType(_type);
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                '카테고리 선택',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category.id == _selectedCategoryId;
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = category.id;
                        _selectedCategory = category;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            category.icon ?? '📝',
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ko', 'KR'),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_frequency == 'monthly' && !_isLastDayOfMonth) {
          _dayOfMonth = picked.day;
        } else if (_frequency == 'weekly') {
          _dayOfWeek = picked.weekday % 7;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 365)),
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365 * 5)),
      locale: const Locale('ko', 'KR'),
    );
    
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리를 선택해주세요')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    
    try {
      final provider = context.read<RecurringTransactionProvider>();
      
      if (widget.transaction != null) {
        await provider.updateRecurringTransaction(
          id: widget.transaction!.id,
          categoryId: _selectedCategoryId,
          amount: amount,
          type: _type,
          frequency: _frequency,
          intervalValue: _intervalValue,
          dayOfMonth: _isLastDayOfMonth ? 99 : (_frequency == 'monthly' ? _dayOfMonth : null),
          dayOfWeek: _frequency == 'weekly' ? _dayOfWeek : null,
          startDate: _startDate,
          endDate: _endDate,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          merchant: _merchantController.text.isEmpty ? null : _merchantController.text,
          paymentMethod: _paymentMethod,
        );
      } else {
        await provider.addRecurringTransaction(
          categoryId: _selectedCategoryId!,
          amount: amount,
          type: _type,
          frequency: _frequency,
          intervalValue: _intervalValue,
          dayOfMonth: _isLastDayOfMonth ? 99 : (_frequency == 'monthly' ? _dayOfMonth : null),
          dayOfWeek: _frequency == 'weekly' ? _dayOfWeek : null,
          startDate: _startDate,
          endDate: _endDate,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          merchant: _merchantController.text.isEmpty ? null : _merchantController.text,
          paymentMethod: _paymentMethod,
        );
      }
      
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction != null ? '반복 거래 수정' : '반복 거래 등록'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '거래 유형',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('지출'),
                            value: 'expense',
                            groupValue: _type,
                            onChanged: (value) {
                              setState(() {
                                _type = value!;
                                _selectedCategoryId = null;
                                _selectedCategory = null;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('수입'),
                            value: 'income',
                            groupValue: _type,
                            onChanged: (value) {
                              setState(() {
                                _type = value!;
                                _selectedCategoryId = null;
                                _selectedCategory = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Category Selection
            InkWell(
              onTap: _selectCategory,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      _selectedCategory?.icon ?? '📝',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCategory?.name ?? '카테고리 선택',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedCategory != null ? null : Colors.grey,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: '금액',
                border: OutlineInputBorder(),
                suffixText: '원',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '금액을 입력해주세요';
                }
                return null;
              },
              onChanged: (value) {
                final formatted = _formatCurrency(value);
                if (formatted != value) {
                  _amountController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Frequency
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '반복 주기',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _frequency,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('매일')),
                        DropdownMenuItem(value: 'weekly', child: Text('매주')),
                        DropdownMenuItem(value: 'monthly', child: Text('매월')),
                        DropdownMenuItem(value: 'yearly', child: Text('매년')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _frequency = value!;
                          if (_frequency == 'monthly') {
                            _dayOfMonth = _startDate.day;
                            _dayOfWeek = null;
                          } else if (_frequency == 'weekly') {
                            _dayOfWeek = _startDate.weekday % 7;
                            _dayOfMonth = null;
                            _isLastDayOfMonth = false;
                          } else {
                            _dayOfMonth = null;
                            _dayOfWeek = null;
                            _isLastDayOfMonth = false;
                          }
                        });
                      },
                    ),
                    
                    if (_frequency == 'monthly') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text('매월 말일'),
                              value: _isLastDayOfMonth,
                              onChanged: (value) {
                                setState(() {
                                  _isLastDayOfMonth = value!;
                                  if (_isLastDayOfMonth) {
                                    _dayOfMonth = 99;
                                  } else {
                                    _dayOfMonth = _startDate.day;
                                  }
                                });
                              },
                            ),
                          ),
                          if (!_isLastDayOfMonth)
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _dayOfMonth,
                                decoration: const InputDecoration(
                                  labelText: '실행일',
                                  border: OutlineInputBorder(),
                                ),
                                items: List.generate(31, (i) => i + 1)
                                    .map((day) => DropdownMenuItem(
                                          value: day,
                                          child: Text('$day일'),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _dayOfMonth = value;
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                    
                    if (_frequency == 'weekly') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _dayOfWeek,
                        decoration: const InputDecoration(
                          labelText: '요일',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(7, (i) => i)
                            .map((day) => DropdownMenuItem(
                                  value: day,
                                  child: Text('${weekdays[day]}요일'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _dayOfWeek = value;
                          });
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _intervalValue.toString(),
                      decoration: InputDecoration(
                        labelText: _frequency == 'daily' ? '일 간격' :
                                  _frequency == 'weekly' ? '주 간격' :
                                  _frequency == 'monthly' ? '개월 간격' : '년 간격',
                        border: const OutlineInputBorder(),
                        helperText: '1 = 매${_frequency == 'daily' ? '일' : _frequency == 'weekly' ? '주' : _frequency == 'monthly' ? '월' : '년'}, 2 = 2${_frequency == 'daily' ? '일' : _frequency == 'weekly' ? '주' : _frequency == 'monthly' ? '개월' : '년'}마다',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '간격을 입력해주세요';
                        }
                        final interval = int.tryParse(value);
                        if (interval == null || interval < 1) {
                          return '1 이상의 숫자를 입력해주세요';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _intervalValue = int.tryParse(value) ?? 1;
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Dates
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '기간 설정',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('시작일'),
                      subtitle: Text(DateFormat('yyyy년 MM월 dd일').format(_startDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _selectStartDate,
                    ),
                    ListTile(
                      title: const Text('종료일 (선택)'),
                      subtitle: Text(
                        _endDate != null
                            ? DateFormat('yyyy년 MM월 dd일').format(_endDate!)
                            : '무기한',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_endDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _endDate = null;
                                });
                              },
                            ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                      onTap: _selectEndDate,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Payment Method
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(
                labelText: '결제 수단 (선택)',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('선택 안함')),
                DropdownMenuItem(value: 'card', child: Text('카드')),
                DropdownMenuItem(value: 'transfer', child: Text('계좌이체')),
                DropdownMenuItem(value: 'cash', child: Text('현금')),
              ],
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Merchant
            TextFormField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: '사용처 (선택)',
                border: OutlineInputBorder(),
                hintText: '예: 넷플릭스, 보험료',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '메모 (선택)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 24),
            
            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(widget.transaction != null ? '수정' : '등록'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}