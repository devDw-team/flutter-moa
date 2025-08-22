import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/recurring_transaction_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize date formatting for Korean locale
    await initializeDateFormatting('ko_KR', null);
    
    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://usqslqpqvidvvaqvtgnv.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVzcXNscXBxdmlkdnZhcXZ0Z252Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE3NzA4MzQsImV4cCI6MjA2NzM0NjgzNH0.rLUqlhTAu8xF1JIpQ3ic_dHiobVjYHh3uV0ps6cbpBI',
    );
  } catch (e) {
    print('Initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => RecurringTransactionProvider()),
      ],
      child: MaterialApp(
        title: '모아 Lite',
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'),
          Locale('en', 'US'),
        ],
        theme: ThemeData(
          primarySwatch: Colors.blue,
          appBarTheme: const AppBarTheme(
            elevation: 1,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}