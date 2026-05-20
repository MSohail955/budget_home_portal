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

    items = const [
      _RecordItem(
        section: RecordSection.expenses,
        title: 'Expenses',
        subtitle: 'Grocery, bills, school fees and home costs',
        icon: Icons.payments_outlined,
        color: Color(0xFFDC2626),
        page: ExpensesScreen(),
      ),
      _RecordItem(
        section: RecordSection.income,
        title: 'Income',
        subtitle: 'Salary, business, rent, freelance and gifts',
        icon: Icons.trending_up_outlined,
        color: Color(0xFF16A34A),
        page: IncomeScreen(),
      ),
      _RecordItem(
        section: RecordSection.rent,
        title: 'Rent',
        subtitle: 'Tenant rent, due dates and paid/unpaid status',
        icon: Icons.home_work_outlined,
        color: Color(0xFF7C3AED),
        page: RentScreen(),
      ),
      _RecordItem(
        section: RecordSection.bills,
        title: 'Bills',
        subtitle: 'Electricity, internet, water and maintenance',
        icon: Icons.receipt_long_outlined,
        color: Color(0xFF2563EB),
        page: BillsScreen(),
      ),
      _RecordItem(
        section: RecordSection.loans,
        title: 'Loans',
        subtitle: 'Loans taken, given, pending and paid',
        icon: Icons.handshake_outlined,
        color: Color(0xFFF59E0B),
        page: LoansScreen(),
      ),
    ];
  }

  void openSection(RecordSection section) {
    final selectedItem = items.firstWhere(
      (item) => item.section == section,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => selectedItem.page,
      ),
    );
  }

  String buildMetaText({
    required _RecordItem item,
    required FinanceProvider finance,
    required CurrencyProvider currency,
  }) {
    switch (item.section) {
      case RecordSection.expenses:
        return '${finance.expenses.length} records • ${currency.formatAmount(finance.totalExpenses)} spent';

      case RecordSection.income:
        return '${finance.incomes.length} records • ${currency.formatAmount(finance.totalIncome)} received';

      case RecordSection.rent:
        return '${finance.rents.length} records • ${currency.formatAmount(finance.pendingRent)} pending';

      case RecordSection.bills:
        return '${finance.bills.length} records • ${currency.formatAmount(finance.unpaidBills)} unpaid';

      case RecordSection.loans:
        return '${finance.loans.length} records • ${currency.formatAmount(finance.pendingLoans)} pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final finance = context.watch<FinanceProvider>();
    final currency = context.watch<CurrencyProvider>();

    final totalRecords = finance.expenses.length +
        finance.incomes.length +
        finance.rents.length +
        finance.bills.length +
        finance.loans.length;

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
                  _RecordsHeader(totalRecords: totalRecords),
                  const SizedBox(height: 22),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 2 : 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isWide ? 2.45 : 2.25,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return _RecordCard(
                        item: item,
                        meta: buildMetaText(
                          item: item,
                          finance: finance,
                          currency: currency,
                        ),
                        onTap: () => openSection(item.section),
                      );
                    },
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

class _RecordsHeader extends StatelessWidget {
  const _RecordsHeader({
    required this.totalRecords,
  });

  final int totalRecords;

  @override
  Widget build(BuildContext context) {
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
            color: const Color(0xFF2563EB).withOpacity(0.22),
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
                'Records',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Manage expenses, income, rent, bills and loans from one place.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
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
                const Icon(
                  Icons.folder_copy_outlined,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  '$totalRecords Records',
                  style: const TextStyle(
                    color: Colors.white,
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

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.item,
    required this.meta,
    required this.onTap,
  });

  final _RecordItem item;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Ink(
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
          child: Row(
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: item.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ],
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
    required this.page,
  });

  final RecordSection section;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;
}