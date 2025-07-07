# Flutter 모아 (Flutter MOA) - 가계부 앱

Flutter와 Supabase를 사용하여 개발한 개인 재무 관리 앱입니다.

> MOA는 "모아"의 영문 표기로, 수입과 지출을 잘 모아서 관리하자는 의미를 담고 있습니다.

## 주요 기능

- 📊 수입/지출 입력 및 관리
- 📅 캘린더 뷰로 일별 거래 내역 확인
- 🏷️ 카테고리별 거래 분류
- 📱 스와이프로 거래 수정/삭제

## 설정 방법

### 1. Supabase 설정

1. [Supabase](https://supabase.com)에서 프로젝트를 생성합니다.
2. 프로젝트 설정에서 API URL과 anon key를 복사합니다.
3. `lib/main.dart` 파일에서 다음 부분을 수정합니다:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL', // 여기에 Supabase URL 입력
  anonKey: 'YOUR_SUPABASE_ANON_KEY', // 여기에 anon key 입력
);
```

### 2. 데이터베이스 마이그레이션

`database/schema-design.md` 파일에 있는 SQL 스키마를 Supabase SQL Editor에서 실행하여 필요한 테이블과 뷰를 생성합니다.

### 3. 앱 실행

```bash
# 의존성 설치
flutter pub get

# iOS 시뮬레이터에서 실행
flutter run -d ios

# Android 에뮬레이터에서 실행
flutter run -d android
```

## 프로젝트 구조

```
flutter-moa/
├── lib/
│   ├── main.dart                 # 앱 진입점
│   ├── models/                   # 데이터 모델
│   │   ├── transaction.dart      # 거래 모델
│   │   ├── category.dart         # 카테고리 모델
│   │   └── budget.dart          # 예산 모델
│   ├── screens/                  # 화면
│   │   ├── calendar_screen.dart  # 캘린더 화면
│   │   └── transaction_form_screen.dart  # 거래 입력/수정 화면
│   ├── services/                 # 서비스
│   │   └── supabase_service.dart # Supabase API 서비스
│   ├── providers/                # 상태 관리
│   │   ├── auth_provider.dart    # 인증 상태 관리
│   │   └── transaction_provider.dart # 거래 데이터 상태 관리
│   └── types/                    # TypeScript 타입 정의
│       └── database.types.ts     # Supabase 데이터베이스 타입
├── database/                     # 데이터베이스 문서
│   ├── schema-design.md          # 데이터베이스 스키마 설계
│   └── api-usage-examples.md     # API 사용 예시
└── CLAUDE.md                     # Claude AI 가이드 문서
```

## 프로젝트 정보

- 프로젝트명: flutter_moa
- 패키지명: com.moalite.flutter_moa

## 개발 환경

- Flutter SDK: ^3.8.1
- Dart SDK: 포함됨
- 주요 패키지:
  - supabase_flutter: ^2.3.0
  - provider: ^6.1.1
  - table_calendar: ^3.0.9
  - intl: ^0.18.1
  - flutter_slidable: ^3.0.1

## 추가 개발 예정 기능

- [ ] 사용자 인증 (로그인/회원가입)
- [ ] 예산 관리 기능
- [ ] 통계 및 차트
- [ ] 영수증 OCR
- [ ] 가족 그룹 공유
- [ ] 반복 거래 설정

## 라이센스

이 프로젝트는 개인 사용 목적으로 개발되었습니다.