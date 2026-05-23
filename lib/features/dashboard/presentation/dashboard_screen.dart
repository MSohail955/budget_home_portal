import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
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
    final totalCommitments = unpaidBills + pendingRent + pendingLoans;
    final netBalance = totalInflow - totalExpenses;

    final savingsRate =
        totalInflow == 0 ? 0.0 : (netBalance / totalInflow) * 100;

    final expenseRate =
        totalInflow == 0 ? 0.0 : (totalExpenses / totalInflow) * 100;

    final commitmentRate =
        totalInflow == 0 ? 0.0 : (totalCommitments / totalInflow) * 100;

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
      totalCommitments: totalCommitments,
      netBalance: netBalance,
      savingsRate: savingsRate,
      expenseRate: expenseRate,
      commitmentRate: commitmentRate,
    );
  }

  Future<void> quickLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFFEE2E2),
                child: Icon(
                  Icons.logout,
                  color: Color(0xFFDC2626),
                ),
              ),
              SizedBox(width: 12),
              Text('Logout'),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout from Budget Home?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    await context.read<AuthProvider>().logout();

    if (!context.mounted) return;

    context.go('/login');
  }

  void openDashboardSearch(BuildContext context) {
    final searchController = TextEditingController();
    String query = '';

    final actions = [
      _DashboardSearchAction(
        title: 'Add Income',
        subtitle: 'Create or manage salary, business and income records.',
        icon: Icons.trending_up_outlined,
        color: const Color(0xFF16A34A),
        section: RecordSection.income,
        keywords: 'income salary business earning received money add income',
      ),
      _DashboardSearchAction(
        title: 'Add Expense',
        subtitle: 'Create or manage groceries, shopping and expense records.',
        icon: Icons.shopping_bag_outlined,
        color: const Color(0xFFDC2626),
        section: RecordSection.expenses,
        keywords:
            'expense expenses spending grocery shopping cost payment add expense',
      ),
      _DashboardSearchAction(
        title: 'Track Bills',
        subtitle: 'Manage electricity, internet, water and unpaid bills.',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF2563EB),
        section: RecordSection.bills,
        keywords: 'bill bills electricity internet water due unpaid reminder',
      ),
      _DashboardSearchAction(
        title: 'Track Rent',
        subtitle: 'Manage rent collection, tenants and property payments.',
        icon: Icons.home_work_outlined,
        color: const Color(0xFF7C3AED),
        section: RecordSection.rent,
        keywords: 'rent tenant property collection home pending rent',
      ),
      _DashboardSearchAction(
        title: 'Track Loans',
        subtitle: 'Manage loans taken, given, pending and paid.',
        icon: Icons.handshake_outlined,
        color: const Color(0xFFF59E0B),
        section: RecordSection.loans,
        keywords: 'loan loans borrowed given taken pending paid personal',
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredActions = actions.where((item) {
              final value = query.trim().toLowerCase();

              if (value.isEmpty) return true;

              return item.title.toLowerCase().contains(value) ||
                  item.subtitle.toLowerCase().contains(value) ||
                  item.keywords.toLowerCase().contains(value);
            }).toList();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2563EB),
                                  Color(0xFF7C3AED),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.search,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Search Budget Home',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Search and jump directly to the feature you need.',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: searchController,
                        autofocus: true,
                        onChanged: (value) {
                          setSheetState(() {
                            query = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search income, bills, rent, loans...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    searchController.clear();
                                    setSheetState(() {
                                      query = '';
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Flexible(
                        child: filteredActions.isEmpty
                            ? const _SearchEmptyState()
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filteredActions.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final item = filteredActions[index];

                                  return Material(
                                    color: item.color.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(22),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(22),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        onOpenRecordSection?.call(item.section);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(15),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 24,
                                              backgroundColor:
                                                  item.color.withOpacity(0.14),
                                              child: Icon(
                                                item.icon,
                                                color: item.color,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.title,
                                                    style: const TextStyle(
                                                      color: Color(0xFF0F172A),
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    item.subtitle,
                                                    style: const TextStyle(
                                                      color: Color(0xFF64748B),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 15,
                                              color: item.color,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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

    final pendingRentCount = snapshot.rents.where((item) => !item.isPaid).length;

    final pendingLoansCount =
        snapshot.loans.where((item) => !item.isPaid).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnimatedEntry(
                    delay: 0,
                    child: _DashboardTopBar(
                      onSearchTap: () => openDashboardSearch(context),
                      onLogoutTap: () => quickLogout(context),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _AnimatedEntry(
                    delay: 60,
                    child: _PremiumHeader(
                      selectedMonth: snapshot.selectedMonth,
                      selectedYear: snapshot.selectedYear,
                      snapshot: snapshot,
                      currency: currency,
                      upcomingCount: upcomingAlerts.length,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _AnimatedEntry(
                    delay: 120,
                    child: _DashboardFilterCard(),
                  ),
                  const SizedBox(height: 22),
                  if (!hasAnyRecords) ...[
                    _AnimatedEntry(
                      delay: 140,
                      child: _NewUserEmptyState(
                        onOpenRecordSection: onOpenRecordSection,
                      ),
                    ),
                    const SizedBox(height: 22),
                  ] else if (!hasFilteredRecords) ...[
                    _AnimatedEntry(
                      delay: 140,
                      child: _FilteredEmptyState(
                        monthLabel:
                            '${snapshot.selectedMonth} ${snapshot.selectedYear}',
                        onOpenRecordSection: onOpenRecordSection,
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  _AnimatedEntry(
                    delay: 180,
                    child: _ReminderBadgeGrid(
                      isWide: isWide,
                      upcomingReminders: upcomingAlerts.length,
                      pendingBills: pendingBillsCount,
                      pendingRent: pendingRentCount,
                      pendingLoans: pendingLoansCount,
                      onOpenRecordSection: onOpenRecordSection,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _AnimatedEntry(
                    delay: 240,
                    child: _PremiumSummaryGrid(
                      isWide: isWide,
                      currency: currency,
                      snapshot: snapshot,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _AnimatedEntry(
                    delay: 300,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 920) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _CashFlowCard(
                                  currency: currency,
                                  snapshot: snapshot,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 4,
                                child: _AlertsCard(
                                  currency: currency,
                                  snapshot: snapshot,
                                ),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            _CashFlowCard(
                              currency: currency,
                              snapshot: snapshot,
                            ),
                            const SizedBox(height: 16),
                            _AlertsCard(
                              currency: currency,
                              snapshot: snapshot,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  _AnimatedEntry(
                    delay: 360,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 920) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _UpcomingRemindersCard(
                                  reminder: reminder,
                                  upcomingAlerts: upcomingAlerts,
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
                            _UpcomingRemindersCard(
                              reminder: reminder,
                              upcomingAlerts: upcomingAlerts,
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
                  ),
                  const SizedBox(height: 22),
                  _AnimatedEntry(
                    delay: 420,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 920) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _PerformanceSection(snapshot: snapshot),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _ReminderRulesCard(reminder: reminder),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            _PerformanceSection(snapshot: snapshot),
                            const SizedBox(height: 16),
                            _ReminderRulesCard(reminder: reminder),
                          ],
                        );
                      },
                    ),
                  ),
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
    required this.totalCommitments,
    required this.netBalance,
    required this.savingsRate,
    required this.expenseRate,
    required this.commitmentRate,
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
  final double totalCommitments;
  final double netBalance;
  final double savingsRate;
  final double expenseRate;
  final double commitmentRate;
}

class _DashboardSearchAction {
  const _DashboardSearchAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.section,
    required this.keywords,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final RecordSection section;
  final String keywords;
}

class _AnimatedEntry extends StatelessWidget {
  const _AnimatedEntry({required this.child, required this.delay});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 520 + delay),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}


class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar({
    required this.onSearchTap,
    required this.onLogoutTap,
  });

  final VoidCallback onSearchTap;
  final VoidCallback onLogoutTap;

  void _openProfileDetails(BuildContext context) {
    final profile = context.read<ProfileProvider>();
    final name = profile.name.trim().isEmpty ? 'User' : profile.name.trim();
    final email = profile.email.trim().isEmpty
        ? 'No email added'
        : profile.email.trim();
    final phone = profile.phone.trim().isEmpty
        ? 'No phone added'
        : profile.phone.trim();
    final address = profile.address.trim().isEmpty
        ? 'No address added'
        : profile.address.trim();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(32),
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF2563EB),
                                Color(0xFF7C3AED),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB)
                                    .withOpacity(0.22),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Account Profile',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _ProfileDetailRow(
                            icon: Icons.person_outline,
                            label: 'Full Name',
                            value: name,
                          ),
                          _ProfileDetailRow(
                            icon: Icons.email_outlined,
                            label: 'Email Address',
                            value: email,
                          ),
                          _ProfileDetailRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone Number',
                            value: phone,
                          ),
                          _ProfileDetailRow(
                            icon: Icons.location_on_outlined,
                            label: 'Address',
                            value: address,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF2563EB),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'To update your profile details, open Settings and edit your profile information.',
                              style: TextStyle(
                                color: Color(0xFF1E3A8A),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 520;

                        final editButton = OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Open Settings → Profile to edit details.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit in Settings'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        );

                        final logoutButton = ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            onLogoutTap();
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        );

                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(child: editButton),
                              const SizedBox(width: 12),
                              Expanded(child: logoutButton),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            SizedBox(width: double.infinity, child: editButton),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: logoutButton,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final name = profile.name.trim().isEmpty ? 'User' : profile.name.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 850;

          final logo = const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Color(0x22FFFFFF),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Budget Home',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          );

          final search = _TopSearchBox(onTap: onSearchTap);

          final userArea = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProfileAvatarButton(
                onTap: () => _openProfileDetails(context),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _TopLogoutButton(onTap: onLogoutTap),
            ],
          );

          if (isWide) {
            return Row(
              children: [
                logo,
                const Spacer(),
                SizedBox(
                  width: 360,
                  child: search,
                ),
                const SizedBox(width: 18),
                userArea,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              logo,
              const SizedBox(height: 14),
              search,
              const SizedBox(height: 14),
              userArea,
            ],
          );
        },
      ),
    );
  }
}

class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final name = profile.name.trim().isEmpty ? 'User' : profile.name.trim();
    final initial = name.substring(0, 1).toUpperCase();

    return Tooltip(
      message: 'View profile details',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF7C3AED),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFEFF6FF),
            child: Icon(
              icon,
              color: const Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
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

class _TopSearchBox extends StatelessWidget {
  const _TopSearchBox({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white70),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search for transactions, reports...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopLogoutButton extends StatelessWidget {
  const _TopLogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF7F1D1D).withOpacity(0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFCA5A5).withOpacity(0.30)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout, color: Color(0xFFFCA5A5), size: 18),
              SizedBox(width: 7),
              Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFFFCA5A5),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumHeader extends StatelessWidget {
  const _PremiumHeader({
    required this.selectedMonth,
    required this.selectedYear,
    required this.snapshot,
    required this.currency,
    required this.upcomingCount,
  });

  final String selectedMonth;
  final String selectedYear;
  final DashboardSnapshot snapshot;
  final CurrencyProvider currency;
  final int upcomingCount;

  String get filterLabel {
    if (selectedMonth == 'All' && selectedYear == 'All') return 'All Time';
    if (selectedMonth == 'All') return selectedYear;
    if (selectedYear == 'All') return selectedMonth;
    return '$selectedMonth $selectedYear';
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final displayName =
        profile.name.trim().isEmpty ? 'User' : profile.name.trim();

    final balancePositive = snapshot.netBalance >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF7C3AED),
            Color(0xFF06B6D4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.22),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0F172A),
              Color(0xFF111827),
              Color(0xFF082F49),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(34),
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -80,
              top: -90,
              child: _GlowCircle(size: 240, color: Color(0xFF38BDF8)),
            ),
            const Positioned(
              left: -90,
              bottom: -120,
              child: _GlowCircle(size: 240, color: Color(0xFF8B5CF6)),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 820;

                final leftContent = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          icon: Icons.notifications_active_outlined,
                          label: '$upcomingCount Alerts',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(0x22FFFFFF),
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Budget Home',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Welcome back, $displayName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your premium home finance command center is ready.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _NetBalanceDisplay(
                      value: currency.formatAmount(snapshot.netBalance),
                      isPositive: balancePositive,
                    ),
                  ],
                );

                final rightContent = _HeaderInsightCard(
                  currency: currency,
                  snapshot: snapshot,
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 6, child: leftContent),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: rightContent),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leftContent,
                    const SizedBox(height: 22),
                    rightContent,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderQuickButton extends StatelessWidget {
  const _HeaderQuickButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
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

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.14),
        ),
      ),
    );
  }
}

class _NetBalanceDisplay extends StatelessWidget {
  const _NetBalanceDisplay({
    required this.value,
    required this.isPositive,
  });

  final String value;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final color =
        isPositive ? const Color(0xFF22C55E) : const Color(0xFFF87171);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.11),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.18),
            child: Icon(
              isPositive
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Net Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderInsightCard extends StatelessWidget {
  const _HeaderInsightCard({
    required this.currency,
    required this.snapshot,
  });

  final CurrencyProvider currency;
  final DashboardSnapshot snapshot;

  String insightText() {
    if (snapshot.totalInflow == 0 && snapshot.totalExpenses == 0) {
      return 'Add your first income, bill, rent, expense, or loan record to unlock insights.';
    }

    if (snapshot.netBalance < 0) {
      return 'Expenses are higher than inflow. Review spending and pending payments.';
    }

    if (snapshot.savingsRate >= 50) {
      return 'Excellent month. Your saving health is very strong.';
    }

    if (snapshot.totalCommitments > 0) {
      return 'You have pending commitments. Clear bills, rent, and loans before due dates.';
    }

    return 'Your finance position looks stable for this selected period.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0x22FFFFFF),
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Smart Insight',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            insightText(),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          _HeaderMiniMetric(
            label: 'Total Inflow',
            value: currency.formatAmount(snapshot.totalInflow),
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 10),
          _HeaderMiniMetric(
            label: 'Pending Commitments',
            value: currency.formatAmount(snapshot.totalCommitments),
            icon: Icons.pending_actions_outlined,
          ),
        ],
      ),
    );
  }
}

class _HeaderMiniMetric extends StatelessWidget {
  const _HeaderMiniMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
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
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
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

class _DashboardFilterCard extends StatelessWidget {
  const _DashboardFilterCard();

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<DashboardFilterProvider>();

    return _GlassCard(
      padding: const EdgeInsets.all(18),
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
                'View premium analytics by month and year.',
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
        borderRadius: BorderRadius.circular(18),
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
    return _PremiumChipButton(
      icon: Icons.restart_alt,
      label: 'Reset',
      color: const Color(0xFFF97316),
      onTap: onTap,
    );
  }
}

class _PremiumChipButton extends StatelessWidget {
  const _PremiumChipButton({
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
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

class _PremiumSummaryGrid extends StatelessWidget {
  const _PremiumSummaryGrid({
    required this.isWide,
    required this.currency,
    required this.snapshot,
  });

  final bool isWide;
  final CurrencyProvider currency;
  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryCard(
        title: 'Month Income',
        value: currency.formatAmount(snapshot.totalIncome),
        icon: Icons.trending_up,
        color: const Color(0xFF16A34A),
        progress: snapshot.totalInflow == 0
            ? 0
            : snapshot.totalIncome / snapshot.totalInflow,
        subtitle: 'Primary inflow',
      ),
      _SummaryCard(
        title: 'Month Expenses',
        value: currency.formatAmount(snapshot.totalExpenses),
        icon: Icons.trending_down,
        color: const Color(0xFFDC2626),
        progress: snapshot.expenseRate / 100,
        subtitle: '${snapshot.expenseRate.toStringAsFixed(1)}% of inflow',
      ),
      _SummaryCard(
        title: 'Rent Collected',
        value: currency.formatAmount(snapshot.rentCollected),
        icon: Icons.home_work_outlined,
        color: const Color(0xFF7C3AED),
        progress: snapshot.totalInflow == 0
            ? 0
            : snapshot.rentCollected / snapshot.totalInflow,
        subtitle: 'Rental inflow',
      ),
      _SummaryCard(
        title: 'Net Balance',
        value: currency.formatAmount(snapshot.netBalance),
        icon: Icons.account_balance_wallet_outlined,
        color: snapshot.netBalance >= 0
            ? const Color(0xFF2563EB)
            : const Color(0xFFDC2626),
        progress: (snapshot.savingsRate / 100).clamp(0.0, 1.0),
        subtitle: '${snapshot.savingsRate.toStringAsFixed(1)}% savings',
      ),
    ];

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.progress,
    required this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double progress;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _HoverScale(
      child: Container(
        constraints: const BoxConstraints(minHeight: 176),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color),
                ),
                const Spacer(),
                Icon(
                  Icons.auto_graph_outlined,
                  color: color.withOpacity(0.65),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 22),
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
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _AnimatedLinearMeter(
              value: progress.clamp(0.0, 1.0),
              color: color,
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedLinearMeter extends StatelessWidget {
  const _AnimatedLinearMeter({
    required this.value,
    required this.color,
  });

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: animatedValue,
            minHeight: 8,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      },
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

    return _HoverScale(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Ink(
            height: 118,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasCount ? color.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: hasCount
                    ? color.withOpacity(0.22)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: hasCount
                      ? color.withOpacity(0.10)
                      : Colors.black.withOpacity(0.035),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
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
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: count.toDouble()),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Text(
                            value.round().toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          );
                        },
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
      ),
    );
  }
}

class _CashFlowCard extends StatelessWidget {
  const _CashFlowCard({
    required this.currency,
    required this.snapshot,
  });

  final CurrencyProvider currency;
  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final maxValue = [
      snapshot.totalInflow,
      snapshot.totalExpenses,
      snapshot.totalCommitments,
      1.0,
    ].reduce(math.max);

    return _PanelCard(
      title: 'Cash Flow Overview',
      icon: Icons.insights_outlined,
      child: Column(
        children: [
          _BarMetric(
            title: 'Total Inflow',
            value: snapshot.totalInflow,
            maxValue: maxValue,
            formatted: currency.formatAmount(snapshot.totalInflow),
            color: const Color(0xFF16A34A),
            icon: Icons.arrow_downward_rounded,
          ),
          const SizedBox(height: 16),
          _BarMetric(
            title: 'Total Expenses',
            value: snapshot.totalExpenses,
            maxValue: maxValue,
            formatted: currency.formatAmount(snapshot.totalExpenses),
            color: const Color(0xFFDC2626),
            icon: Icons.arrow_upward_rounded,
          ),
          const SizedBox(height: 16),
          _BarMetric(
            title: 'Pending Commitments',
            value: snapshot.totalCommitments,
            maxValue: maxValue,
            formatted: currency.formatAmount(snapshot.totalCommitments),
            color: const Color(0xFFF59E0B),
            icon: Icons.pending_actions_outlined,
          ),
        ],
      ),
    );
  }
}

class _BarMetric extends StatelessWidget {
  const _BarMetric({
    required this.title,
    required this.value,
    required this.maxValue,
    required this.formatted,
    required this.color,
    required this.icon,
  });

  final String title;
  final double value;
  final double maxValue;
  final String formatted;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final progress = maxValue == 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);

    return Row(
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
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
                    formatted,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              _AnimatedLinearMeter(value: progress, color: color),
            ],
          ),
        ),
      ],
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
      child: Column(
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
      ),
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
      child: Column(
        children: [
          if (upcomingAlerts.isEmpty)
            const _EmptyMiniState(
              icon: Icons.notifications_none_outlined,
              title: 'No upcoming reminders',
              subtitle:
                  'Upcoming bills, rent, and loan reminders will appear here.',
            )
          else
            ...upcomingAlerts
                .take(5)
                .map((alert) => _UpcomingReminderRow(alert: alert)),
          const SizedBox(height: 4),
          _ReminderChannelNote(reminder: reminder),
        ],
      ),
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
      child: Column(
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
      ),
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
      child: Column(
        children: [
          if (recentExpense != null)
            _InfoRow(
              title: recentExpense.title,
              subtitle:
                  '${recentExpense.category} • ${readableDate(recentExpense.date)}',
              amount: '- ${currency.formatAmount(recentExpense.amount)}',
              color: const Color(0xFFDC2626),
            ),
          if (recentIncome != null)
            _InfoRow(
              title: recentIncome.title,
              subtitle:
                  '${recentIncome.category} • ${readableDate(recentIncome.date)}',
              amount: '+ ${currency.formatAmount(recentIncome.amount)}',
              color: const Color(0xFF16A34A),
            ),
          if (recentBill != null)
            _InfoRow(
              title: recentBill.title,
              subtitle:
                  '${recentBill.category} • ${recentBill.status} • ${readableDate(recentBill.dueDate)}',
              amount: currency.formatAmount(recentBill.amount),
              color: const Color(0xFF2563EB),
            ),
          if (recentExpense == null &&
              recentIncome == null &&
              recentBill == null)
            const _EmptyMiniState(
              icon: Icons.history_outlined,
              title: 'No activity',
              subtitle: 'Latest records will appear here.',
            ),
        ],
      ),
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
          _ProgressRow(
            title: 'Commitment Rate',
            value: snapshot.commitmentRate,
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
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
        _AnimatedLinearMeter(value: progress, color: color),
      ],
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
    return _GlassCard(
      padding: const EdgeInsets.all(22),
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
                onTap: () =>
                    onOpenRecordSection?.call(RecordSection.expenses),
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
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
      backgroundColor: color.withOpacity(0.10),
      side: BorderSide(color: color.withOpacity(0.20)),
      onPressed: onTap,
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
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF2563EB).withOpacity(0.10),
                child: Icon(
                  icon,
                  color: const Color(0xFF2563EB),
                  size: 20,
                ),
              ),
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

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    required this.padding,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.055),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
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

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              color: Color(0xFF94A3B8),
              size: 42,
            ),
            SizedBox(height: 10),
            Text(
              'No matching feature found',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverScale extends StatefulWidget {
  const _HoverScale({
    required this.child,
  });

  final Widget child;

  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          isHovered = false;
        });
      },
      child: AnimatedScale(
        scale: isHovered ? 1.018 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, isHovered ? -2 : 0, 0),
          child: widget.child,
        ),
      ),
    );
  }
}
