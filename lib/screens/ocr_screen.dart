import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../services/supabase_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../providers/transaction_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({Key? key}) : super(key: key);

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  File? _selectedImage;
  final _imagePicker = ImagePicker();
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _supabaseService = SupabaseService.instance;
  
  bool _isProcessing = false;
  Map<String, dynamic>? _extractedData;
  
  // Controllers for manual editing
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  
  @override
  void dispose() {
    _textRecognizer.close();
    _merchantController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _extractedData = null;
        });
        _processImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 실패: $e')),
      );
    }
  }
  
  Future<void> _processImage() async {
    if (_selectedImage == null) return;
    
    setState(() => _isProcessing = true);
    
    try {
      // 시뮬레이터에서는 OCR을 건너뛰고 수동 입력 다이얼로그를 표시
      if (kDebugMode && (Platform.isIOS || Platform.isAndroid)) {
        // 실제 기기인지 확인
        final isSimulator = await _isSimulator();
        if (isSimulator) {
          setState(() {
            _extractedData = {};
            _merchantController.text = '';
            _amountController.text = '';
            _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
          });
          
          if (mounted) {
            _showExtractedDataDialog();
          }
          return;
        }
      }
      
      final inputImage = InputImage.fromFile(_selectedImage!);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Extract data from recognized text
      final extractedData = _extractReceiptData(recognizedText.text);
      
      setState(() {
        _extractedData = extractedData;
        _merchantController.text = extractedData['merchant'] ?? '';
        _amountController.text = extractedData['amount']?.toString() ?? '';
        _dateController.text = extractedData['date'] != null 
            ? DateFormat('yyyy-MM-dd').format(extractedData['date'])
            : DateFormat('yyyy-MM-dd').format(DateTime.now());
      });
      
      if (mounted) {
        _showExtractedDataDialog();
      }
    } catch (e) {
      if (mounted) {
        // OCR 실패 시 수동 입력 모드로 전환
        setState(() {
          _extractedData = {};
          _merchantController.text = '';
          _amountController.text = '';
          _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
        });
        _showExtractedDataDialog();
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }
  
  Future<bool> _isSimulator() async {
    if (Platform.isIOS) {
      final info = await Process.run('uname', ['-m']);
      return info.stdout.toString().contains('x86_64');
    }
    return false;
  }
  
  Map<String, dynamic> _extractReceiptData(String text) {
    final lines = text.split('\n');
    String? merchant;
    double? amount;
    DateTime? date;
    
    // Pattern matching for common receipt formats
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Extract merchant name (usually at the top)
      if (merchant == null && i < 5 && line.isNotEmpty) {
        // Skip common receipt headers
        if (!line.contains('영수증') && !line.contains('RECEIPT') && 
            !line.contains('전자세금계산서') && !line.contains('간이영수증')) {
          merchant = line;
        }
      }
      
      // Extract amount (look for patterns like "합계", "총액", "TOTAL")
      if (amount == null) {
        // Try various Korean patterns first
        final koreanPatterns = [
          RegExp(r'(?:합계|총액|총금액|결제금액|결제액|금액|판매금액|매출|합산|청구금액)\s*[:\s]*([0-9,]+)', caseSensitive: false),
          RegExp(r'(?:TOTAL|AMOUNT|SUM|PAYMENT)\s*[:\s]*([0-9,]+)', caseSensitive: false),
          RegExp(r'([0-9,]+)\s*(?:원|₩|KRW|WON)', caseSensitive: false),
          RegExp(r'₩\s*([0-9,]+)', caseSensitive: false),
        ];
        
        for (final pattern in koreanPatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            final amountStr = match.group(1)?.replaceAll(',', '');
            final parsedAmount = double.tryParse(amountStr ?? '') ?? 0;
            // Accept amounts over 100 won
            if (parsedAmount > 100 && (amount == null || parsedAmount > amount)) {
              amount = parsedAmount;
              break;
            }
          }
        }
      }
      
      // Extract date (various formats)
      if (date == null) {
        // Format: 2024-01-10 or 2024/01/10
        var dateMatch = RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(line);
        if (dateMatch != null) {
          final year = int.parse(dateMatch.group(1)!);
          final month = int.parse(dateMatch.group(2)!);
          final day = int.parse(dateMatch.group(3)!);
          date = DateTime(year, month, day);
        } else {
          // Format: 24.01.10 or 24-01-10
          dateMatch = RegExp(r'(\d{2})[-.](\d{1,2})[-.](\d{1,2})').firstMatch(line);
          if (dateMatch != null) {
            final year = 2000 + int.parse(dateMatch.group(1)!);
            final month = int.parse(dateMatch.group(2)!);
            final day = int.parse(dateMatch.group(3)!);
            date = DateTime(year, month, day);
          }
        }
      }
    }
    
    return {
      'merchant': merchant,
      'amount': amount,
      'date': date,
    };
  }
  
  void _showExtractedDataDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('영수증 정보 확인'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_extractedData?.isEmpty ?? true 
                  ? '영수증 정보를 입력해주세요' 
                  : '추출된 정보를 확인하고 수정해주세요'),
              const SizedBox(height: 16),
              TextField(
                controller: _merchantController,
                decoration: const InputDecoration(
                  labelText: '사용처',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '금액',
                  border: OutlineInputBorder(),
                  suffixText: '원',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: '날짜',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedImage = null;
                _extractedData = null;
              });
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: _saveTransaction,
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveTransaction() async {
    final merchant = _merchantController.text.trim();
    final amountStr = _amountController.text.trim();
    final dateStr = _dateController.text.trim();
    
    if (merchant.isEmpty || amountStr.isEmpty || dateStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 정보를 입력해주세요')),
      );
      return;
    }
    
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 금액을 입력해주세요')),
      );
      return;
    }
    
    try {
      // Get default expense category (기타)
      final categories = context.read<TransactionProvider>().categories;
      final defaultCategory = categories.firstWhere(
        (c) => c.type == 'expense' && c.name == '기타',
        orElse: () => categories.firstWhere((c) => c.type == 'expense'),
      );
      
      // Save transaction
      await _supabaseService.addTransaction(
        categoryId: defaultCategory.id,
        amount: amount,
        type: 'expense',
        date: DateTime.parse(dateStr),
        description: 'OCR로 등록된 영수증',
        merchant: merchant,
      );
      
      // Upload receipt image to storage
      if (_selectedImage != null) {
        await _uploadReceiptImage(_selectedImage!);
      }
      
      // Reload transactions
      if (mounted) {
        await context.read<TransactionProvider>().loadTransactions(DateTime.now());
        
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('거래가 등록되었습니다')),
        );
        
        // Reset state
        setState(() {
          _selectedImage = null;
          _extractedData = null;
          _merchantController.clear();
          _amountController.clear();
          _dateController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('거래 등록 실패: $e')),
        );
      }
    }
  }
  
  Future<void> _uploadReceiptImage(File image) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;
      
      final bytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final now = DateTime.now();
      final filePath = '$userId/${now.year}/${now.month}/$fileName';
      
      // Create receipts bucket if it doesn't exist
      try {
        await _supabaseService.supabase.storage.createBucket('receipts');
      } catch (e) {
        // Bucket might already exist
      }
      
      await _supabaseService.supabase.storage
          .from('receipts')
          .uploadBinary(filePath, bytes);
      
      final imageUrl = _supabaseService.supabase.storage
          .from('receipts')
          .getPublicUrl(filePath);
      
      // Save receipt record in database
      await _supabaseService.supabase.from('receipts').insert({
        'user_id': userId,
        'image_url': imageUrl,
        'ocr_status': 'completed',
        'ocr_result': _extractedData,
        'merchant_name': _merchantController.text.trim(),
        'total_amount': double.parse(_amountController.text.trim()),
        'receipt_date': _dateController.text.trim(),
      });
    } catch (e) {
      print('Error uploading receipt: $e');
      // Continue even if upload fails
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영수증 스캔'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedImage != null) ...[
              Container(
                width: 300,
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isProcessing)
                const CircularProgressIndicator()
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _processImage,
                      child: const Text('다시 스캔'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                          _extractedData = null;
                        });
                      },
                      child: const Text('취소'),
                    ),
                  ],
                ),
            ] else ...[
              Icon(
                Icons.receipt_long,
                size: 100,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              const Text(
                '영수증을 스캔하여\n자동으로 거래를 등록하세요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('카메라'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('갤러리'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}