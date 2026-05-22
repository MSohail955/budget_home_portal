import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/finance_provider.dart';
import '../../../core/providers/reminder_provider.dart';

enum NotificationFilter {
  all,
  dueSoon,
  overdue,
  bills,
  rent,
  loans,
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationFilter selectedFilter = NotificationFilter.all;

  DateTime todayOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime? tryParseDate(String value) {
    return DateTime.tryParse(value.trim());
  }

  String readableDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  int daysLeft(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    return cleanDate.difference(todayOnly()).inDays;
  }

  List<AppNotificationItem> buildNotifications({
    required FinanceProvider finance,
    required ReminderProvider reminder,
  }) {
    final items = <AppNotificationItem>[];

    if (reminder.billRemindersEnabled) {
      for (final bill in finance.bills) {
        if (bill.isPaid) continue;

        final dueDate = tryParseDate(bill.dueDate);
        if (dueDate == null) continue;

        final left = daysLeft(dueDate);

        if (left < 0) {
          items.add(
            AppNotificationItem(
              title: '${bill.title} is overdue',
              subtitle:
                  '${bill.category} bill was due on ${readableDate(dueDate)}.',
              type: 'Bill',
              status: 'Overdue',
              daysLeft: left,
              amount: bill.amount,
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFFDC2626),
            ),
          );
        } else if (left <= reminder.remindBeforeDays) {
          items.add(
            AppNotificationItem(
              title: '${bill.title} due soon',
              subtitle:
                  '${bill.category} bill is due on ${readableDate(dueDate)}.',
              type: 'Bill',
              status: left == 0 ? 'Due Today' : 'Due Soon',
              daysLeft: left,
              amount: bill.amount,
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFF2563EB),
            ),
          );
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

        if (left < 0) {
          items.add(
            AppNotificationItem(
              title: '${rent.tenantName} rent is overdue',
              subtitle:
                  '${rent.propertyName} rent was due on ${readableDate(dueDate)}.',
              type: 'Rent',
              status: 'Overdue',
              daysLeft: left,
              amount: rent.amount,
              icon: Icons.home_work_outlined,
              color: const Color(0xFFDC2626),
            ),
          );
        } else if (isCollectionWindow) {
          items.add(
            AppNotificationItem(
              title: '${rent.tenantName} rent collection window',
              subtitle:
                  '${rent.propertyName} rent is in collection window. Due date: ${readableDate(dueDate)}.',
              type: 'Rent',
              status: 'Collection Window',
              daysLeft: left,
              amount: rent.amount,
              icon: Icons.home_work_outlined,
              color: const Color(0xFF7C3AED),
            ),
          );
        } else if (left <= reminder.remindBeforeDays) {
          items.add(
            AppNotificationItem(
              title: '${rent.tenantName} rent due soon',
              subtitle:
                  '${rent.propertyName} rent is due on ${readableDate(dueDate)}.',
              type: 'Rent',
              status: left == 0 ? 'Due Today' : 'Due Soon',
              daysLeft: left,
              amount: rent.amount,
              icon: Icons.home_work_outlined,
              color: const Color(0xFF7C3AED),
            ),
          );
        }
      }
    }

    if (reminder.loanRemindersEnabled) {
      for (final loan in finance.loans) {
        if (loan.isPaid) continue;

        final dueDate = tryParseDate(loan.date);
        if (dueDate == null) continue;

        final left = daysLeft(dueDate);

        if (left < 0) {
          items.add(
            AppNotificationItem(
              title: '${loan.personName} loan is overdue',
              subtitle:
                  '${loan.loanType} loan for ${loan.loanPurpose} was due on ${readableDate(dueDate)}.',
              type: 'Loan',
              status: 'Overdue',
              daysLeft: left,
              amount: loan.amount,
              icon: Icons.handshake_outlined,
              color: const Color(0xFFDC2626),
            ),
          );
        } else if (left <= reminder.remindBeforeDays) {
          items.add(
            AppNotificationItem(
              title: '${loan.personName} loan due soon',
              subtitle:
                  '${loan.loanType} loan for ${loan.loanPurpose} is due on ${readableDate(dueDate)}.',
              type: 'Loan',
              status: left == 0 ? 'Due Today' : 'Due Soon',
              daysLeft: left,
              amount: loan.amount,
              icon: Icons.handshake_outlined,
              color: const Color(0xFFF59E0B),
            ),
          );
        }
      }
    }

    items.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

    return items;
  }

  List<AppNotificationItem> applyFilter(List<AppNotificationItem> items) {
    if (selectedFilter == NotificationFilter.all) return items;

    if (selectedFilter == NotificationFilter.dueSoon) {
      return items
          .where(
            (item) =>
                item.status == 'Due Soon' ||
                item.status == 'Due Today' ||
                item.status == 'Collection Window',
          )
          .toList();
    }

    if (selectedFilter == NotificationFilter.overdue) {
      return items.where((item) => item.status == 'Overdue').toList();
    }

    if (selectedFilter == NotificationFilter.bills) {
      return items.where((item) => item.type == 'Bill').toList();
    }

    if (selectedFilter == NotificationFilter.rent) {
      return items.where((item) => item.type == 'Rent').toList();
    }

    if (selectedFilter == NotificationFilter.loans) {
      return items.where((item) => item.type == 'Loan').toList();
    }

    return items;
  }

  int countByType(List<AppNotificationItem> items, String type) {
    return items.where((item) => item.type == type).length;
  }

  int countOverdue(List<AppNotificationItem> items) {
    return items.where((item) => item.status == 'Overdue').length;
  }

  int countDueSoon(List<AppNotificationItem> items) {
    return items
        .where(
          (item) =>
              item.status == 'Due Soon' ||
              item.status == 'Due Today' ||
              item.status == 'Collection Window',
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final reminder = context.watch<ReminderProvider>();

    final allItems = buildNotifications(
      finance: finance,
      reminder: reminder,
    );

    final items = applyFilter(allItems);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 950),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NotificationsHeader(
                    totalCount: allItems.length,
                    overdueCount: countOverdue(allItems),
                    dueSoonCount: countDueSoon(allItems),
                  ),
                  const SizedBox(height: 18),
                  _NotificationFilterBar(
                    selectedFilter: selectedFilter,
                    totalCount: allItems.length,
                    dueSoonCount: countDueSoon(allItems),
                    overdueCount: countOverdue(allItems),
                    billCount: countByType(allItems, 'Bill'),
                    rentCount: countByType(allItems, 'Rent'),
                    loanCount: countByType(allItems, 'Loan'),
                    onChanged: (filter) {
                      setState(() {
                        selectedFilter = filter;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  _ReminderSettingsCard(reminder: reminder),
                  const SizedBox(height: 18),
                  if (items.isEmpty)
                    const _EmptyNotificationsState()
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _NotificationCard(item: items[index]);
                      },
                    ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppNotificationItem {
  const AppNotificationItem({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.status,
    required this.daysLeft,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String type;
  final String status;
  final int daysLeft;
  final double amount;
  final IconData icon;
  final Color color;
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.totalCount,
    required this.overdueCount,
    required this.dueSoonCount,
  });

  final int totalCount;
  final int overdueCount;
  final int dueSoonCount;

  @override
  Widget build(BuildContext context) {
    final hasUrgent = overdueCount > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasUrgent
              ? const [Color(0xFFDC2626), Color(0xFF7F1D1D)]
              : const [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: (hasUrgent ? const Color(0xFFDC2626) : const Color(0xFF2563EB))
                .withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 14,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Track bills, rent, and loans before they become late.',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeaderPill(
                icon: Icons.notifications_active_outlined,
                label: '$totalCount Alerts',
              ),
              _HeaderPill(
                icon: Icons.schedule_outlined,
                label: '$dueSoonCount Due Soon',
              ),
              _HeaderPill(
                icon: Icons.warning_amber_rounded,
                label: '$overdueCount Overdue',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 19),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationFilterBar extends StatelessWidget {
  const _NotificationFilterBar({
    required this.selectedFilter,
    required this.totalCount,
    required this.dueSoonCount,
    required this.overdueCount,
    required this.billCount,
    required this.rentCount,
    required this.loanCount,
    required this.onChanged,
  });

  final NotificationFilter selectedFilter;
  final int totalCount;
  final int dueSoonCount;
  final int overdueCount;
  final int billCount;
  final int rentCount;
  final int loanCount;
  final ValueChanged<NotificationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = [
      _NotificationFilterData(
        filter: NotificationFilter.all,
        label: 'All',
        count: totalCount,
        icon: Icons.list_alt_outlined,
        color: const Color(0xFF2563EB),
      ),
      _NotificationFilterData(
        filter: NotificationFilter.dueSoon,
        label: 'Due Soon',
        count: dueSoonCount,
        icon: Icons.schedule_outlined,
        color: const Color(0xFFF59E0B),
      ),
      _NotificationFilterData(
        filter: NotificationFilter.overdue,
        label: 'Overdue',
        count: overdueCount,
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFDC2626),
      ),
      _NotificationFilterData(
        filter: NotificationFilter.bills,
        label: 'Bills',
        count: billCount,
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF2563EB),
      ),
      _NotificationFilterData(
        filter: NotificationFilter.rent,
        label: 'Rent',
        count: rentCount,
        icon: Icons.home_work_outlined,
        color: const Color(0xFF7C3AED),
      ),
      _NotificationFilterData(
        filter: NotificationFilter.loans,
        label: 'Loans',
        count: loanCount,
        icon: Icons.handshake_outlined,
        color: const Color(0xFFF59E0B),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((item) {
          final isSelected = selectedFilter == item.filter;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              selected: isSelected,
              showCheckmark: false,
              avatar: Icon(
                item.icon,
                size: 18,
                color: isSelected ? Colors.white : item.color,
              ),
              label: Text(
                '${item.label} (${item.count})',
                style: TextStyle(
                  color: isSelected ? Colors.white : item.color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              selectedColor: item.color,
              backgroundColor: item.color.withOpacity(0.10),
              side: BorderSide(color: item.color.withOpacity(0.25)),
              onSelected: (_) => onChanged(item.filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NotificationFilterData {
  const _NotificationFilterData({
    required this.filter,
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final NotificationFilter filter;
  final String label;
  final int count;
  final IconData icon;
  final Color color;
}

class _ReminderSettingsCard extends StatelessWidget {
  const _ReminderSettingsCard({
    required this.reminder,
  });

  final ReminderProvider reminder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFEFF6FF),
            child: Icon(
              Icons.settings_suggest_outlined,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Reminder window: ${reminder.remindBeforeDays} day(s) before due date. Channel: ${reminder.reminderChannel}. Email/SMS will require backend integration.',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
  });

  final AppNotificationItem item;

  String badgeText() {
    if (item.daysLeft < 0) {
      return '${item.daysLeft.abs()}d late';
    }

    if (item.daysLeft == 0) {
      return 'Today';
    }

    return '${item.daysLeft}d left';
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = item.status == 'Overdue';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isOverdue ? item.color.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOverdue ? item.color.withOpacity(0.25) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: item.color.withOpacity(0.12),
            child: Icon(
              item.icon,
              color: item.color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SmallPill(
                      label: item.type,
                      color: item.color,
                    ),
                    _SmallPill(
                      label: item.status,
                      color: item.color,
                    ),
                    _SmallPill(
                      label: badgeText(),
                      color: item.color,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 62,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          const Text(
            'No notifications found',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Due soon and overdue bills, rent, and loan reminders will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}