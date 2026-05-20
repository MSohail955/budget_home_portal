import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/auth_provider.dart';
import '../core/providers/currency_provider.dart';
import '../core/providers/dashboard_filter_provider.dart';
import '../core/providers/finance_provider.dart';
import '../core/providers/profile_provider.dart';
import '../core/providers/reminder_provider.dart';
import '../core/providers/report_filter_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class BudgetHomeApp extends StatelessWidget {
  const BudgetHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardFilterProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportFilterProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReminderProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CurrencyProvider>(
          create: (_) => CurrencyProvider(),
          update: (_, authProvider, currencyProvider) {
            final provider = currencyProvider ?? CurrencyProvider();
            provider.setUserId(authProvider.currentUserId);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, FinanceProvider>(
          create: (_) => FinanceProvider(),
          update: (_, authProvider, financeProvider) {
            final provider = financeProvider ?? FinanceProvider();
            provider.setUserId(authProvider.currentUserId);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (_) => ProfileProvider(),
          update: (_, authProvider, profileProvider) {
            final provider = profileProvider ?? ProfileProvider();
            provider.setUser(authProvider.currentUser);
            return provider;
          },
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'Budget Home',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.lightTheme,
            themeMode: ThemeMode.light,
            routerConfig: AppRouter.createRouter(authProvider),
          );
        },
      ),
    );
  }
}