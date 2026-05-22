import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/finance_provider.dart';
import '../../../core/providers/reminder_provider.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../records/presentation/records_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int selectedIndex = 0;

  final GlobalKey<RecordsScreenState> recordsKey =
      GlobalKey<RecordsScreenState>();

  void changeTab(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void openRecordsSection(RecordSection section) {
    setState(() {
      selectedIndex = 1;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      recordsKey.currentState?.openSection(section);
    });
  }

  DateTime todayOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime? tryParseDate(String value) {
    return DateTime.tryParse(value.trim());
  }

  int daysLeft(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    return cleanDate.difference(todayOnly()).inDays;
  }

  int buildAlertCount({
    required FinanceProvider finance,
    required ReminderProvider reminder,
  }) {
    int count = 0;

    if (reminder.billRemindersEnabled) {
      for (final bill in finance.bills) {
        if (bill.isPaid) continue;

        final dueDate = tryParseDate(bill.dueDate);
        if (dueDate == null) continue;

        final left = daysLeft(dueDate);

        if (left < 0 || left <= reminder.remindBeforeDays) {
          count++;
        }
      }
    }

    if (reminder.rentRemindersEnabled) {
      for (final rent in finance.rents) {
        if (rent.isPaid) continue;

        final dueDate = tryParseDate(rent.dueDate);
        if (dueDate == null) continue;

        final left = daysLeft(dueDate);
        final today = todayOnly();

        final isCollectionWindow = today.year == dueDate.year &&
            today.month == dueDate.month &&
            today.day >= reminder.rentReminderStartDay &&
            today.day <= reminder.rentReminderEndDay;

        if (left < 0 || left <= reminder.remindBeforeDays || isCollectionWindow) {
          count++;
        }
      }
    }

    if (reminder.loanRemindersEnabled) {
      for (final loan in finance.loans) {
        if (loan.isPaid) continue;

        final dueDate = tryParseDate(loan.date);
        if (dueDate == null) continue;

        final left = daysLeft(dueDate);

        if (left < 0 || left <= reminder.remindBeforeDays) {
          count++;
        }
      }
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final reminder = context.watch<ReminderProvider>();

    final alertCount = buildAlertCount(
      finance: finance,
      reminder: reminder,
    );

    final pages = [
      DashboardScreen(
        onOpenRecordSection: openRecordsSection,
      ),
      RecordsScreen(
        key: recordsKey,
      ),
      const NotificationsScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBody: false,
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: NavigationBar(
            backgroundColor: Colors.white,
            elevation: 0,
            height: 72,
            selectedIndex: selectedIndex,
            onDestinationSelected: changeTab,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.folder_copy_outlined),
                selectedIcon: Icon(Icons.folder_copy),
                label: 'Records',
              ),
              NavigationDestination(
                icon: _AlertNavIcon(
                  count: alertCount,
                  selected: false,
                ),
                selectedIcon: _AlertNavIcon(
                  count: alertCount,
                  selected: true,
                ),
                label: 'Alerts',
              ),
              const NavigationDestination(
                icon: Icon(Icons.pie_chart_outline),
                selectedIcon: Icon(Icons.pie_chart),
                label: 'Reports',
              ),
              const NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertNavIcon extends StatelessWidget {
  const _AlertNavIcon({
    required this.count,
    required this.selected,
  });

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final displayCount = count > 99 ? '99+' : count.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          selected ? Icons.notifications : Icons.notifications_none_outlined,
        ),
        if (count > 0)
          Positioned(
            right: -9,
            top: -7,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                displayCount,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}