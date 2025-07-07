# 모아 Lite 가계부 앱 데이터베이스 스키마 설계

## 1. 개요
- **앱 이름**: 모아 Lite
- **플랫폼**: Flutter + Supabase (PostgreSQL)
- **주요 기능**: 수입/지출 입력, 캘린더 뷰, 예산 관리, OCR 영수증 처리
- **보안**: Row Level Security (RLS) 적용
- **실시간**: Realtime 구독 지원

## 2. 테이블 구조

### 2.1 사용자 관련 테이블

#### profiles (사용자 프로필)
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  currency TEXT DEFAULT 'KRW',
  locale TEXT DEFAULT 'ko',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### family_groups (가족 그룹)
```sql
CREATE TABLE family_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  created_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### family_members (가족 구성원)
```sql
CREATE TABLE family_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'member')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);
```

### 2.2 거래 관련 테이블

#### categories (카테고리)
```sql
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  family_group_id UUID REFERENCES family_groups(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  icon TEXT,
  color TEXT,
  parent_id UUID REFERENCES categories(id),
  sort_order INTEGER DEFAULT 0,
  is_system BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CHECK ((user_id IS NOT NULL AND family_group_id IS NULL) OR 
         (user_id IS NULL AND family_group_id IS NOT NULL) OR
         (is_system = TRUE))
);
```

#### transactions (거래 내역)
```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  family_group_id UUID REFERENCES family_groups(id),
  category_id UUID NOT NULL REFERENCES categories(id),
  amount DECIMAL(15, 2) NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  description TEXT,
  transaction_date DATE NOT NULL,
  transaction_time TIME,
  receipt_id UUID REFERENCES receipts(id),
  is_recurring BOOLEAN DEFAULT FALSE,
  recurring_id UUID REFERENCES recurring_transactions(id),
  tags TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### recurring_transactions (반복 거래)
```sql
CREATE TABLE recurring_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  family_group_id UUID REFERENCES family_groups(id),
  category_id UUID NOT NULL REFERENCES categories(id),
  amount DECIMAL(15, 2) NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  description TEXT,
  frequency TEXT NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly', 'yearly')),
  interval_value INTEGER DEFAULT 1,
  start_date DATE NOT NULL,
  end_date DATE,
  next_date DATE NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2.3 예산 관련 테이블

#### budgets (예산)
```sql
CREATE TABLE budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  family_group_id UUID REFERENCES family_groups(id),
  category_id UUID REFERENCES categories(id),
  name TEXT NOT NULL,
  amount DECIMAL(15, 2) NOT NULL,
  period_type TEXT NOT NULL CHECK (period_type IN ('weekly', 'monthly', 'yearly')),
  start_date DATE NOT NULL,
  end_date DATE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CHECK ((user_id IS NOT NULL AND family_group_id IS NULL) OR 
         (user_id IS NULL AND family_group_id IS NOT NULL))
);
```

#### budget_alerts (예산 알림)
```sql
CREATE TABLE budget_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
  threshold_percentage INTEGER NOT NULL CHECK (threshold_percentage BETWEEN 0 AND 100),
  is_notified BOOLEAN DEFAULT FALSE,
  notified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2.4 영수증 관련 테이블

#### receipts (영수증)
```sql
CREATE TABLE receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  image_url TEXT NOT NULL,
  thumbnail_url TEXT,
  ocr_status TEXT DEFAULT 'pending' CHECK (ocr_status IN ('pending', 'processing', 'completed', 'failed')),
  ocr_result JSONB,
  merchant_name TEXT,
  total_amount DECIMAL(15, 2),
  receipt_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2.5 통계 및 집계 뷰

#### monthly_summary (월별 요약 뷰)
```sql
CREATE VIEW monthly_summary AS
SELECT 
  user_id,
  family_group_id,
  DATE_TRUNC('month', transaction_date) AS month,
  type,
  SUM(amount) AS total_amount,
  COUNT(*) AS transaction_count
FROM transactions
GROUP BY user_id, family_group_id, DATE_TRUNC('month', transaction_date), type;
```

#### category_summary (카테고리별 요약 뷰)
```sql
CREATE VIEW category_summary AS
SELECT 
  t.user_id,
  t.family_group_id,
  t.category_id,
  c.name AS category_name,
  c.type AS category_type,
  DATE_TRUNC('month', t.transaction_date) AS month,
  SUM(t.amount) AS total_amount,
  COUNT(*) AS transaction_count
FROM transactions t
JOIN categories c ON t.category_id = c.id
GROUP BY t.user_id, t.family_group_id, t.category_id, c.name, c.type, DATE_TRUNC('month', t.transaction_date);
```

## 3. Row Level Security (RLS) 정책

### profiles 테이블
- 사용자는 자신의 프로필만 조회/수정 가능
- 가족 그룹 멤버는 다른 멤버의 기본 정보 조회 가능

### transactions 테이블
- 사용자는 자신의 거래만 CRUD 가능
- 가족 그룹 멤버는 그룹 거래 조회 가능 (role에 따라 수정 권한 차등)

### categories 테이블
- 시스템 카테고리는 모든 사용자 조회 가능
- 개인 카테고리는 본인만 CRUD 가능
- 가족 그룹 카테고리는 그룹 멤버만 접근 가능

### budgets 테이블
- 개인 예산은 본인만 접근 가능
- 가족 그룹 예산은 그룹 멤버만 접근 가능

## 4. 인덱스 설계

```sql
-- 거래 조회 성능 최적화
CREATE INDEX idx_transactions_user_date ON transactions(user_id, transaction_date DESC);
CREATE INDEX idx_transactions_category ON transactions(category_id);
CREATE INDEX idx_transactions_family_date ON transactions(family_group_id, transaction_date DESC) WHERE family_group_id IS NOT NULL;

-- 카테고리 조회 최적화
CREATE INDEX idx_categories_user ON categories(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_categories_family ON categories(family_group_id) WHERE family_group_id IS NOT NULL;

-- 예산 조회 최적화
CREATE INDEX idx_budgets_user_active ON budgets(user_id, is_active) WHERE user_id IS NOT NULL;
CREATE INDEX idx_budgets_family_active ON budgets(family_group_id, is_active) WHERE family_group_id IS NOT NULL;

-- 영수증 조회 최적화
CREATE INDEX idx_receipts_user_date ON receipts(user_id, created_at DESC);
```

## 5. 트리거 및 함수

### updated_at 자동 업데이트
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 각 테이블에 트리거 적용
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
-- (다른 테이블들도 동일하게 적용)
```

### 예산 사용률 계산 함수
```sql
CREATE OR REPLACE FUNCTION calculate_budget_usage(budget_id UUID)
RETURNS TABLE (
  used_amount DECIMAL,
  usage_percentage DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(SUM(t.amount), 0) AS used_amount,
    CASE 
      WHEN b.amount > 0 THEN ROUND((COALESCE(SUM(t.amount), 0) / b.amount) * 100, 2)
      ELSE 0
    END AS usage_percentage
  FROM budgets b
  LEFT JOIN transactions t ON 
    (b.category_id IS NULL OR t.category_id = b.category_id) AND
    t.transaction_date BETWEEN b.start_date AND COALESCE(b.end_date, CURRENT_DATE) AND
    t.type = 'expense' AND
    ((b.user_id IS NOT NULL AND t.user_id = b.user_id) OR
     (b.family_group_id IS NOT NULL AND t.family_group_id = b.family_group_id))
  WHERE b.id = budget_id
  GROUP BY b.amount;
END;
$$ LANGUAGE plpgsql;
```

## 6. Storage 버킷 구조

```
receipts/
  ├── {user_id}/
  │   ├── {year}/
  │   │   ├── {month}/
  │   │   │   ├── {receipt_id}_original.jpg
  │   │   │   └── {receipt_id}_thumb.jpg
```

## 7. Realtime 구독 채널

- `transactions:user:{user_id}` - 개인 거래 업데이트
- `transactions:family:{family_group_id}` - 가족 그룹 거래 업데이트
- `budgets:user:{user_id}` - 개인 예산 알림
- `budgets:family:{family_group_id}` - 가족 그룹 예산 알림