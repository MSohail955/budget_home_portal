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

        if (left < 0 ||
            left <= reminder.remindBeforeDays ||
            isCollectionWindow) {
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
      backgroundColor: const Color(0xFFF4F7FB),
      extendBody: true,
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: _PremiumBottomNavigation(
          selectedIndex: selectedIndex,
          alertCount: alertCount,
          onChanged: changeTab,
        ),
      ),
    );
  }
}

class _PremiumBottomNavigation extends StatelessWidget {
  const _PremiumBottomNavigation({
    required this.selectedIndex,
    required this.alertCount,
    required this.onChanged,
  });

  final int selectedIndex;
  final int alertCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(
        label: 'Home',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        color: const Color(0xFF2563EB),
      ),
      _NavItem(
        label: 'Records',
        icon: Icons.folder_copy_outlined,
        selectedIcon: Icons.folder_copy_rounded,
        color: const Color(0xFF16A34A),
      ),
      _NavItem(
        label: 'Alerts',
        icon: Icons.notifications_none_outlined,
        selectedIcon: Icons.notifications_rounded,
        color: const Color(0xFFF59E0B),
        badgeCount: alertCount,
      ),
      _NavItem(
        label: 'Reports',
        icon: Icons.pie_chart_outline,
        selectedIcon: Icons.pie_chart_rounded,
        color: const Color(0xFF7C3AED),
      ),
      _NavItem(
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        color: const Color(0xFF0F172A),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.20),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;

          return Row(
            children: [
              for (int index = 0; index < items.length; index++)
                Expanded(
                  child: _PremiumNavButton(
                    item: items[index],
                    selected: selectedIndex == index,
                    compact: compact,
                    onTap: () => onChanged(index),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PremiumNavButton extends StatelessWidget {
  const _PremiumNavButton({
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = selected ? item.selectedIcon : item.icon;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 58,
            padding: EdgeInsets.symmetric(
              horizontal: selected && !compact ? 12 : 8,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected
                    ? item.color.withOpacity(0.16)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NavIconWithBadge(
                  icon: icon,
                  color: selected ? item.color : Colors.white70,
                  badgeCount: item.badgeCount,
                  selected: selected,
                ),
                if (selected && !compact) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: item.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIconWithBadge extends StatelessWidget {
  const _NavIconWithBadge({
    required this.icon,
    required this.color,
    required this.badgeCount,
    required this.selected,
  });

  final IconData icon;
  final Color color;
  final int badgeCount;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final displayCount = badgeCount > 99 ? '99+' : badgeCount.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          icon,
          color: color,
          size: selected ? 24 : 23,
        ),
        if (badgeCount > 0)
          Positioned(
            right: -11,
            top: -9,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? Colors.white : const Color(0xFF0F172A),
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

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.color,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Color color;
  final int badgeCount;
}