# 모아 Lite API 사용 예시 (Flutter + Supabase)

## 1. 초기 설정

### Flutter 프로젝트에 Supabase 설정
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  runApp(MyApp());
}

// Supabase 클라이언트 접근
final supabase = Supabase.instance.client;
```

## 2. 인증 관련 API

### 회원가입
```dart
Future<void> signUp(String email, String password, String fullName) async {
  final response = await supabase.auth.signUp(
    email: email,
    password: password,
    data: {'full_name': fullName},
  );
  
  if (response.user != null) {
    // 프로필은 트리거로 자동 생성됨
    print('회원가입 성공');
  }
}
```

### 로그인
```dart
Future<void> signIn(String email, String password) async {
  final response = await supabase.auth.signInWithPassword(
    email: email,
    password: password,
  );
  
  if (response.user != null) {
    print('로그인 성공');
  }
}
```

## 3. 거래 관련 API

### 거래 추가
```dart
Future<void> addTransaction({
  required String categoryId,
  required double amount,
  required String type,
  required DateTime date,
  String? description,
  List<String>? tags,
}) async {
  final userId = supabase.auth.currentUser!.id;
  
  await supabase.from('transactions').insert({
    'user_id': userId,
    'category_id': categoryId,
    'amount': amount,
    'type': type,
    'transaction_date': date.toIso8601String().split('T')[0],
    'description': description,
    'tags': tags,
  });
}
```

### 거래 조회 (캘린더용)
```dart
Future<List<Map<String, dynamic>>> getDailyTransactions(DateTime date) async {
  final userId = supabase.auth.currentUser!.id;
  final dateStr = date.toIso8601String().split('T')[0];
  
  final response = await supabase
      .from('daily_summary')
      .select()
      .eq('user_id', userId)
      .eq('transaction_date', dateStr);
  
  return response as List<Map<String, dynamic>>;
}
```

### 월별 거래 조회
```dart
Future<List<Map<String, dynamic>>> getMonthlyTransactions(DateTime month) async {
  final userId = supabase.auth.currentUser!.id;
  final startDate = DateTime(month.year, month.month, 1);
  final endDate = DateTime(month.year, month.month + 1, 0);
  
  final response = await supabase
      .from('transactions')
      .select('*, categories!inner(*)')
      .eq('user_id', userId)
      .gte('transaction_date', startDate.toIso8601String().split('T')[0])
      .lte('transaction_date', endDate.toIso8601String().split('T')[0])
      .order('transaction_date', ascending: false);
  
  return response as List<Map<String, dynamic>>;
}
```

### 실시간 거래 업데이트 구독
```dart
void subscribeToTransactions() {
  final userId = supabase.auth.currentUser!.id;
  
  supabase
      .channel('transactions:$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'transactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
      )
      .subscribe((payload) {
        print('거래 업데이트: ${payload.eventType}');
        // UI 업데이트 로직
      });
}
```

## 4. 카테고리 관련 API

### 카테고리 목록 조회
```dart
Future<List<Map<String, dynamic>>> getCategories({String? type}) async {
  final userId = supabase.auth.currentUser!.id;
  
  var query = supabase
      .from('categories')
      .select()
      .or('is_system.eq.true,user_id.eq.$userId')
      .order('sort_order');
  
  if (type != null) {
    query = query.eq('type', type);
  }
  
  final response = await query;
  return response as List<Map<String, dynamic>>;
}
```

### 카테고리 추가
```dart
Future<void> addCategory({
  required String name,
  required String type,
  String? icon,
  String? color,
}) async {
  final userId = supabase.auth.currentUser!.id;
  
  await supabase.from('categories').insert({
    'user_id': userId,
    'name': name,
    'type': type,
    'icon': icon,
    'color': color,
  });
}
```

## 5. 예산 관련 API

### 예산 설정
```dart
Future<void> setBudget({
  required String name,
  required double amount,
  required String periodType,
  required DateTime startDate,
  String? categoryId,
}) async {
  final userId = supabase.auth.currentUser!.id;
  
  await supabase.from('budgets').insert({
    'user_id': userId,
    'name': name,
    'amount': amount,
    'period_type': periodType,
    'start_date': startDate.toIso8601String().split('T')[0],
    'category_id': categoryId,
    'is_active': true,
  });
}
```

### 예산 사용 현황 조회
```dart
Future<List<Map<String, dynamic>>> getBudgetSummary() async {
  final userId = supabase.auth.currentUser!.id;
  
  final response = await supabase
      .from('budget_summary')
      .select()
      .eq('user_id', userId)
      .eq('is_active', true);
  
  return response as List<Map<String, dynamic>>;
}
```

### 예산 알림 설정
```dart
Future<void> setBudgetAlert(String budgetId, int thresholdPercentage) async {
  await supabase.from('budget_alerts').insert({
    'budget_id': budgetId,
    'threshold_percentage': thresholdPercentage,
  });
}
```

## 6. 통계 관련 API

### 거래 통계 조회
```dart
Future<Map<String, dynamic>> getTransactionStats({
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final userId = supabase.auth.currentUser!.id;
  
  final response = await supabase.rpc('get_transaction_stats', params: {
    'p_user_id': userId,
    'p_start_date': startDate?.toIso8601String().split('T')[0],
    'p_end_date': endDate?.toIso8601String().split('T')[0],
  });
  
  return response[0] as Map<String, dynamic>;
}
```

### 카테고리별 지출 분석
```dart
Future<List<Map<String, dynamic>>> getCategoryAnalysis(DateTime month) async {
  final userId = supabase.auth.currentUser!.id;
  final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}';
  
  final response = await supabase
      .from('category_summary')
      .select()
      .eq('user_id', userId)
      .eq('category_type', 'expense')
      .ilike('month', '$monthStr%')
      .order('total_amount', ascending: false);
  
  return response as List<Map<String, dynamic>>;
}
```

## 7. 영수증 관련 API

### 영수증 업로드
```dart
Future<String> uploadReceipt(File imageFile) async {
  final userId = supabase.auth.currentUser!.id;
  final fileName = '${userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
  
  // Storage에 이미지 업로드
  await supabase.storage
      .from('receipts')
      .upload(fileName, imageFile);
  
  // 공개 URL 생성
  final imageUrl = supabase.storage
      .from('receipts')
      .getPublicUrl(fileName);
  
  // 영수증 레코드 생성
  final response = await supabase.from('receipts').insert({
    'user_id': userId,
    'image_url': imageUrl,
    'ocr_status': 'pending',
  }).select().single();
  
  return response['id'];
}
```

### OCR 결과 업데이트
```dart
Future<void> updateOcrResult(String receiptId, Map<String, dynamic> ocrData) async {
  await supabase.from('receipts').update({
    'ocr_result': ocrData,
    'ocr_status': 'completed',
    'merchant_name': ocrData['merchant_name'],
    'total_amount': ocrData['total_amount'],
    'receipt_date': ocrData['date'],
  }).eq('id', receiptId);
}
```

## 8. 반복 거래 관련 API

### 반복 거래 설정
```dart
Future<void> createRecurringTransaction({
  required String categoryId,
  required double amount,
  required String type,
  required String frequency,
  required DateTime startDate,
  String? description,
}) async {
  final userId = supabase.auth.currentUser!.id;
  
  await supabase.from('recurring_transactions').insert({
    'user_id': userId,
    'category_id': categoryId,
    'amount': amount,
    'type': type,
    'frequency': frequency,
    'start_date': startDate.toIso8601String().split('T')[0],
    'next_date': startDate.toIso8601String().split('T')[0],
    'description': description,
    'is_active': true,
  });
}
```

### 반복 거래 처리
```dart
Future<int> processRecurringTransactions() async {
  final response = await supabase.rpc('process_recurring_transactions');
  return response as int;
}
```

## 9. 오프라인 동기화 전략

### 로컬 캐싱 (Hive 사용)
```dart
import 'package:hive/hive.dart';

class OfflineSync {
  static const String PENDING_TRANSACTIONS = 'pending_transactions';
  
  // 오프라인 거래 저장
  static Future<void> savePendingTransaction(Map<String, dynamic> transaction) async {
    final box = await Hive.openBox(PENDING_TRANSACTIONS);
    await box.add({
      ...transaction,
      'created_at_local': DateTime.now().toIso8601String(),
      'sync_status': 'pending',
    });
  }
  
  // 온라인 시 동기화
  static Future<void> syncPendingTransactions() async {
    final box = await Hive.openBox(PENDING_TRANSACTIONS);
    final pendingItems = box.values.toList();
    
    for (var item in pendingItems) {
      try {
        await supabase.from('transactions').insert(item);
        await box.delete(item.key);
      } catch (e) {
        print('동기화 실패: $e');
      }
    }
  }
}
```

## 10. 에러 처리 예시

```dart
class TransactionService {
  static Future<Either<String, List<Transaction>>> getTransactions() async {
    try {
      final response = await supabase
          .from('transactions')
          .select()
          .order('transaction_date', ascending: false);
      
      final transactions = (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
      
      return Right(transactions);
    } on PostgrestException catch (e) {
      return Left('데이터베이스 오류: ${e.message}');
    } catch (e) {
      return Left('알 수 없는 오류: $e');
    }
  }
}
```