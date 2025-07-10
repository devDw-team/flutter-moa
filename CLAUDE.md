# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is "모아 Lite" (Moa Lite), a personal finance tracking application built with Flutter and Supabase. The application helps users track their income and expenses with a beautiful calendar-based interface.

## Project Structure

- `database/` - Database documentation in Korean
  - `schema-design.md` - Complete database schema with tables, views, functions, and RLS policies
  - `api-usage-examples.md` - Flutter/Dart code examples for API usage
- `lib/` - Flutter application code
  - `models/` - Data models (Transaction, Category, etc.)
  - `providers/` - State management with Provider pattern
  - `screens/` - UI screens
  - `services/` - Business logic and API services
  - `types/` - TypeScript type definitions
- `lib/types/` - TypeScript type definitions
  - `database.types.ts` - Auto-generated Supabase types

## Key Technologies

- **Frontend**: Flutter (Dart)
- **Backend/Database**: Supabase (PostgreSQL)
- **State Management**: Provider pattern
- **Authentication**: Supabase Auth
- **Type System**: TypeScript (for database types)
- **Security**: Row Level Security (RLS) policies
- **Real-time**: Supabase Realtime subscriptions
- **MCP Integration**: Supabase MCP server for database operations
- **UI Components**: Material Design 3

## Common Commands

### Flutter Commands
```bash
# Install dependencies
flutter pub get

# Run the app on iOS simulator
flutter run -d ios

# Run the app on Android emulator
flutter run -d android

# Run on web
flutter run -d web-server --web-hostname localhost --web-port 3000
```

### Supabase MCP Server
```bash
# Run the Supabase MCP server (configured in .mcp.json)
npx @supabase-mcp-server/mcp
```

### Generate TypeScript Types
Use the Supabase MCP tool `mcp__supabase-moa__generate_typescript_types` to regenerate types after schema changes.

## Database Architecture

### Core Tables
- **profiles** - User profiles linked to auth.users
- **transactions** - Financial transactions (income/expense)
- **categories** - Transaction categories (system/user/family)
- **budgets** - Budget management with alerts
- **receipts** - Receipt images with OCR processing
- **family_groups** - Shared expense groups
- **recurring_transactions** - Automated recurring entries

### Views
- **monthly_summary** - Aggregated monthly data
- **category_summary** - Category-wise statistics
- **daily_summary** - Daily transaction summaries
- **budget_summary** - Budget usage tracking

### Key Functions
- `calculate_budget_usage()` - Budget utilization calculation
- `process_recurring_transactions()` - Process recurring entries
- `get_transaction_stats()` - Transaction statistics
- `check_budget_alerts()` - Budget threshold monitoring

## Security Model

All tables implement Row Level Security (RLS) with these patterns:
- Personal data: Users can only access their own records
- Family groups: Members can view/edit based on role (owner/admin/member)
- System categories: Read-only for all users

## Development Guidelines

1. **Schema Changes**: Always update migrations using `mcp__supabase-moa__apply_migration`
2. **Type Generation**: Regenerate TypeScript types after schema changes
3. **Security**: Check advisors after DDL changes using `mcp__supabase-moa__get_advisors`
4. **Testing**: Use `mcp__supabase-moa__execute_sql` for queries, not DDL operations
5. **Branches**: Use `mcp__supabase-moa__create_branch` for development work

## Real-time Channels

- `transactions:user:{user_id}` - Personal transaction updates
- `transactions:family:{family_group_id}` - Family group updates
- `budgets:user:{user_id}` - Budget alerts
- `budgets:family:{family_group_id}` - Family budget alerts

## Storage Structure

Receipts are stored in Supabase Storage:
```
receipts/
  {user_id}/
    {year}/
      {month}/
        {receipt_id}_original.jpg
        {receipt_id}_thumb.jpg
```

## Implemented Features

### Authentication System
- **Login Screen** (`lib/screens/login_screen.dart`)
  - Email/password authentication
  - Input validation
  - Error handling
  - Navigation to signup
  
- **Signup Screen** (`lib/screens/signup_screen.dart`)
  - User registration with email, password, and name
  - Password confirmation
  - Terms of service agreement
  - Automatic profile creation via database trigger

- **Auth Provider** (`lib/providers/auth_provider.dart`)
  - State management for authentication
  - Auth state listeners
  - Session management

### Transaction Management
- **Calendar Screen** (`lib/screens/calendar_screen.dart`)
  - Monthly calendar view with TableCalendar
  - Daily transaction summaries
  - Income/expense indicators on calendar dates (positioned below date numbers)
  - Swipe to edit/delete transactions
  - Floating action button for quick transaction entry
  - Logout functionality

- **Transaction Form** (`lib/screens/transaction_form_screen.dart`)
  - Add/edit transactions
  - Income/expense toggle
  - Amount input with currency formatting
  - Category selection with icons
  - Date picker
  - Merchant input field
  - Optional notes field

### Category System
- **System Categories**
  - Pre-defined expense categories: 식비, 카페/간식, 유흥, 생필품, 쇼핑, 교통, 자동차/주유비, 주거/통신, 의료/건강, 금융, 문화/여가, 여행/숙박, 교육, 자녀, 경조사, 기타
  - Pre-defined income categories: 급여, 용돈, 부업, 금융, 기타
  - Each category has an icon and color
  
- **Category Picker** 
  - Grid layout bottom sheet
  - Visual category selection with icons
  - Filtered by transaction type (income/expense)

### Data Models
- **Transaction Model** (`lib/models/transaction.dart`)
  - Complete transaction data structure
  - Related category information
  - JSON serialization

- **Category Model** (`lib/models/category.dart`)
  - Category properties (name, icon, color, type)
  - System vs user categories

### Services
- **Supabase Service** (`lib/services/supabase_service.dart`)
  - Authentication methods
  - CRUD operations for transactions
  - Category fetching with fallback data
  - Error handling

### State Management
- **Transaction Provider** (`lib/providers/transaction_provider.dart`)
  - Transaction list management
  - Category management
  - Monthly summary calculations
  - Loading states and error handling

## UI/UX Design
- Clean, modern Material Design 3 interface
- Korean localization
- Responsive layouts
- Intuitive navigation
- Visual feedback for all actions
- Error states and loading indicators

### Navigation System
- **Main Screen with Bottom Navigation** (`lib/screens/main_screen.dart`)
  - IndexedStack for screen persistence
  - 4 main tabs: 홈, 예산, OCR, 설정
  - Material Design bottom navigation bar

### Budget Management
- **Budget Screen** (`lib/screens/budget_screen.dart`)
  - Monthly budget setting with number formatting
  - Income vs Expense bar chart visualization
  - Budget usage percentage display
  - Category-wise expense summary (top 5 categories)
  - Real-time data from Supabase
  - Thousand separator input formatter
  
- **Budget Storage**
  - Budgets stored in Supabase `budgets` table
  - Automatic create/update logic
  - Monthly period tracking
  - Historical budget data

### OCR System (Placeholder)
- **OCR Screen** (`lib/screens/ocr_screen.dart`)
  - Camera/Gallery image picker
  - Receipt scanning UI
  - Ready for OCR integration

### Settings
- **Settings Screen** (`lib/screens/settings_screen.dart`)
  - User profile display
  - Category management (planned)
  - Notification settings (planned)
  - Data backup (planned)
  - Security settings (planned)
  - App info and logout

### Additional Services
- **Budget Methods in Supabase Service**
  - `getCurrentMonthBudget()` - Retrieve current month's budget
  - `createOrUpdateBudget()` - Save/update budget data
  - `getBudgetHistory()` - Get historical budget data
  - `getMonthlySummary()` - Calculate monthly income/expense totals
  - `getCategoryAnalysis()` - Get category-wise expense summary

## UI/UX Design
- Clean, modern Material Design 3 interface
- Korean localization
- Responsive layouts
- Bottom navigation for main features
- Number formatting with thousand separators
- Chart visualizations with fl_chart
- Intuitive navigation
- Visual feedback for all actions
- Error states and loading indicators

## Security Features
- Row Level Security (RLS) on all tables
- Automatic user profile creation
- Secure authentication flow
- Protected API endpoints
- User data isolation
- Fixed RLS policies to prevent infinite recursion
- Personal data only (family group features disabled)

## Recent Updates (2025-01-09)
- Fixed login/data loading timing issues
- Resolved RLS infinite recursion errors
- Added bottom navigation with 4 main screens
- Implemented budget management with Supabase integration
- Added thousand separator formatting for currency inputs
- Fixed chart display when no data exists
- Removed family group related RLS policies

## Recent Updates (2025-01-10)
- **Calendar UI Improvements**
  - Moved income/expense indicators to display below date numbers
  - Fixed date range comparison for category analysis query
  
- **Budget Screen Enhancements**
  - Added category-wise expense summary showing top 5 spending categories
  - Visual progress bars for each category with percentage display
  - Fixed null safety issues with category colors and icons
  
- **Transaction Form Updates**
  - Added merchant field to track where money was spent
  - Updated database schema with merchant column
  - Updated all related models and services to support merchant data
  
- **Database Changes**
  - Added `merchant` column to transactions table
  - Regenerated TypeScript types for database consistency