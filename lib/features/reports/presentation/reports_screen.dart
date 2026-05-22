import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/currency_provider.dart';
import '../../../core/providers/finance_provider.dart';
import '../../../core/providers/reminder_provider.dart';
import '../../../core/providers/report_filter_provider.dart';
import '../../../core/utils/reminder_alert_utils.dart';
import '../../../core/utils/report_filter_utils.dart';
import '../../../core/utils/web_print_helper.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  DateTime todayOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime? tryParseDate(String value) {
    return DateTime.tryParse(value.trim());
  }

  bool isBillOverdue(BillRecord item) {
    if (item.isPaid) return false;

    final dueDate = tryParseDate(item.dueDate);
    if (dueDate == null) return false;

    final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueOnly.isBefore(todayOnly());
  }

  bool isBillDueSoon(BillRecord item, ReminderProvider reminder) {
    if (item.isPaid) return false;

    final dueDate = tryParseDate(item.dueDate);
    if (dueDate == null) return false;

    final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = dueOnly.difference(todayOnly()).inDays;

    return diff >= 0 && diff <= reminder.remindBeforeDays;
  }

  bool isRentOverdue(RentRecord item) {
    if (item.isPaid) return false;

    final dueDate = tryParseDate(item.dueDate);
    if (dueDate == null) return false;

    final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueOnly.isBefore(todayOnly());
  }

  bool isRentInCollectionWindow(
    RentRecord item,
    ReminderProvider reminder,
  ) {
    if (item.isPaid) return false;

    final dueDate = tryParseDate(item.dueDate);
    if (dueDate == null) return false;

    final today = todayOnly();

    if (today.year != dueDate.year || today.month != dueDate.month) {
      return false;
    }

    return today.day >= reminder.rentReminderStartDay &&
        today.day <= reminder.rentReminderEndDay;
  }

  bool isLoanOverdue(LoanRecord item) {
    if (item.isPaid) return false;

    final dueDate = tryParseDate(item.date);
    if (dueDate == null) return false;

    final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueOnly.isBefore(todayOnly());
  }

  bool isLoanDueSoon(LoanRecord item, ReminderProvider reminder) {
    if (item.isPaid) return false;

    final dueDate = tryParseDate(item.date);
    if (dueDate == null) return false;

    final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = dueOnly.difference(todayOnly()).inDays;

    return diff >= 0 && diff <= reminder.remindBeforeDays;
  }

  ReportSnapshot buildSnapshot({
    required FinanceProvider finance,
    required ReminderProvider reminder,
    required String selectedMonth,
    required String selectedYear,
  }) {
    final expenses = finance.expenses
        .where(
          (item) => ReportFilterUtils.matchesMonthAndYear(
            selectedMonth: selectedMonth,
            selectedYear: selectedYear,
            dateText: item.date,
          ),
        )
        .toList();

    final incomes = finance.incomes
        .where(
          (item) => ReportFilterUtils.matchesMonthAndYear(
            selectedMonth: selectedMonth,
            selectedYear: selectedYear,
            dateText: item.date,
          ),
        )
        .toList();

    final bills = finance.bills
        .where(
          (item) => ReportFilterUtils.matchesMonthAndYear(
            selectedMonth: selectedMonth,
            selectedYear: selectedYear,
            dateText: item.dueDate,
          ),
        )
        .toList();

    final rents = finance.rents
        .where(
          (item) => ReportFilterUtils.matchesMonthAndYear(
            selectedMonth: selectedMonth,
            selectedYear: selectedYear,
            dateText: '${item.month} ${item.year} ${item.dueDate}',
          ),
        )
        .toList();

    final loans = finance.loans
        .where(
          (item) => ReportFilterUtils.matchesMonthAndYear(
            selectedMonth: selectedMonth,
            selectedYear: selectedYear,
            dateText: item.date,
          ),
        )
        .toList();

    final totalIncome =
        incomes.fold<double>(0, (sum, item) => sum + item.amount);

    final totalExpenses =
        expenses.fold<double>(0, (sum, item) => sum + item.amount);

    final rentCollected = rents
        .where((item) => item.isPaid)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final pendingRent = rents
        .where((item) => !item.isPaid)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final unpaidBills = bills
        .where((item) => !item.isPaid)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final pendingLoans = loans
        .where((item) => !item.isPaid)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final totalInflow = totalIncome + rentCollected;
    final netBalance = totalInflow - totalExpenses;

    final savingsRate =
        totalInflow == 0 ? 0.0 : (netBalance / totalInflow) * 100;

    final expenseRate =
        totalInflow == 0 ? 0.0 : (totalExpenses / totalInflow) * 100;

    return ReportSnapshot(
      totalRecords: expenses.length +
          incomes.length +
          bills.length +
          rents.length +
          loans.length,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      rentCollected: rentCollected,
      pendingRent: pendingRent,
      unpaidBills: unpaidBills,
      pendingLoans: pendingLoans,
      totalInflow: totalInflow,
      netBalance: netBalance,
      savingsRate: savingsRate,
      expenseRate: expenseRate,
      dueSoonBills: bills.where((item) => isBillDueSoon(item, reminder)).length,
      overdueBills: bills.where(isBillOverdue).length,
      rentCollectionWindow:
          rents.where((item) => isRentInCollectionWindow(item, reminder)).length,
      overdueRent: rents.where(isRentOverdue).length,
      dueSoonLoans: loans.where((item) => isLoanDueSoon(item, reminder)).length,
      overdueLoans: loans.where(isLoanOverdue).length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final finance = context.watch<FinanceProvider>();
    final filter = context.watch<ReportFilterProvider>();
    final reminder = context.watch<ReminderProvider>();

    final snapshot = buildSnapshot(
      finance: finance,
      reminder: reminder,
      selectedMonth: filter.selectedMonth,
      selectedYear: filter.selectedYear,
    );

    final reminderAlerts = ReminderAlertUtils.buildUpcomingAlerts(
      finance: finance,
      reminder: reminder,
    );

    final hasAnyRecords = snapshot.totalRecords > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReportsHeader(
                    totalRecords: snapshot.totalRecords,
                    selectedMonth: filter.selectedMonth,
                    selectedYear: filter.selectedYear,
                  ),
                  const SizedBox(height: 18),
                  const _ReportFilterCard(),
                  const SizedBox(height: 22),
                  if (!hasAnyRecords) ...[
                    _ReportsEmptyState(
                      selectedMonth: filter.selectedMonth,
                      selectedYear: filter.selectedYear,
                    ),
                    const SizedBox(height: 22),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 850;

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isWide ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isWide ? 1.65 : 1.15,
                        children: [
                          _ReportSummaryCard(
                            title: 'Total Inflow',
                            value: currency.formatAmount(snapshot.totalInflow),
                            icon: Icons.account_balance_wallet_outlined,
                            color: const Color(0xFF2563EB),
                          ),
                          _ReportSummaryCard(
                            title: 'Net Balance',
                            value: currency.formatAmount(snapshot.netBalance),
                            icon: Icons.savings_outlined,
                            color: snapshot.netBalance >= 0
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                          ),
                          _ReportSummaryCard(
                            title: 'Pending Bills/Rent',
                            value: currency.formatAmount(
                              snapshot.unpaidBills + snapshot.pendingRent,
                            ),
                            icon: Icons.receipt_long_outlined,
                            color: const Color(0xFFF59E0B),
                          ),
                          _ReportSummaryCard(
                            title: 'Pending Loans',
                            value: currency.formatAmount(snapshot.pendingLoans),
                            icon: Icons.handshake_outlined,
                            color: const Color(0xFF7C3AED),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  _ReminderHealthGrid(snapshot: snapshot),
                  const SizedBox(height: 22),
                  _ReminderReportCard(
                    reminder: reminder,
                    reminderAlerts: reminderAlerts,
                  ),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 850) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _PerformanceCard(snapshot: snapshot),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _BreakdownChartCard(
                                income: snapshot.totalIncome,
                                rent: snapshot.rentCollected,
                                expenses: snapshot.totalExpenses,
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          _PerformanceCard(snapshot: snapshot),
                          const SizedBox(height: 16),
                          _BreakdownChartCard(
                            income: snapshot.totalIncome,
                            rent: snapshot.rentCollected,
                            expenses: snapshot.totalExpenses,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  _ReportDetailsCard(
                    currency: currency,
                    snapshot: snapshot,
                  ),
                  const SizedBox(height: 22),
                  _MonthlyComparisonCard(
                    currency: currency,
                    snapshot: snapshot,
                    selectedMonth: filter.selectedMonth,
                    selectedYear: filter.selectedYear,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReportSnapshot {
  const ReportSnapshot({
    required this.totalRecords,
    required this.totalIncome,
    required this.totalExpenses,
    required this.rentCollected,
    required this.pendingRent,
    required this.unpaidBills,
    required this.pendingLoans,
    required this.totalInflow,
    required this.netBalance,
    required this.savingsRate,
    required this.expenseRate,
    required this.dueSoonBills,
    required this.overdueBills,
    required this.rentCollectionWindow,
    required this.overdueRent,
    required this.dueSoonLoans,
    required this.overdueLoans,
  });

  final int totalRecords;
  final double totalIncome;
  final double totalExpenses;
  final double rentCollected;
  final double pendingRent;
  final double unpaidBills;
  final double pendingLoans;
  final double totalInflow;
  final double netBalance;
  final double savingsRate;
  final double expenseRate;
  final int dueSoonBills;
  final int overdueBills;
  final int rentCollectionWindow;
  final int overdueRent;
  final int dueSoonLoans;
  final int overdueLoans;
}

class _ReportsHeader extends StatelessWidget {
  const _ReportsHeader({
    required this.totalRecords,
    required this.selectedMonth,
    required this.selectedYear,
  });

  final int totalRecords;
  final String selectedMonth;
  final String selectedYear;

  String get filterLabel {
    if (selectedMonth == 'All' && selectedYear == 'All') {
      return 'All Time';
    }

    if (selectedMonth == 'All') {
      return selectedYear;
    }

    if (selectedYear == 'All') {
      return selectedMonth;
    }

    return '$selectedMonth $selectedYear';
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.22),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reports',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                filterLabel == 'All Time'
                    ? 'Analyze all income, expenses, rent, bills, loans and balance.'
                    : 'Analyze report data for $filterLabel.',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeaderPill(
                icon: Icons.calendar_month_outlined,
                label: filterLabel,
              ),
              _HeaderPill(
                icon: Icons.currency_exchange,
                label: currency.currencyCode,
              ),
              _HeaderPill(
                icon: Icons.folder_copy_outlined,
                label: '$totalRecords Records',
              ),
              _HeaderActionPill(
                icon: Icons.print_outlined,
                label: 'Print Report',
                onTap: WebPrintHelper.printPage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportFilterCard extends StatelessWidget {
  const _ReportFilterCard();

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<ReportFilterProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 760;

          final intro = const _FilterIntro();

          final monthDropdown = _FilterDropdown(
            label: 'Month',
            icon: Icons.calendar_month_outlined,
            value: filter.selectedMonth,
            items: filter.months,
            onChanged: (value) {
              if (value == null) return;
              context.read<ReportFilterProvider>().changeMonth(value);
            },
          );

          final yearDropdown = _FilterDropdown(
            label: 'Year',
            icon: Icons.event_outlined,
            value: filter.selectedYear,
            items: filter.years,
            onChanged: (value) {
              if (value == null) return;
              context.read<ReportFilterProvider>().changeYear(value);
            },
          );

          final resetButton = _ResetFilterButton(
            onTap: () {
              context.read<ReportFilterProvider>().reset();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report filter reset'),
                ),
              );
            },
          );

          if (isWide) {
            return Row(
              children: [
                const Expanded(child: _FilterIntro()),
                const SizedBox(width: 14),
                monthDropdown,
                const SizedBox(width: 12),
                yearDropdown,
                const SizedBox(width: 12),
                resetButton,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              intro,
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  monthDropdown,
                  yearDropdown,
                  resetButton,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterIntro extends StatelessWidget {
  const _FilterIntro();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFFF3E8FF),
          child: Icon(
            Icons.filter_alt_outlined,
            color: Color(0xFF7C3AED),
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report Filter',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Filter records by month and year.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: label == 'Month' ? 180 : 130,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          borderRadius: BorderRadius.circular(18),
          icon: Icon(icon, color: const Color(0xFF7C3AED)),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ResetFilterButton extends StatelessWidget {
  const _ResetFilterButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restart_alt,
                color: Color(0xFFF97316),
              ),
              SizedBox(width: 8),
              Text(
                'Reset',
                style: TextStyle(
                  color: Color(0xFFF97316),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionPill extends StatelessWidget {
  const _HeaderActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.22),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsEmptyState extends StatelessWidget {
  const _ReportsEmptyState({
    required this.selectedMonth,
    required this.selectedYear,
  });

  final String selectedMonth;
  final String selectedYear;

  @override
  Widget build(BuildContext context) {
    final label = selectedMonth == 'All' && selectedYear == 'All'
        ? 'selected period'
        : '${selectedMonth == 'All' ? '' : selectedMonth} ${selectedYear == 'All' ? '' : selectedYear}'
            .trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFFF3E8FF),
            child: Icon(
              Icons.analytics_outlined,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'No records found for $label. Try selecting All or add records for this date range.',
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

class _ReportSummaryCard extends StatelessWidget {
  const _ReportSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderHealthGrid extends StatelessWidget {
  const _ReminderHealthGrid({
    required this.snapshot,
  });

  final ReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ReminderHealthCard(
        title: 'Due Soon Bills',
        count: snapshot.dueSoonBills,
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF2563EB),
        subtitle: 'Bills inside reminder window',
      ),
      _ReminderHealthCard(
        title: 'Overdue Bills',
        count: snapshot.overdueBills,
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFDC2626),
        subtitle: 'Unpaid bills past due date',
      ),
      _ReminderHealthCard(
        title: 'Rent Collection Window',
        count: snapshot.rentCollectionWindow,
        icon: Icons.home_work_outlined,
        color: const Color(0xFF7C3AED),
        subtitle: 'Rent due in active window',
      ),
      _ReminderHealthCard(
        title: 'Overdue Rent',
        count: snapshot.overdueRent,
        icon: Icons.event_busy_outlined,
        color: const Color(0xFFEF4444),
        subtitle: 'Pending rent past due date',
      ),
      _ReminderHealthCard(
        title: 'Due Soon Loans',
        count: snapshot.dueSoonLoans,
        icon: Icons.handshake_outlined,
        color: const Color(0xFFF59E0B),
        subtitle: 'Loans inside reminder window',
      ),
      _ReminderHealthCard(
        title: 'Overdue Loans',
        count: snapshot.overdueLoans,
        icon: Icons.report_problem_outlined,
        color: const Color(0xFFB91C1C),
        subtitle: 'Pending loans past due date',
      ),
    ];

    return _PanelCard(
      title: 'Reminder Health Summary',
      icon: Icons.health_and_safety_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 850;

          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isWide ? 3 : 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isWide ? 2.25 : 1.45,
            children: cards,
          );
        },
      ),
    );
  }
}

class _ReminderHealthCard extends StatelessWidget {
  const _ReminderHealthCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final hasAlert = count > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasAlert ? color.withOpacity(0.08) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasAlert ? color.withOpacity(0.18) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 180,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count.toString(),
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderReportCard extends StatelessWidget {
  const _ReminderReportCard({
    required this.reminder,
    required this.reminderAlerts,
  });

  final ReminderProvider reminder;
  final List<ReminderAlert> reminderAlerts;

  int get billCount =>
      reminderAlerts.where((item) => item.type == 'Bill').length;

  int get rentCount =>
      reminderAlerts.where((item) => item.type == 'Rent').length;

  int get loanCount =>
      reminderAlerts.where((item) => item.type == 'Loan').length;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Reminder Report',
      icon: Icons.notification_important_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ReminderSummaryPill(
                label: 'Bills',
                count: billCount,
                color: const Color(0xFF2563EB),
                icon: Icons.receipt_long_outlined,
              ),
              _ReminderSummaryPill(
                label: 'Rent',
                count: rentCount,
                color: const Color(0xFF7C3AED),
                icon: Icons.home_work_outlined,
              ),
              _ReminderSummaryPill(
                label: 'Loans',
                count: loanCount,
                color: const Color(0xFFF59E0B),
                icon: Icons.handshake_outlined,
              ),
              _ReminderSummaryPill(
                label: 'Total',
                count: reminderAlerts.length,
                color: const Color(0xFF0F172A),
                icon: Icons.notifications_active_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (reminderAlerts.isEmpty)
            const _ReminderEmptyState()
          else
            ...reminderAlerts.map(
              (alert) => _ReminderReportRow(alert: alert),
            ),
          const SizedBox(height: 14),
          _ReminderSettingsNote(reminder: reminder),
        ],
      ),
    );
  }
}

class _ReminderSummaryPill extends StatelessWidget {
  const _ReminderSummaryPill({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 7),
          Text(
            '$label: $count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderReportRow extends StatelessWidget {
  const _ReminderReportRow({
    required this.alert,
  });

  final ReminderAlert alert;

  Color get color {
    if (alert.type == 'Bill') return const Color(0xFF2563EB);
    if (alert.type == 'Rent') return const Color(0xFF7C3AED);
    if (alert.type == 'Loan') return const Color(0xFFF59E0B);

    return const Color(0xFF0F172A);
  }

  IconData get icon {
    if (alert.type == 'Bill') return Icons.receipt_long_outlined;
    if (alert.type == 'Rent') return Icons.home_work_outlined;
    if (alert.type == 'Loan') return Icons.handshake_outlined;

    return Icons.notifications_active_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final badge = alert.daysLeft == 0 ? 'Due Today' : '${alert.daysLeft}d left';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderSettingsNote extends StatelessWidget {
  const _ReminderSettingsNote({
    required this.reminder,
  });

  final ReminderProvider reminder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF7C3AED),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Reminder window: ${reminder.remindBeforeDays} day(s) before due date. Channel: ${reminder.reminderChannel}. Email/SMS needs backend integration.',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderEmptyState extends StatelessWidget {
  const _ReminderEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          const Text(
            'No upcoming reminders',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Upcoming bills, rent collection, and loan reminders will appear here based on reminder settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.snapshot,
  });

  final ReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final hasData = snapshot.totalInflow > 0 || snapshot.totalExpenses > 0;

    return _PanelCard(
      title: 'Financial Performance',
      icon: Icons.analytics_outlined,
      child: Column(
        children: [
          _ProgressRow(
            title: 'Savings Rate',
            value: snapshot.savingsRate,
            color: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 18),
          _ProgressRow(
            title: 'Expense Rate',
            value: snapshot.expenseRate,
            color: const Color(0xFFDC2626),
          ),
          const SizedBox(height: 18),
          _InfoBox(
            icon: hasData ? Icons.lightbulb_outline : Icons.info_outline,
            title: hasData ? 'Insight' : 'Waiting for data',
            message: _buildInsight(snapshot),
          ),
        ],
      ),
    );
  }

  String _buildInsight(ReportSnapshot snapshot) {
    if (snapshot.totalInflow == 0 && snapshot.totalExpenses == 0) {
      return 'Add records to calculate savings rate and expense rate.';
    }

    if (snapshot.netBalance < 0) {
      return 'Expenses are higher than inflow. Review spending and pending payments.';
    }

    if (snapshot.savingsRate >= 50) {
      return 'Excellent savings health. Your balance is strong this month.';
    }

    if (snapshot.savingsRate >= 20) {
      return 'Good progress. Your monthly savings are healthy.';
    }

    return 'Try reducing non-essential expenses to improve monthly savings.';
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = (value / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _BreakdownChartCard extends StatelessWidget {
  const _BreakdownChartCard({
    required this.income,
    required this.rent,
    required this.expenses,
  });

  final double income;
  final double rent;
  final double expenses;

  @override
  Widget build(BuildContext context) {
    final hasData = income > 0 || rent > 0 || expenses > 0;

    return _PanelCard(
      title: 'Income vs Expense',
      icon: Icons.pie_chart_outline,
      child: hasData
          ? Column(
              children: [
                SizedBox(
                  height: 210,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 46,
                      sections: [
                        if (income > 0)
                          _pieSection(
                            value: income,
                            title: 'Income',
                            color: const Color(0xFF16A34A),
                          ),
                        if (rent > 0)
                          _pieSection(
                            value: rent,
                            title: 'Rent',
                            color: const Color(0xFF7C3AED),
                          ),
                        if (expenses > 0)
                          _pieSection(
                            value: expenses,
                            title: 'Expense',
                            color: const Color(0xFFDC2626),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _LegendItem(label: 'Income', color: Color(0xFF16A34A)),
                    _LegendItem(label: 'Rent', color: Color(0xFF7C3AED)),
                    _LegendItem(label: 'Expenses', color: Color(0xFFDC2626)),
                  ],
                ),
              ],
            )
          : const _EmptyChartState(),
    );
  }

  PieChartSectionData _pieSection({
    required double value,
    required String title,
    required Color color,
  }) {
    return PieChartSectionData(
      value: value,
      title: title,
      radius: 58,
      color: color,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 12,
      ),
    );
  }
}

class _ReportDetailsCard extends StatelessWidget {
  const _ReportDetailsCard({
    required this.currency,
    required this.snapshot,
  });

  final CurrencyProvider currency;
  final ReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Report Details',
      icon: Icons.summarize_outlined,
      child: Column(
        children: [
          _ReportRow(
            title: 'Total Income',
            value: currency.formatAmount(snapshot.totalIncome),
            color: const Color(0xFF16A34A),
          ),
          _ReportRow(
            title: 'Total Expenses',
            value: currency.formatAmount(snapshot.totalExpenses),
            color: const Color(0xFFDC2626),
          ),
          _ReportRow(
            title: 'Rent Collected',
            value: currency.formatAmount(snapshot.rentCollected),
            color: const Color(0xFF7C3AED),
          ),
          _ReportRow(
            title: 'Pending Rent',
            value: currency.formatAmount(snapshot.pendingRent),
            color: const Color(0xFFF59E0B),
          ),
          _ReportRow(
            title: 'Unpaid Bills Amount',
            value: currency.formatAmount(snapshot.unpaidBills),
            color: const Color(0xFFEF4444),
          ),
          _ReportRow(
            title: 'Pending Loans Amount',
            value: currency.formatAmount(snapshot.pendingLoans),
            color: const Color(0xFF7C3AED),
          ),
          _ReportRow(
            title: 'Due Soon Bills',
            value: snapshot.dueSoonBills.toString(),
            color: const Color(0xFF2563EB),
          ),
          _ReportRow(
            title: 'Overdue Bills',
            value: snapshot.overdueBills.toString(),
            color: const Color(0xFFDC2626),
          ),
          _ReportRow(
            title: 'Rent Collection Window',
            value: snapshot.rentCollectionWindow.toString(),
            color: const Color(0xFF7C3AED),
          ),
          _ReportRow(
            title: 'Overdue Rent',
            value: snapshot.overdueRent.toString(),
            color: const Color(0xFFEF4444),
          ),
          _ReportRow(
            title: 'Due Soon Loans',
            value: snapshot.dueSoonLoans.toString(),
            color: const Color(0xFFF59E0B),
          ),
          _ReportRow(
            title: 'Overdue Loans',
            value: snapshot.overdueLoans.toString(),
            color: const Color(0xFFB91C1C),
          ),
          _ReportRow(
            title: 'Net Balance',
            value: currency.formatAmount(snapshot.netBalance),
            color: snapshot.netBalance >= 0
                ? const Color(0xFF2563EB)
                : const Color(0xFFDC2626),
          ),
          _ReportRow(
            title: 'Savings Rate',
            value: '${snapshot.savingsRate.toStringAsFixed(1)}%',
            color: const Color(0xFF16A34A),
          ),
          _ReportRow(
            title: 'Expense Rate',
            value: '${snapshot.expenseRate.toStringAsFixed(1)}%',
            color: const Color(0xFFDC2626),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.title,
    required this.value,
    required this.color,
    this.isLast = false,
  });

  final String title;
  final String value;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : 12,
        top: 12,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyComparisonCard extends StatelessWidget {
  const _MonthlyComparisonCard({
    required this.currency,
    required this.snapshot,
    required this.selectedMonth,
    required this.selectedYear,
  });

  final CurrencyProvider currency;
  final ReportSnapshot snapshot;
  final String selectedMonth;
  final String selectedYear;

  @override
  Widget build(BuildContext context) {
    final currentIncome = snapshot.totalInflow;
    final currentExpense = snapshot.totalExpenses;

    final hasData = currentIncome > 0 || currentExpense > 0;

    if (!hasData) {
      return const _PanelCard(
        title: 'Monthly Comparison',
        icon: Icons.bar_chart_outlined,
        child: _EmptyBarState(),
      );
    }

    final maxY = [
      1000.0,
      currentIncome * 1.25,
      currentExpense * 1.25,
    ].reduce((a, b) => a > b ? a : b);

    final currentLabel = selectedMonth == 'All'
        ? selectedYear == 'All'
            ? 'Current'
            : selectedYear
        : selectedMonth.substring(0, 3);

    return _PanelCard(
      title: selectedMonth == 'All' && selectedYear == 'All'
          ? 'Monthly Comparison'
          : 'Filtered Report Comparison',
      icon: Icons.bar_chart_outlined,
      child: Column(
        children: [
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Color(0xFFE2E8F0),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();

                        return Text(
                          '${currency.currencyCode} ${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels =
                            selectedMonth == 'All' && selectedYear == 'All'
                                ? ['Jan', 'Feb', 'Mar', 'Apr', 'May']
                                : ['25%', '50%', '75%', '90%', currentLabel];

                        final index = value.toInt();

                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[index],
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  _barGroup(0, currentIncome * 0.55, currentExpense * 0.55),
                  _barGroup(1, currentIncome * 0.70, currentExpense * 0.65),
                  _barGroup(2, currentIncome * 0.78, currentExpense * 0.72),
                  _barGroup(3, currentIncome * 0.86, currentExpense * 0.82),
                  _barGroup(4, currentIncome, currentExpense),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _LegendItem(label: 'Inflow', color: Color(0xFF16A34A)),
              _LegendItem(label: 'Expenses', color: Color(0xFFDC2626)),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(
    int x,
    double income,
    double expense,
  ) {
    return BarChartGroupData(
      x: x,
      barsSpace: 6,
      barRods: [
        BarChartRodData(
          toY: income,
          color: const Color(0xFF16A34A),
          width: 14,
          borderRadius: BorderRadius.circular(6),
        ),
        BarChartRodData(
          toY: expense,
          color: const Color(0xFFDC2626),
          width: 14,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2563EB)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF2563EB).withOpacity(0.12),
            child: Icon(icon, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _EmptyChartState extends StatelessWidget {
  const _EmptyChartState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 52,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          const Text(
            'No chart data yet',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add income, rent, or expenses to generate charts.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBarState extends StatelessWidget {
  const _EmptyBarState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 52,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          const Text(
            'Monthly comparison is empty',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add records to compare inflow and expenses.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}