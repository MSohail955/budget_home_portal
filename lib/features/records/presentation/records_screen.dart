import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/currency_provider.dart';
import '../../../core/providers/finance_provider.dart';
import '../../bills/presentation/bills_screen.dart';
import '../../expenses/presentation/expenses_screen.dart';
import '../../income/presentation/income_screen.dart';
import '../../loans/presentation/loans_screen.dart';
import '../../rent/presentation/rent_screen.dart';

enum RecordSection {
  expenses,
  income,
  rent,
  bills,
  loans,
}

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({
    super.key,
  });

  @override
  State<RecordsScreen> createState() => RecordsScreenState();
}

class RecordsScreenState extends State<RecordsScreen> {
  late final List<_RecordItem> items;

  @override
  void initState() {
    super.initState();

    items = [
      _RecordItem(
        section: RecordSection.expenses,
        title: 'Expenses',
        subtitle: 'Track groceries, bills, school fees and home costs.',
        icon: Icons.payments_outlined,
        color: Color(0xFFDC2626),
        pageBuilder: (openAddForm) => ExpensesScreen(openAddForm: openAddForm),
      ),
      _RecordItem(
        section: RecordSection.income,
        title: 'Income',
        subtitle: 'Manage salary, business, rent, freelance and gifts.',
        icon: Icons.trending_up_outlined,
        color: Color(0xFF16A34A),
        pageBuilder: (openAddForm) => IncomeScreen(openAddForm: openAddForm),
      ),
      _RecordItem(
        section: RecordSection.rent,
        title: 'Rent',
        subtitle: 'Monitor tenant rent, due dates and payment status.',
        icon: Icons.home_work_outlined,
        color: Color(0xFF7C3AED),
        pageBuilder: (openAddForm) => RentScreen(openAddForm: openAddForm),
      ),
      _RecordItem(
        section: RecordSection.bills,
        title: 'Bills',
        subtitle: 'Handle electricity, internet, water and maintenance.',
        icon: Icons.receipt_long_outlined,
        color: Color(0xFF2563EB),
        pageBuilder: (openAddForm) => BillsScreen(openAddForm: openAddForm),
      ),
      _RecordItem(
        section: RecordSection.loans,
        title: 'Loans',
        subtitle: 'Track loans taken, given, pending and paid.',
        icon: Icons.handshake_outlined,
        color: Color(0xFFF59E0B),
        pageBuilder: (openAddForm) => LoansScreen(openAddForm: openAddForm),
      ),
    ];
  }

  void openSection(
    RecordSection section, {
    bool openAddForm = false,
  }) {
    final selectedItem = items.firstWhere(
      (item) => item.section == section,
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) =>
            selectedItem.pageBuilder(openAddForm),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0.04),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  int countForSection({
    required _RecordItem item,
    required FinanceProvider finance,
  }) {
    switch (item.section) {
      case RecordSection.expenses:
        return finance.expenses.length;
      case RecordSection.income:
        return finance.incomes.length;
      case RecordSection.rent:
        return finance.rents.length;
      case RecordSection.bills:
        return finance.bills.length;
      case RecordSection.loans:
        return finance.loans.length;
    }
  }

  double amountForSection({
    required _RecordItem item,
    required FinanceProvider finance,
  }) {
    switch (item.section) {
      case RecordSection.expenses:
        return finance.totalExpenses;
      case RecordSection.income:
        return finance.totalIncome;
      case RecordSection.rent:
        return finance.pendingRent;
      case RecordSection.bills:
        return finance.unpaidBills;
      case RecordSection.loans:
        return finance.pendingLoans;
    }
  }

  String statusLabelForSection({
    required _RecordItem item,
    required FinanceProvider finance,
  }) {
    switch (item.section) {
      case RecordSection.expenses:
        return 'Total spent';
      case RecordSection.income:
        return 'Total received';
      case RecordSection.rent:
        return finance.pendingRent > 0 ? 'Pending rent' : 'Rent clear';
      case RecordSection.bills:
        return finance.unpaidBills > 0 ? 'Unpaid bills' : 'Bills clear';
      case RecordSection.loans:
        return finance.pendingLoans > 0 ? 'Pending loans' : 'Loans clear';
    }
  }

  String buildMetaText({
    required _RecordItem item,
    required FinanceProvider finance,
    required CurrencyProvider currency,
  }) {
    final count = countForSection(item: item, finance: finance);
    final amount = amountForSection(item: item, finance: finance);
    final label = statusLabelForSection(item: item, finance: finance);

    return '$count records • ${currency.formatAmount(amount)} • $label';
  }

  double calculateProgress({
    required _RecordItem item,
    required FinanceProvider finance,
  }) {
    final amounts = [
      finance.totalExpenses,
      finance.totalIncome,
      finance.pendingRent,
      finance.unpaidBills,
      finance.pendingLoans,
      1.0,
    ];

    final maxValue = amounts.reduce(math.max);
    final value = amountForSection(item: item, finance: finance);

    if (maxValue <= 0) return 0;

    return (value / maxValue).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;
    final isTablet = width > 650;
    final finance = context.watch<FinanceProvider>();
    final currency = context.watch<CurrencyProvider>();

    final totalRecords = finance.expenses.length +
        finance.incomes.length +
        finance.rents.length +
        finance.bills.length +
        finance.loans.length;

    final totalManagedAmount = finance.totalExpenses +
        finance.totalIncome +
        finance.totalRent +
        finance.totalBills +
        finance.totalLoans;

    final pendingAmount =
        finance.unpaidBills + finance.pendingRent + finance.pendingLoans;

    final sectionsWithData = items
        .where(
          (item) => countForSection(item: item, finance: finance) > 0,
        )
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnimatedEntry(
                    delay: 0,
                    child: _PremiumRecordsHeader(
                      totalRecords: totalRecords,
                      totalAmount: currency.formatAmount(totalManagedAmount),
                      pendingAmount: currency.formatAmount(pendingAmount),
                      sectionsWithData: sectionsWithData,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _AnimatedEntry(
                    delay: 90,
                    child: _QuickOverviewStrip(
                      currency: currency,
                      finance: finance,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _AnimatedEntry(
                    delay: 160,
                    child: _RecordCommandCard(
                      onOpenSection: openSection,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _AnimatedEntry(
                    delay: 230,
                    child: _SectionTitleRow(
                      title: 'Record Modules',
                      subtitle:
                          'Open any module to add, edit, filter, and manage records.',
                      totalRecords: totalRecords,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide
                          ? 2
                          : isTablet
                              ? 2
                              : 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isWide
                          ? 2.08
                          : isTablet
                              ? 1.72
                              : 2.2,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return _AnimatedEntry(
                        delay: 280 + (index * 70),
                        child: _PremiumRecordCard(
                          item: item,
                          count: countForSection(
                            item: item,
                            finance: finance,
                          ),
                          meta: buildMetaText(
                            item: item,
                            finance: finance,
                            currency: currency,
                          ),
                          amount: currency.formatAmount(
                            amountForSection(
                              item: item,
                              finance: finance,
                            ),
                          ),
                          statusLabel: statusLabelForSection(
                            item: item,
                            finance: finance,
                          ),
                          progress: calculateProgress(
                            item: item,
                            finance: finance,
                          ),
                          onTap: () => openSection(item.section),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  _AnimatedEntry(
                    delay: 700,
                    child: _RecordsInsightPanel(
                      currency: currency,
                      finance: finance,
                    ),
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

class _RecordItem {
  const _RecordItem({
    required this.section,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.pageBuilder,
  });

  final RecordSection section;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget Function(bool openAddForm) pageBuilder;
}

class _AnimatedEntry extends StatelessWidget {
  const _AnimatedEntry({
    required this.child,
    required this.delay,
  });

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
            offset: Offset(0, 22 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _PremiumRecordsHeader extends StatelessWidget {
  const _PremiumRecordsHeader({
    required this.totalRecords,
    required this.totalAmount,
    required this.pendingAmount,
    required this.sectionsWithData,
  });

  final int totalRecords;
  final String totalAmount;
  final String pendingAmount;
  final int sectionsWithData;

  @override
  Widget build(BuildContext context) {
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
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.22),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.92),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -80,
              top: -90,
              child: _GlowCircle(
                size: 220,
                color: Color(0xFF38BDF8),
              ),
            ),
            const Positioned(
              left: -90,
              bottom: -110,
              child: _GlowCircle(
                size: 230,
                color: Color(0xFF8B5CF6),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 820;

                final titleBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _HeaderPill(
                          icon: Icons.folder_copy_outlined,
                          label: '$totalRecords Records',
                        ),
                        _HeaderPill(
                          icon: Icons.dashboard_customize_outlined,
                          label: '$sectionsWithData Active Modules',
                        ),
                        const _HeaderPill(
                          icon: Icons.auto_awesome,
                          label: 'Premium Workspace',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Records Center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Manage expenses, income, rent, bills, and loans from one premium workspace.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                );

                final metricBlock = _HeaderMetricPanel(
                  totalAmount: totalAmount,
                  pendingAmount: pendingAmount,
                  totalRecords: totalRecords,
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(flex: 6, child: titleBlock),
                      const SizedBox(width: 22),
                      Expanded(flex: 4, child: metricBlock),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: 20),
                    metricBlock,
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

class _HeaderMetricPanel extends StatelessWidget {
  const _HeaderMetricPanel({
    required this.totalAmount,
    required this.pendingAmount,
    required this.totalRecords,
  });

  final String totalAmount;
  final String pendingAmount;
  final int totalRecords;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
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
                  Icons.analytics_outlined,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Records Summary',
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
          _HeaderMiniMetric(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Total Managed',
            value: totalAmount,
          ),
          const SizedBox(height: 10),
          _HeaderMiniMetric(
            icon: Icons.pending_actions_outlined,
            label: 'Pending Amount',
            value: pendingAmount,
          ),
          const SizedBox(height: 10),
          _HeaderMiniMetric(
            icon: Icons.storage_outlined,
            label: 'Saved Records',
            value: totalRecords.toString(),
          ),
        ],
      ),
    );
  }
}

class _QuickOverviewStrip extends StatelessWidget {
  const _QuickOverviewStrip({
    required this.currency,
    required this.finance,
  });

  final CurrencyProvider currency;
  final FinanceProvider finance;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _OverviewChip(
        icon: Icons.trending_up,
        label: 'Income',
        value: currency.formatAmount(finance.totalIncome),
        color: const Color(0xFF16A34A),
      ),
      _OverviewChip(
        icon: Icons.trending_down,
        label: 'Expenses',
        value: currency.formatAmount(finance.totalExpenses),
        color: const Color(0xFFDC2626),
      ),
      _OverviewChip(
        icon: Icons.receipt_long_outlined,
        label: 'Unpaid Bills',
        value: currency.formatAmount(finance.unpaidBills),
        color: const Color(0xFF2563EB),
      ),
      _OverviewChip(
        icon: Icons.home_work_outlined,
        label: 'Pending Rent',
        value: currency.formatAmount(finance.pendingRent),
        color: const Color(0xFF7C3AED),
      ),
      _OverviewChip(
        icon: Icons.handshake_outlined,
        label: 'Pending Loans',
        value: currency.formatAmount(finance.pendingLoans),
        color: const Color(0xFFF59E0B),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int index = 0; index < cards.length; index++) ...[
            cards[index],
            if (index != cards.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _OverviewChip extends StatelessWidget {
  const _OverviewChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _HoverScale(
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.07),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordCommandCard extends StatelessWidget {
  const _RecordCommandCard({
    required this.onOpenSection,
  });

  final void Function(RecordSection section, {bool openAddForm}) onOpenSection;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 760;

          final intro = const Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(
                  Icons.add_task_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Jump directly into the record type you want to manage.',
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

          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _QuickActionPill(
                icon: Icons.trending_up_outlined,
                label: 'Add Income',
                color: const Color(0xFF16A34A),
                onTap: () => onOpenSection(RecordSection.income, openAddForm: true),
              ),
              _QuickActionPill(
                icon: Icons.shopping_bag_outlined,
                label: 'Add Expense',
                color: const Color(0xFFDC2626),
                onTap: () => onOpenSection(RecordSection.expenses, openAddForm: true),
              ),
              _QuickActionPill(
                icon: Icons.receipt_long_outlined,
                label: 'Track Bills',
                color: const Color(0xFF2563EB),
                onTap: () => onOpenSection(RecordSection.bills, openAddForm: true),
              ),
              _QuickActionPill(
                icon: Icons.home_work_outlined,
                label: 'Track Rent',
                color: const Color(0xFF7C3AED),
                onTap: () => onOpenSection(RecordSection.rent, openAddForm: true),
              ),
              _QuickActionPill(
                icon: Icons.handshake_outlined,
                label: 'Track Loans',
                color: const Color(0xFFF59E0B),
                onTap: () => onOpenSection(RecordSection.loans, openAddForm: true),
              ),
            ],
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: intro),
                const SizedBox(width: 18),
                Flexible(child: actions),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              intro,
              const SizedBox(height: 18),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _QuickActionPill extends StatelessWidget {
  const _QuickActionPill({
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

class _SectionTitleRow extends StatelessWidget {
  const _SectionTitleRow({
    required this.title,
    required this.subtitle,
    required this.totalRecords,
  });

  final String title;
  final String subtitle;
  final int totalRecords;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFEFF6FF),
          child: Icon(
            Icons.grid_view_rounded,
            color: Color(0xFF2563EB),
          ),
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
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            '$totalRecords Total',
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumRecordCard extends StatelessWidget {
  const _PremiumRecordCard({
    required this.item,
    required this.count,
    required this.meta,
    required this.amount,
    required this.statusLabel,
    required this.progress,
    required this.onTap,
  });

  final _RecordItem item;
  final int count;
  final String meta;
  final String amount;
  final String statusLabel;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasRecords = count > 0;

    return _HoverScale(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: hasRecords ? item.color.withOpacity(0.055) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: hasRecords
                    ? item.color.withOpacity(0.18)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: hasRecords
                      ? item.color.withOpacity(0.10)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -26,
                  top: -26,
                  child: _SoftCircle(
                    size: 92,
                    color: item.color,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: item.color.withOpacity(0.12),
                          child: Icon(
                            item.icon,
                            color: item.color,
                            size: 26,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: count.toDouble()),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Text(
                                '${value.round()} Records',
                                style: TextStyle(
                                  color: item.color,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              amount,
                              style: TextStyle(
                                color: item.color,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          statusLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _AnimatedLinearMeter(
                      value: progress,
                      color: item.color,
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: item.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: item.color.withOpacity(0.75),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordsInsightPanel extends StatelessWidget {
  const _RecordsInsightPanel({
    required this.currency,
    required this.finance,
  });

  final CurrencyProvider currency;
  final FinanceProvider finance;

  @override
  Widget build(BuildContext context) {
    final totalPending =
        finance.unpaidBills + finance.pendingRent + finance.pendingLoans;

    final hasPending = totalPending > 0;

    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 760;

          final left = Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: (hasPending
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF16A34A))
                    .withOpacity(0.12),
                child: Icon(
                  hasPending
                      ? Icons.pending_actions_outlined
                      : Icons.verified_outlined,
                  color: hasPending
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPending
                          ? 'Pending items need attention'
                          : 'All clear for now',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasPending
                          ? 'You currently have ${currency.formatAmount(totalPending)} pending across bills, rent, and loans.'
                          : 'No pending bills, rent, or loans are currently affecting this workspace.',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final right = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InsightPill(
                label: 'Bills: ${currency.formatAmount(finance.unpaidBills)}',
                color: const Color(0xFF2563EB),
              ),
              _InsightPill(
                label: 'Rent: ${currency.formatAmount(finance.pendingRent)}',
                color: const Color(0xFF7C3AED),
              ),
              _InsightPill(
                label: 'Loans: ${currency.formatAmount(finance.pendingLoans)}',
                color: const Color(0xFFF59E0B),
              ),
            ],
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: left),
                const SizedBox(width: 18),
                right,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              left,
              const SizedBox(height: 16),
              right,
            ],
          );
        },
      ),
    );
  }
}

class _InsightPill extends StatelessWidget {
  const _InsightPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
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

class _HeaderMiniMetric extends StatelessWidget {
  const _HeaderMiniMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
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

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({
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
          color: color.withOpacity(0.08),
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