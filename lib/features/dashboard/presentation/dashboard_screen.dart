import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/currency_provider.dart';
import '../../../core/providers/dashboard_filter_provider.dart';
import '../../../core/providers/finance_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/reminder_provider.dart';
import '../../../core/utils/reminder_alert_utils.dart';
import '../../../core/utils/report_filter_utils.dart';
import '../../records/presentation/records_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    this.onOpenRecordSection,
  });

  final void Function(RecordSection section)? onOpenRecordSection;

  DashboardSnapshot buildSnapshot({
    required FinanceProvider finance,
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

    final totalIncome = incomes.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    final totalExpenses = expenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

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

    return DashboardSnapshot(
      selectedMonth: selectedMonth,
      selectedYear: selectedYear,
      expenses: expenses,
      incomes: incomes,
      bills: bills,
      rents: rents,
      loans: loans,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final currency = context.watch<CurrencyProvider>();
    final finance = context.watch<FinanceProvider>();
    final filter = context.watch<DashboardFilterProvider>();
    final reminder = context.watch<ReminderProvider>();

    final upcomingAlerts = ReminderAlertUtils.buildUpcomingAlerts(
      finance: finance,
      reminder: reminder,
    );

    final snapshot = buildSnapshot(
      finance: finance,
      selectedMonth: filter.selectedMonth,
      selectedYear: filter.selectedYear,
    );

    final hasAnyRecords = finance.expenses.isNotEmpty ||
        finance.incomes.isNotEmpty ||
        finance.bills.isNotEmpty ||
        finance.rents.isNotEmpty ||
        finance.loans.isNotEmpty;

    final hasFilteredRecords = snapshot.expenses.isNotEmpty ||
        snapshot.incomes.isNotEmpty ||
        snapshot.bills.isNotEmpty ||
        snapshot.rents.isNotEmpty ||
        snapshot.loans.isNotEmpty;

    final pendingBillsCount =
        snapshot.bills.where((item) => !item.isPaid).length;

    final pendingRentCount =
        snapshot.rents.where((item) => !item.isPaid).length;

    final pendingLoansCount =
        snapshot.loans.where((item) => !item.isPaid).length;

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
                  _PremiumHeader(
                    selectedMonth: snapshot.selectedMonth,
                    selectedYear: snapshot.selectedYear,
                  ),
                  const SizedBox(height: 18),
                  const _DashboardFilterCard(),
                  const SizedBox(height: 22),
                  if (!hasAnyRecords) ...[
                    _NewUserEmptyState(
                      onOpenRecordSection: onOpenRecordSection,
                    ),
                    const SizedBox(height: 22),
                  ] else if (!hasFilteredRecords) ...[
                    _FilteredEmptyState(
                      monthLabel:
                          '${snapshot.selectedMonth} ${snapshot.selectedYear}',
                      onOpenRecordSection: onOpenRecordSection,
                    ),
                    const SizedBox(height: 22),
                  ],
                  _ReminderBadgeGrid(
                    isWide: isWide,
                    upcomingReminders: upcomingAlerts.length,
                    pendingBills: pendingBillsCount,
                    pendingRent: pendingRentCount,
                    pendingLoans: pendingLoansCount,
                    onOpenRecordSection: onOpenRecordSection,
                  ),
                  const SizedBox(height: 22),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isWide ? 4 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isWide ? 1.65 : 1.15,
                    children: [
                      _SummaryCard(
                        title: 'Month Income',
                        value: currency.formatAmount(snapshot.totalIncome),
                        icon: Icons.trending_up,
                        color: const Color(0xFF16A34A),
                      ),
                      _SummaryCard(
                        title: 'Month Expenses',
                        value: currency.formatAmount(snapshot.totalExpenses),
                        icon: Icons.trending_down,
                        color: const Color(0xFFDC2626),
                      ),
                      _SummaryCard(
                        title: 'Rent Collected',
                        value: currency.formatAmount(snapshot.rentCollected),
                        icon: Icons.home_work_outlined,
                        color: const Color(0xFF7C3AED),
                      ),
                      _SummaryCard(
                        title: 'Net Balance',
                        value: currency.formatAmount(snapshot.netBalance),
                        icon: Icons.account_balance_wallet_outlined,
                        color: snapshot.netBalance >= 0
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFDC2626),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 850) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _AlertsCard(
                                currency: currency,
                                snapshot: snapshot,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _RecentActivityCard(
                                currency: currency,
                                snapshot: snapshot,
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          _AlertsCard(
                            currency: currency,
                            snapshot: snapshot,
                          ),
                          const SizedBox(height: 16),
                          _RecentActivityCard(
                            currency: currency,
                            snapshot: snapshot,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  _UpcomingRemindersCard(
                    reminder: reminder,
                    upcomingAlerts: upcomingAlerts,
                  ),
                  const SizedBox(height: 22),
                  _ReminderRulesCard(reminder: reminder),
                  const SizedBox(height: 22),
                  _PerformanceSection(snapshot: snapshot),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.selectedMonth,
    required this.selectedYear,
    required this.expenses,
    required this.incomes,
    required this.bills,
    required this.rents,
    required this.loans,
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
  });

  final String selectedMonth;
  final String selectedYear;
  final List<ExpenseRecord> expenses;
  final List<IncomeRecord> incomes;
  final List<BillRecord> bills;
  final List<RentRecord> rents;
  final List<LoanRecord> loans;
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
}

class _PremiumHeader extends StatelessWidget {
  const _PremiumHeader({
    required this.selectedMonth,
    required this.selectedYear,
  });

  final String selectedMonth;
  final String selectedYear;

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final profile = context.watch<ProfileProvider>();

    final displayName =
        profile.name.trim().isEmpty ? 'User' : profile.name.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 16),
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
              Text(
                'Welcome back, $displayName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Here is your home finance overview for the selected month.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
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
                label: '$selectedMonth $selectedYear',
              ),
              _HeaderPill(
                icon: Icons.currency_exchange,
                label: currency.currencyCode,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardFilterCard extends StatelessWidget {
  const _DashboardFilterCard();

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<DashboardFilterProvider>();

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

          final filterWidgets = [
            const _FilterIntro(),
            _FilterDropdown(
              label: 'Month',
              icon: Icons.calendar_month_outlined,
              value: filter.selectedMonth,
              items: filter.months,
              onChanged: (value) {
                if (value == null) return;
                context.read<DashboardFilterProvider>().changeMonth(value);
              },
            ),
            _FilterDropdown(
              label: 'Year',
              icon: Icons.event_outlined,
              value: filter.selectedYear,
              items: filter.years,
              onChanged: (value) {
                if (value == null) return;
                context.read<DashboardFilterProvider>().changeYear(value);
              },
            ),
            _ResetFilterButton(
              onTap: () {
                context.read<DashboardFilterProvider>().reset();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dashboard filter reset')),
                );
              },
            ),
          ];

          if (isWide) {
            return Row(
              children: [
                Expanded(child: filterWidgets[0]),
                const SizedBox(width: 14),
                filterWidgets[1],
                const SizedBox(width: 12),
                filterWidgets[2],
                const SizedBox(width: 12),
                filterWidgets[3],
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              filterWidgets[0],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  filterWidgets[1],
                  filterWidgets[2],
                  filterWidgets[3],
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
          backgroundColor: Color(0xFFEFF6FF),
          child: Icon(
            Icons.tune_outlined,
            color: Color(0xFF2563EB),
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Filter',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'View dashboard by month and year.',
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
          icon: Icon(icon, color: const Color(0xFF2563EB)),
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
              Icon(Icons.restart_alt, color: Color(0xFFF97316)),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
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
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewUserEmptyState extends StatelessWidget {
  const _NewUserEmptyState({
    required this.onOpenRecordSection,
  });

  final void Function(RecordSection section)? onOpenRecordSection;

  @override
  Widget build(BuildContext context) {
    return _StarterCard(
      title: 'Start your finance workspace',
      subtitle:
          'Your account is fresh. Add your first income, expense, bill, rent, or loan record from the Records section.',
      onOpenRecordSection: onOpenRecordSection,
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({
    required this.monthLabel,
    required this.onOpenRecordSection,
  });

  final String monthLabel;
  final void Function(RecordSection section)? onOpenRecordSection;

  @override
  Widget build(BuildContext context) {
    return _StarterCard(
      title: 'No records for $monthLabel',
      subtitle:
          'No records found for this selected month and year. Add dated records to see dashboard data.',
      onOpenRecordSection: onOpenRecordSection,
    );
  }
}

class _StarterCard extends StatelessWidget {
  const _StarterCard({
    required this.title,
    required this.subtitle,
    required this.onOpenRecordSection,
  });

  final String title;
  final String subtitle;
  final void Function(RecordSection section)? onOpenRecordSection;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StarterPill(
                icon: Icons.add_card_outlined,
                label: 'Add Income',
                color: const Color(0xFF16A34A),
                onTap: () => onOpenRecordSection?.call(RecordSection.income),
              ),
              _StarterPill(
                icon: Icons.shopping_bag_outlined,
                label: 'Add Expense',
                color: const Color(0xFFDC2626),
                onTap: () => onOpenRecordSection?.call(RecordSection.expenses),
              ),
              _StarterPill(
                icon: Icons.receipt_long_outlined,
                label: 'Track Bills',
                color: const Color(0xFF2563EB),
                onTap: () => onOpenRecordSection?.call(RecordSection.bills),
              ),
              _StarterPill(
                icon: Icons.home_work_outlined,
                label: 'Track Rent',
                color: const Color(0xFF7C3AED),
                onTap: () => onOpenRecordSection?.call(RecordSection.rent),
              ),
              _StarterPill(
                icon: Icons.handshake_outlined,
                label: 'Track Loans',
                color: const Color(0xFFF59E0B),
                onTap: () => onOpenRecordSection?.call(RecordSection.loans),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StarterPill extends StatelessWidget {
  const _StarterPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
      backgroundColor: color.withOpacity(0.10),
      side: BorderSide(color: color.withOpacity(0.20)),
      onPressed: onTap,
    );
  }
}

class _ReminderBadgeGrid extends StatelessWidget {
  const _ReminderBadgeGrid({
    required this.isWide,
    required this.upcomingReminders,
    required this.pendingBills,
    required this.pendingRent,
    required this.pendingLoans,
    required this.onOpenRecordSection,
  });

  final bool isWide;
  final int upcomingReminders;
  final int pendingBills;
  final int pendingRent;
  final int pendingLoans;
  final void Function(RecordSection section)? onOpenRecordSection;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ReminderBadgeCard(
        title: 'Upcoming Reminders',
        count: upcomingReminders,
        subtitle: upcomingReminders == 0
            ? 'No upcoming due items'
            : 'Due soon items',
        icon: Icons.event_available_outlined,
        color: const Color(0xFF2563EB),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upcoming reminders are shown below.'),
            ),
          );
        },
      ),
      _ReminderBadgeCard(
        title: 'Pending Bills',
        count: pendingBills,
        subtitle: pendingBills == 0 ? 'All bills clear' : 'Bills unpaid',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFFDC2626),
        onTap: () => onOpenRecordSection?.call(RecordSection.bills),
      ),
      _ReminderBadgeCard(
        title: 'Pending Rent',
        count: pendingRent,
        subtitle: pendingRent == 0 ? 'No rent pending' : 'Rent to collect',
        icon: Icons.home_work_outlined,
        color: const Color(0xFF7C3AED),
        onTap: () => onOpenRecordSection?.call(RecordSection.rent),
      ),
      _ReminderBadgeCard(
        title: 'Pending Loans',
        count: pendingLoans,
        subtitle:
            pendingLoans == 0 ? 'No loan pending' : 'Loans need attention',
        icon: Icons.handshake_outlined,
        color: const Color(0xFFF59E0B),
        onTap: () => onOpenRecordSection?.call(RecordSection.loans),
      ),
    ];

    if (isWide) {
      return Row(
        children: [
          for (int index = 0; index < cards.length; index++) ...[
            Expanded(child: cards[index]),
            if (index != cards.length - 1) const SizedBox(width: 16),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 16),
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }
}

class _ReminderBadgeCard extends StatelessWidget {
  const _ReminderBadgeCard({
    required this.title,
    required this.count,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final int count;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasCount = count > 0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          height: 112,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasCount ? color.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasCount
                  ? color.withOpacity(0.20)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: hasCount
                    ? color.withOpacity(0.08)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: color.withOpacity(0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
            style: const TextStyle(
              color: Color(0xFF64748B),
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
              maxLines: 1,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({
    required this.currency,
    required this.snapshot,
  });

  final CurrencyProvider currency;
  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final unpaidBills = snapshot.bills.where((item) => !item.isPaid).length;
    final unpaidRent = snapshot.rents.where((item) => !item.isPaid).length;
    final pendingLoans = snapshot.loans.where((item) => !item.isPaid).length;

    final hasPaymentAlerts =
        unpaidBills > 0 || unpaidRent > 0 || pendingLoans > 0;

    return _PanelCard(
      title: 'Smart Alerts',
      icon: Icons.notifications_active_outlined,
      children: [
        if (!hasPaymentAlerts)
          const _EmptyMiniState(
            icon: Icons.check_circle_outline,
            title: 'No pending payment alerts',
            subtitle: 'Pending bills, rent, and loans will appear here.',
          )
        else ...[
          _InfoRow(
            title: 'Unpaid Bills',
            subtitle: '$unpaidBills bills need attention',
            amount: currency.formatAmount(snapshot.unpaidBills),
            color: const Color(0xFFDC2626),
          ),
          _InfoRow(
            title: 'Unpaid Rent',
            subtitle: '$unpaidRent rent records pending',
            amount: currency.formatAmount(snapshot.pendingRent),
            color: const Color(0xFFF59E0B),
          ),
          _InfoRow(
            title: 'Pending Loans',
            subtitle: '$pendingLoans loan records pending',
            amount: currency.formatAmount(snapshot.pendingLoans),
            color: const Color(0xFF7C3AED),
          ),
        ],
      ],
    );
  }
}

class _UpcomingRemindersCard extends StatelessWidget {
  const _UpcomingRemindersCard({
    required this.reminder,
    required this.upcomingAlerts,
  });

  final ReminderProvider reminder;
  final List<ReminderAlert> upcomingAlerts;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Upcoming Reminders',
      icon: Icons.event_available_outlined,
      children: [
        if (upcomingAlerts.isEmpty)
          const _EmptyMiniState(
            icon: Icons.notifications_none_outlined,
            title: 'No upcoming reminders',
            subtitle:
                'Upcoming bills, rent, and loan reminders will appear here based on your reminder settings.',
          )
        else
          ...upcomingAlerts.map(
            (alert) => _UpcomingReminderRow(alert: alert),
          ),
        const SizedBox(height: 4),
        _ReminderChannelNote(reminder: reminder),
      ],
    );
  }
}

class _ReminderRulesCard extends StatelessWidget {
  const _ReminderRulesCard({
    required this.reminder,
  });

  final ReminderProvider reminder;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Reminder Rules',
      icon: Icons.rule_folder_outlined,
      children: [
        if (reminder.billRemindersEnabled) ...[
          _ReminderRuleRow(
            icon: Icons.wifi_outlined,
            title: 'Internet Bill',
            subtitle:
                'Due day ${reminder.internetBillDay} every month • ${reminder.remindBeforeDays} days before',
            color: const Color(0xFF2563EB),
          ),
          _ReminderRuleRow(
            icon: Icons.school_outlined,
            title: 'School Fees',
            subtitle:
                'Due day ${reminder.schoolFeesDay} every month • ${reminder.remindBeforeDays} days before',
            color: const Color(0xFF16A34A),
          ),
          _ReminderRuleRow(
            icon: Icons.electric_bolt_outlined,
            title: 'Electricity Bill',
            subtitle:
                'Due day ${reminder.electricityBillDay} every month • ${reminder.remindBeforeDays} days before',
            color: const Color(0xFFF59E0B),
          ),
        ],
        if (reminder.rentRemindersEnabled)
          _ReminderRuleRow(
            icon: Icons.home_work_outlined,
            title: 'Rent Collection',
            subtitle:
                'Reminder from day ${reminder.rentReminderStartDay} to ${reminder.rentReminderEndDay} every month',
            color: const Color(0xFF7C3AED),
          ),
        if (reminder.loanRemindersEnabled)
          _ReminderRuleRow(
            icon: Icons.handshake_outlined,
            title: 'Loan Reminders',
            subtitle:
                'Reminder ${reminder.remindBeforeDays} days before selected loan date',
            color: const Color(0xFFEF4444),
          ),
      ],
    );
  }
}

class _ReminderChannelNote extends StatelessWidget {
  const _ReminderChannelNote({
    required this.reminder,
  });

  final ReminderProvider reminder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
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
            color: Color(0xFF2563EB),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Reminder channel: ${reminder.reminderChannel}. Email/SMS will require backend integration.',
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

class _UpcomingReminderRow extends StatelessWidget {
  const _UpcomingReminderRow({
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
    final badge = alert.daysLeft == 0 ? 'Today' : '${alert.daysLeft}d left';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 19),
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
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  alert.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
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

class _ReminderRuleRow extends StatelessWidget {
  const _ReminderRuleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    required this.currency,
    required this.snapshot,
  });

  final CurrencyProvider currency;
  final DashboardSnapshot snapshot;

  String readableDate(String value) {
    final parsed = DateTime.tryParse(value);

    if (parsed == null) return value;

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

    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    final recentExpense =
        snapshot.expenses.isNotEmpty ? snapshot.expenses.first : null;
    final recentIncome =
        snapshot.incomes.isNotEmpty ? snapshot.incomes.first : null;
    final recentBill = snapshot.bills.isNotEmpty ? snapshot.bills.first : null;

    return _PanelCard(
      title: 'Recent Activity',
      icon: Icons.history_outlined,
      children: [
        if (recentExpense != null)
          _InfoRow(
            title: recentExpense.title,
            subtitle:
                '${recentExpense.category} - ${readableDate(recentExpense.date)}',
            amount: '- ${currency.formatAmount(recentExpense.amount)}',
            color: const Color(0xFFDC2626),
          ),
        if (recentIncome != null)
          _InfoRow(
            title: recentIncome.title,
            subtitle:
                '${recentIncome.category} - ${readableDate(recentIncome.date)}',
            amount: '+ ${currency.formatAmount(recentIncome.amount)}',
            color: const Color(0xFF16A34A),
          ),
        if (recentBill != null)
          _InfoRow(
            title: recentBill.title,
            subtitle:
                '${recentBill.category} - ${recentBill.status} - ${readableDate(recentBill.dueDate)}',
            amount: currency.formatAmount(recentBill.amount),
            color: const Color(0xFF2563EB),
          ),
        if (recentExpense == null && recentIncome == null && recentBill == null)
          const _EmptyMiniState(
            icon: Icons.history_outlined,
            title: 'No activity',
            subtitle: 'Latest records will appear here.',
          ),
      ],
    );
  }
}

class _PerformanceSection extends StatelessWidget {
  const _PerformanceSection({
    required this.snapshot,
  });

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Financial Performance',
      icon: Icons.analytics_outlined,
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
      ],
    );
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

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.title,
    required this.icon,
    this.children = const [],
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

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
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 8, backgroundColor: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
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

class _EmptyMiniState extends StatelessWidget {
  const _EmptyMiniState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 34),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}