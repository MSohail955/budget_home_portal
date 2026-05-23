import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/currency_provider.dart';
import '../../../core/providers/finance_provider.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final searchController = TextEditingController();

  String search = '';
  String selectedCategoryFilter = 'All';
  String selectedPaymentFilter = 'All';

  static const List<String> expenseCategories = [
    'Grocery',
    'Milk',
    'Electricity',
    'Internet',
    'School Fees',
    'Home Renovation',
    'Paint / Color Work',
    'Sanitary Work',
    'Electric Work',
    'Plumbing Work',
    'Tenant Work',
    'Extra Expense',
  ];

  static const List<String> paymentMethods = [
    'Cash',
    'Card',
    'Bank Transfer',
    'Other',
  ];

  List<ExpenseRecord> getFilteredExpenses(List<ExpenseRecord> expenses) {
    return expenses.where((item) {
      final query = search.trim().toLowerCase();

      final matchesSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.paymentMethod.toLowerCase().contains(query) ||
          item.date.toLowerCase().contains(query) ||
          item.amount.toString().contains(query);

      final matchesCategory = selectedCategoryFilter == 'All' ||
          item.category == selectedCategoryFilter;

      final matchesPayment = selectedPaymentFilter == 'All' ||
          item.paymentMethod == selectedPaymentFilter;

      return matchesSearch && matchesCategory && matchesPayment;
    }).toList();
  }

  DateTime parseSavedDate(String value) {
    final cleanValue = value.trim();

    if (cleanValue.isEmpty || cleanValue.toLowerCase() == 'today') {
      return DateTime.now();
    }

    final parsed = DateTime.tryParse(cleanValue);

    if (parsed != null) {
      return parsed;
    }

    return DateTime.now();
  }

  String formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String readableDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> pickExpenseDate({
    required DateTime selectedDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime(DateTime.now().year + 10),
      helpText: 'Select expense date',
    );

    if (pickedDate == null) return;

    onPicked(pickedDate);
  }

  String topCategory(List<ExpenseRecord> expenses) {
    if (expenses.isEmpty) return 'No category';

    final totals = <String, double>{};

    for (final item in expenses) {
      totals[item.category] = (totals[item.category] ?? 0) + item.amount;
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  String topPaymentMethod(List<ExpenseRecord> expenses) {
    if (expenses.isEmpty) return 'No method';

    final counts = <String, int>{};

    for (final item in expenses) {
      counts[item.paymentMethod] = (counts[item.paymentMethod] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  void clearFilters() {
    setState(() {
      search = '';
      selectedCategoryFilter = 'All';
      selectedPaymentFilter = 'All';
      searchController.clear();
    });
  }

  void openExpenseSheet({ExpenseRecord? existingExpense}) {
    final isEdit = existingExpense != null;

    final titleController = TextEditingController(
      text: existingExpense?.title ?? '',
    );

    final amountController = TextEditingController(
      text: existingExpense == null
          ? ''
          : existingExpense.amount.toStringAsFixed(0),
    );

    String selectedCategory = existingExpense?.category ?? 'Grocery';
    String selectedMethod = existingExpense?.paymentMethod ?? 'Cash';
    DateTime selectedDate = parseSavedDate(existingExpense?.date ?? '');
    bool isSubmitting = false;

    if (!expenseCategories.contains(selectedCategory)) {
      selectedCategory = 'Grocery';
    }

    if (!paymentMethods.contains(selectedMethod)) {
      selectedMethod = 'Cash';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void submit() {
              final title = titleController.text.trim();
              final amount = double.tryParse(amountController.text.trim()) ?? 0;

              if (title.isEmpty || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid title and amount'),
                  ),
                );
                return;
              }

              setSheetState(() {
                isSubmitting = true;
              });

              final newRecord = ExpenseRecord(
                title: title,
                category: selectedCategory,
                amount: amount,
                date: formatDate(selectedDate),
                paymentMethod: selectedMethod,
              );

              if (isEdit) {
                context.read<FinanceProvider>().updateExpense(
                      oldRecord: existingExpense,
                      newRecord: newRecord,
                    );
              } else {
                context.read<FinanceProvider>().addExpense(newRecord);
              }

              Navigator.pop(sheetContext);

              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(
                    isEdit
                        ? 'Expense updated successfully'
                        : 'Expense added successfully',
                  ),
                ),
              );
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.92,
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
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SheetHeader(
                          icon: isEdit
                              ? Icons.edit_outlined
                              : Icons.add_card_outlined,
                          title: isEdit ? 'Edit Expense' : 'Add Expense',
                          subtitle: isEdit
                              ? 'Update this expense record with accurate details.'
                              : 'Record a new home or personal expense.',
                          color: const Color(0xFFDC2626),
                        ),
                        const SizedBox(height: 20),
                        _AppField(
                          controller: titleController,
                          hint: 'Expense title',
                          icon: Icons.title,
                        ),
                        const SizedBox(height: 14),
                        _AppField(
                          controller: amountController,
                          hint: 'Amount',
                          icon: Icons.payments_outlined,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: _inputDecoration(
                            'Category',
                            Icons.category_outlined,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          items: expenseCategories.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setSheetState(() {
                              selectedCategory = value ?? 'Grocery';
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: selectedMethod,
                          decoration: _inputDecoration(
                            'Payment method',
                            Icons.credit_card_outlined,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          items: paymentMethods.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setSheetState(() {
                              selectedMethod = value ?? 'Cash';
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        _DatePickerField(
                          selectedDate: selectedDate,
                          readableDate: readableDate(selectedDate),
                          savedDate: formatDate(selectedDate),
                          onTap: () {
                            pickExpenseDate(
                              selectedDate: selectedDate,
                              onPicked: (pickedDate) {
                                setSheetState(() {
                                  selectedDate = pickedDate;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF94A3B8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            onPressed: isSubmitting ? null : submit,
                            icon: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(isEdit
                                    ? Icons.save_outlined
                                    : Icons.add_circle_outline),
                            label: Text(
                              isSubmitting
                                  ? 'Saving...'
                                  : isEdit
                                      ? 'Update Expense'
                                      : 'Save Expense',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void deleteExpense(ExpenseRecord item) {
    showDialog(
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
                  Icons.delete_outline,
                  color: Color(0xFFDC2626),
                ),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Delete Expense')),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${item.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
              onPressed: () {
                context.read<FinanceProvider>().deleteExpense(item);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expense deleted')),
                );
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final finance = context.watch<FinanceProvider>();
    final filteredItems = getFilteredExpenses(finance.expenses);
    final totalFiltered = filteredItems.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    final hasFilters = search.trim().isNotEmpty ||
        selectedCategoryFilter != 'All' ||
        selectedPaymentFilter != 'All';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'expenses_add_fab',
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        onPressed: () => openExpenseSheet(),
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Expense',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnimatedEntry(
                    delay: 0,
                    child: _ExpensesHeader(
                      totalExpense: finance.totalExpenses,
                      totalRecords: finance.expenses.length,
                      filteredAmount: totalFiltered,
                      filteredRecords: filteredItems.length,
                      currency: currency,
                      topCategory: topCategory(finance.expenses),
                      onBack: () => Navigator.pop(context),
                      onAdd: () => openExpenseSheet(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _AnimatedEntry(
                    delay: 80,
                    child: _ExpenseSummaryGrid(
                      currency: currency,
                      totalExpense: finance.totalExpenses,
                      totalRecords: finance.expenses.length,
                      filteredAmount: totalFiltered,
                      filteredRecords: filteredItems.length,
                      topCategory: topCategory(finance.expenses),
                      topPaymentMethod: topPaymentMethod(finance.expenses),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _AnimatedEntry(
                    delay: 160,
                    child: _SearchAndFilterPanel(
                      searchController: searchController,
                      search: search,
                      selectedCategoryFilter: selectedCategoryFilter,
                      selectedPaymentFilter: selectedPaymentFilter,
                      categories: expenseCategories,
                      methods: paymentMethods,
                      onSearchChanged: (value) {
                        setState(() {
                          search = value;
                        });
                      },
                      onCategoryChanged: (value) {
                        setState(() {
                          selectedCategoryFilter = value;
                        });
                      },
                      onPaymentChanged: (value) {
                        setState(() {
                          selectedPaymentFilter = value;
                        });
                      },
                      onClear: clearFilters,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _AnimatedEntry(
                    delay: 220,
                    child: _SectionTitle(
                      count: filteredItems.length,
                      hasFilters: hasFilters,
                      filteredAmount: currency.formatAmount(totalFiltered),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (filteredItems.isEmpty)
                    _AnimatedEntry(
                      delay: 280,
                      child: _EmptyState(
                        hasFilters: hasFilters,
                        onAdd: () => openExpenseSheet(),
                        onClear: clearFilters,
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];

                        return _AnimatedEntry(
                          delay: 280 + (index * 40).clamp(0, 320),
                          child: _ExpenseCard(
                            item: item,
                            currency: currency,
                            onEdit: () => openExpenseSheet(
                              existingExpense: item,
                            ),
                            onDelete: () => deleteExpense(item),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpensesHeader extends StatelessWidget {
  const _ExpensesHeader({
    required this.totalExpense,
    required this.totalRecords,
    required this.filteredAmount,
    required this.filteredRecords,
    required this.currency,
    required this.topCategory,
    required this.onBack,
    required this.onAdd,
  });

  final double totalExpense;
  final int totalRecords;
  final double filteredAmount;
  final int filteredRecords;
  final CurrencyProvider currency;
  final String topCategory;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFDC2626),
            Color(0xFFF97316),
            Color(0xFF7C3AED),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withOpacity(0.22),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF111827).withOpacity(0.94),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -90,
              top: -90,
              child: _GlowCircle(
                size: 230,
                color: Color(0xFFF97316),
              ),
            ),
            const Positioned(
              left: -90,
              bottom: -110,
              child: _GlowCircle(
                size: 220,
                color: Color(0xFFDC2626),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 820;

                final left = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _HeaderIconButton(
                          icon: Icons.arrow_back,
                          onTap: onBack,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Expenses',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (!isWide)
                          _HeaderIconButton(
                            icon: Icons.add,
                            onTap: onAdd,
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _HeaderPill(
                          icon: Icons.receipt_long_outlined,
                          label: '$totalRecords Records',
                        ),
                        _HeaderPill(
                          icon: Icons.category_outlined,
                          label: topCategory,
                        ),
                        _HeaderPill(
                          icon: Icons.filter_alt_outlined,
                          label: '$filteredRecords Filtered',
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Track every home expense with clarity.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Add, search, filter, edit and review your spending records in one clean workspace.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (isWide)
                      ElevatedButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add Expense'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFDC2626),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                );

                final right = _HeaderMetricPanel(
                  totalExpense: currency.formatAmount(totalExpense),
                  filteredAmount: currency.formatAmount(filteredAmount),
                  totalRecords: totalRecords,
                  filteredRecords: filteredRecords,
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(flex: 6, child: left),
                      const SizedBox(width: 22),
                      Expanded(flex: 4, child: right),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    left,
                    const SizedBox(height: 20),
                    right,
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
    required this.totalExpense,
    required this.filteredAmount,
    required this.totalRecords,
    required this.filteredRecords,
  });

  final String totalExpense;
  final String filteredAmount;
  final int totalRecords;
  final int filteredRecords;

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
                  'Expense Summary',
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
            icon: Icons.payments_outlined,
            label: 'Total Expense',
            value: totalExpense,
          ),
          const SizedBox(height: 10),
          _HeaderMiniMetric(
            icon: Icons.filter_alt_outlined,
            label: 'Filtered Amount',
            value: filteredAmount,
          ),
          const SizedBox(height: 10),
          _HeaderMiniMetric(
            icon: Icons.storage_outlined,
            label: 'Records',
            value: '$filteredRecords / $totalRecords',
          ),
        ],
      ),
    );
  }
}
class _ExpenseSummaryGrid extends StatelessWidget {
  const _ExpenseSummaryGrid({
    required this.currency,
    required this.totalExpense,
    required this.totalRecords,
    required this.filteredAmount,
    required this.filteredRecords,
    required this.topCategory,
    required this.topPaymentMethod,
  });

  final CurrencyProvider currency;
  final double totalExpense;
  final int totalRecords;
  final double filteredAmount;
  final int filteredRecords;
  final String topCategory;
  final String topPaymentMethod;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryTile(
        icon: Icons.payments_outlined,
        title: 'Total Expenses',
        value: currency.formatAmount(totalExpense),
        subtitle: 'All saved expense records',
        color: const Color(0xFFDC2626),
      ),
      _SummaryTile(
        icon: Icons.filter_alt_outlined,
        title: 'Filtered Total',
        value: currency.formatAmount(filteredAmount),
        subtitle: '$filteredRecords visible records',
        color: const Color(0xFF2563EB),
      ),
      _SummaryTile(
        icon: Icons.category_outlined,
        title: 'Top Category',
        value: topCategory,
        subtitle: '$totalRecords total records',
        color: const Color(0xFF7C3AED),
      ),
      _SummaryTile(
        icon: Icons.credit_card_outlined,
        title: 'Top Method',
        value: topPaymentMethod,
        subtitle: 'Most used payment method',
        color: const Color(0xFFF59E0B),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 860;
        final isTablet = constraints.maxWidth > 620;

        if (isWide) {
          return Row(
            children: [
              for (int index = 0; index < cards.length; index++) ...[
                Expanded(child: cards[index]),
                if (index != cards.length - 1) const SizedBox(width: 14),
              ],
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 14),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: 14),
            if (isTablet)
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 14),
                  Expanded(child: cards[3]),
                ],
              )
            else ...[
              cards[2],
              const SizedBox(height: 14),
              cards[3],
            ],
          ],
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _HoverScale(
      child: Container(
        constraints: const BoxConstraints(minHeight: 140),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
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
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 5),
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

class _SearchAndFilterPanel extends StatelessWidget {
  const _SearchAndFilterPanel({
    required this.searchController,
    required this.search,
    required this.selectedCategoryFilter,
    required this.selectedPaymentFilter,
    required this.categories,
    required this.methods,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onPaymentChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final String search;
  final String selectedCategoryFilter;
  final String selectedPaymentFilter;
  final List<String> categories;
  final List<String> methods;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onPaymentChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasFilters = search.trim().isNotEmpty ||
        selectedCategoryFilter != 'All' ||
        selectedPaymentFilter != 'All';

    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFFFE4E6),
                child: Icon(
                  Icons.search,
                  color: Color(0xFFDC2626),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search & Filter',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search title, category, amount, payment method...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: search.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 680;

              final category = _FilterDropdown(
                label: 'Category',
                value: selectedCategoryFilter,
                items: ['All', ...categories],
                icon: Icons.category_outlined,
                onChanged: onCategoryChanged,
              );

              final payment = _FilterDropdown(
                label: 'Payment',
                value: selectedPaymentFilter,
                items: ['All', ...methods],
                icon: Icons.credit_card_outlined,
                onChanged: onPaymentChanged,
              );

              final clear = _ClearFilterButton(
                enabled: hasFilters,
                onTap: onClear,
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: category),
                    const SizedBox(width: 12),
                    Expanded(child: payment),
                    const SizedBox(width: 12),
                    clear,
                  ],
                );
              }

              return Column(
                children: [
                  category,
                  const SizedBox(height: 12),
                  payment,
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: clear,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecoration(label, icon),
      borderRadius: BorderRadius.circular(18),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        onChanged(value);
      },
    );
  }
}

class _ClearFilterButton extends StatelessWidget {
  const _ClearFilterButton({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: const Icon(Icons.restart_alt),
      label: const Text('Clear'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFDC2626),
        disabledForegroundColor: const Color(0xFF94A3B8),
        side: BorderSide(
          color: enabled ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.count,
    required this.hasFilters,
    required this.filteredAmount,
  });

  final int count;
  final bool hasFilters;
  final String filteredAmount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFFFE4E6),
          child: Icon(
            Icons.receipt_long_outlined,
            color: Color(0xFFDC2626),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Expense Records',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                hasFilters
                    ? '$count matching records • $filteredAmount'
                    : '$count total records • $filteredAmount',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.item,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  final ExpenseRecord item;
  final CurrencyProvider currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String readableDate(String value) {
    final parsed = DateTime.tryParse(value);

    if (parsed == null) return value;

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    return _HoverScale(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onEdit,
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withOpacity(0.055),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 620;

                final icon = CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFFDC2626).withOpacity(0.12),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: Color(0xFFDC2626),
                  ),
                );

                final info = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaPill(
                          icon: Icons.category_outlined,
                          label: item.category,
                          color: const Color(0xFF7C3AED),
                        ),
                        _MetaPill(
                          icon: Icons.credit_card_outlined,
                          label: item.paymentMethod,
                          color: const Color(0xFF2563EB),
                        ),
                        _MetaPill(
                          icon: Icons.calendar_month_outlined,
                          label: readableDate(item.date),
                          color: const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                  ],
                );

                final amount = FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    currency.formatAmount(item.amount),
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                );

                final actions = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IconCircleButton(
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF2563EB),
                      onTap: onEdit,
                    ),
                    const SizedBox(width: 8),
                    _IconCircleButton(
                      icon: Icons.delete_outline,
                      color: const Color(0xFFDC2626),
                      onTap: onDelete,
                    ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          icon,
                          const SizedBox(width: 14),
                          Expanded(child: info),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: amount),
                          const SizedBox(width: 12),
                          actions,
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    icon,
                    const SizedBox(width: 14),
                    Expanded(child: info),
                    const SizedBox(width: 12),
                    SizedBox(width: 150, child: amount),
                    const SizedBox(width: 12),
                    actions,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasFilters,
    required this.onAdd,
    required this.onClear,
  });

  final bool hasFilters;
  final VoidCallback onAdd;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            hasFilters ? Icons.search_off_outlined : Icons.receipt_long_outlined,
            size: 62,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilters ? 'No matching expenses found' : 'No expenses yet',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 19,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            hasFilters
                ? 'Try changing your search or filters.'
                : 'Add your first expense to start tracking home spending.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add Expense'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (hasFilters)
                OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Clear Filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.selectedDate,
    required this.readableDate,
    required this.savedDate,
    required this.onTap,
  });

  final DateTime selectedDate;
  final String readableDate;
  final String savedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      readableDate,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Saved as $savedDate for reports',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.edit_calendar_outlined,
                color: Color(0xFF2563EB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
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
    return Row(
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.13),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: Colors.white,
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
        horizontal: 13,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 7),
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
        color: Colors.white.withOpacity(0.96),
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

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _AppField extends StatelessWidget {
  const _AppField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(hint, icon),
    );
  }
}

InputDecoration _inputDecoration(String hint, IconData icon) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  );
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
        scale: isHovered ? 1.012 : 1,
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
