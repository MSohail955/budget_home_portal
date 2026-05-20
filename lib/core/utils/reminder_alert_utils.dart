import '../providers/finance_provider.dart';
import '../providers/reminder_provider.dart';

class ReminderAlert {
  const ReminderAlert({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.daysLeft,
  });

  final String title;
  final String subtitle;
  final String type;
  final int daysLeft;
}

class ReminderAlertUtils {
  static List<ReminderAlert> buildUpcomingAlerts({
    required FinanceProvider finance,
    required ReminderProvider reminder,
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    final alerts = <ReminderAlert>[];

    if (reminder.billRemindersEnabled) {
      alerts.addAll(
        _buildFixedBillAlerts(
          reminder: reminder,
          today: now,
        ),
      );

      alerts.addAll(
        _buildSavedBillAlerts(
          bills: finance.bills,
          reminder: reminder,
          today: now,
        ),
      );
    }

    if (reminder.rentRemindersEnabled) {
      alerts.addAll(
        _buildRentAlerts(
          rents: finance.rents,
          reminder: reminder,
          today: now,
        ),
      );
    }

    if (reminder.loanRemindersEnabled) {
      alerts.addAll(
        _buildLoanAlerts(
          loans: finance.loans,
          reminder: reminder,
          today: now,
        ),
      );
    }

    alerts.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

    return alerts.take(8).toList();
  }

  static List<ReminderAlert> _buildFixedBillAlerts({
    required ReminderProvider reminder,
    required DateTime today,
  }) {
    final alerts = <ReminderAlert>[];

    final fixedBills = [
      _FixedReminderBill(
        title: 'Internet Bill',
        day: reminder.internetBillDay,
      ),
      _FixedReminderBill(
        title: 'School Fees',
        day: reminder.schoolFeesDay,
      ),
      _FixedReminderBill(
        title: 'Electricity Bill',
        day: reminder.electricityBillDay,
      ),
    ];

    for (final bill in fixedBills) {
      final dueDate = _nextMonthlyDate(
        today: today,
        day: bill.day,
      );

      final daysLeft = _daysBetween(today, dueDate);

      if (daysLeft <= reminder.remindBeforeDays) {
        alerts.add(
          ReminderAlert(
            title: bill.title,
            subtitle: daysLeft == 0
                ? 'Due today. Pay now to avoid late fees.'
                : 'Due in $daysLeft day(s). Pay before due date.',
            type: 'Bill',
            daysLeft: daysLeft,
          ),
        );
      }
    }

    return alerts;
  }

  static List<ReminderAlert> _buildSavedBillAlerts({
    required List<BillRecord> bills,
    required ReminderProvider reminder,
    required DateTime today,
  }) {
    final alerts = <ReminderAlert>[];

    for (final bill in bills) {
      if (bill.isPaid) continue;

      final dueDate = DateTime.tryParse(bill.dueDate);

      if (dueDate == null) continue;

      final daysLeft = _daysBetween(today, dueDate);

      if (daysLeft < 0 || daysLeft > reminder.remindBeforeDays) continue;

      alerts.add(
        ReminderAlert(
          title: bill.title,
          subtitle: daysLeft == 0
              ? '${bill.category} bill is due today.'
              : '${bill.category} bill is due in $daysLeft day(s).',
          type: 'Bill',
          daysLeft: daysLeft,
        ),
      );
    }

    return alerts;
  }

  static List<ReminderAlert> _buildRentAlerts({
    required List<RentRecord> rents,
    required ReminderProvider reminder,
    required DateTime today,
  }) {
    final alerts = <ReminderAlert>[];

    final currentDay = today.day;

    final isInsideRentWindow = currentDay >= reminder.rentReminderStartDay &&
        currentDay <= reminder.rentReminderEndDay;

    if (isInsideRentWindow) {
      alerts.add(
        ReminderAlert(
          title: 'Rent Collection Window',
          subtitle:
              'Rent collection is active from day ${reminder.rentReminderStartDay} to ${reminder.rentReminderEndDay}.',
          type: 'Rent',
          daysLeft: 0,
        ),
      );
    } else {
      final nextRentStart = _nextMonthlyDate(
        today: today,
        day: reminder.rentReminderStartDay,
      );

      final daysLeft = _daysBetween(today, nextRentStart);

      if (daysLeft <= reminder.remindBeforeDays) {
        alerts.add(
          ReminderAlert(
            title: 'Rent Collection',
            subtitle: 'Rent collection starts in $daysLeft day(s).',
            type: 'Rent',
            daysLeft: daysLeft,
          ),
        );
      }
    }

    for (final rent in rents) {
      if (rent.isPaid) continue;

      final dueDate = DateTime.tryParse(rent.dueDate);

      if (dueDate == null) continue;

      final daysLeft = _daysBetween(today, dueDate);

      if (daysLeft < 0 || daysLeft > reminder.remindBeforeDays) continue;

      alerts.add(
        ReminderAlert(
          title: rent.propertyName,
          subtitle: daysLeft == 0
              ? 'Rent from ${rent.tenantName} is due today.'
              : 'Rent from ${rent.tenantName} is due in $daysLeft day(s).',
          type: 'Rent',
          daysLeft: daysLeft,
        ),
      );
    }

    return alerts;
  }

  static List<ReminderAlert> _buildLoanAlerts({
    required List<LoanRecord> loans,
    required ReminderProvider reminder,
    required DateTime today,
  }) {
    final alerts = <ReminderAlert>[];

    for (final loan in loans) {
      if (loan.isPaid) continue;

      final dueDate = DateTime.tryParse(loan.date);

      if (dueDate == null) continue;

      final daysLeft = _daysBetween(today, dueDate);

      if (daysLeft < 0 || daysLeft > reminder.remindBeforeDays) continue;

      alerts.add(
        ReminderAlert(
          title: '${loan.loanType} Loan - ${loan.personName}',
          subtitle: daysLeft == 0
              ? 'Loan payment/reminder is due today.'
              : 'Loan payment/reminder is due in $daysLeft day(s).',
          type: 'Loan',
          daysLeft: daysLeft,
        ),
      );
    }

    return alerts;
  }

  static DateTime _nextMonthlyDate({
    required DateTime today,
    required int day,
  }) {
    final currentMonthSafeDay = _clampDay(
      year: today.year,
      month: today.month,
      day: day,
    );

    final currentMonthDate = DateTime(
      today.year,
      today.month,
      currentMonthSafeDay,
    );

    final todayOnly = DateTime(today.year, today.month, today.day);

    if (!currentMonthDate.isBefore(todayOnly)) {
      return currentMonthDate;
    }

    final nextMonth = today.month == 12 ? 1 : today.month + 1;
    final nextYear = today.month == 12 ? today.year + 1 : today.year;

    final nextMonthSafeDay = _clampDay(
      year: nextYear,
      month: nextMonth,
      day: day,
    );

    return DateTime(nextYear, nextMonth, nextMonthSafeDay);
  }

  static int _clampDay({
    required int year,
    required int month,
    required int day,
  }) {
    final lastDay = DateTime(year, month + 1, 0).day;

    if (day < 1) return 1;
    if (day > lastDay) return lastDay;

    return day;
  }

  static int _daysBetween(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);

    return end.difference(start).inDays;
  }
}

class _FixedReminderBill {
  const _FixedReminderBill({
    required this.title,
    required this.day,
  });

  final String title;
  final int day;
}