import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/currency_provider.dart';
import '../../../core/providers/finance_provider.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({
    super.key,
    this.openAddForm = false,
  });

  final bool openAddForm;

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final searchController = TextEditingController();

  String search = '';
  String selectedCategoryFilter = 'All';
  String selectedSourceFilter = 'All';

  static const List<String> incomeCategories = [
    'Salary',
    'Business',
    'Rent',
    'Freelance',
    'Gift',
    'Other',
  ];

  List<String> sourceFilters(List<IncomeRecord> incomes) {
    final values = incomes
        .map((item) => item.source.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return ['All', ...values];
  }

  List<IncomeRecord> getFilteredIncomes(List<IncomeRecord> incomes) {
    return incomes.where((item) {
      final value = search.trim().toLowerCase();

      final matchesSearch = value.isEmpty ||
          item.title.toLowerCase().contains(value) ||
          item.source.toLowerCase().contains(value) ||
          item.category.toLowerCase().contains(value) ||
          item.date.toLowerCase().contains(value) ||
          item.amount.toString().contains(value);

      final matchesCategory = selectedCategoryFilter == 'All' ||
          item.category == selectedCategoryFilter;

      final matchesSource =
          selectedSourceFilter == 'All' || item.source == selectedSourceFilter;

      return matchesSearch && matchesCategory && matchesSource;
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

  String readableDateFromText(String value) {
    final parsed = DateTime.tryParse(value);

    if (parsed == null) return value;

    return readableDate(parsed);
  }

  Future<void> pickIncomeDate({
    required DateTime selectedDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime(DateTime.now().year + 10),
      helpText: 'Select income date',
    );

    if (pickedDate == null) return;

    onPicked(pickedDate);
  }

  String topCategory(List<IncomeRecord> incomes) {
    if (incomes.isEmpty) return 'No category';

    final totals = <String, double>{};

    for (final item in incomes) {
      totals[item.category] = (totals[item.category] ?? 0) + item.amount;
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  String topSource(List<IncomeRecord> incomes) {
    if (incomes.isEmpty) return 'No source';

    final totals = <String, double>{};

    for (final item in incomes) {
      totals[item.source] = (totals[item.source] ?? 0) + item.amount;
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  void clearFilters() {
    setState(() {
      search = '';
      selectedCategoryFilter = 'All';
      selectedSourceFilter = 'All';
      searchController.clear();
    });
  }

  void openIncomeSheet({IncomeRecord? existingIncome}) {
    final isEdit = existingIncome != null;

    final titleController = TextEditingController(
      text: existingIncome?.title ?? '',
    );

    final sourceController = TextEditingController(
      text: existingIncome?.source ?? '',
    );

    final amountController = TextEditingController(
      text: existingIncome == null
          ? ''
          : existingIncome.amount.toStringAsFixed(
              existingIncome.amount.truncateToDouble() == existingIncome.amount
                  ? 0
                  : 2,
            ),
    );

    String selectedCategory = existingIncome?.category ?? 'Salary';
    DateTime selectedDate = parseSavedDate(existingIncome?.date ?? '');

    if (!incomeCategories.contains(selectedCategory)) {
      selectedCategory = 'Salary';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _SheetContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SheetTitle(
                    icon: isEdit
                        ? Icons.edit_note_outlined
                        : Icons.trending_up_outlined,
                    title: isEdit ? 'Edit Income' : 'Add Income',
                    subtitle: isEdit
                        ? 'Update this income record with correct details.'
                        : 'Record a new income source for your budget.',
                    color: const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 20),
                  _AppField(
                    controller: titleController,
                    hint: 'Income title',
                    icon: Icons.title,
                  ),
                  const SizedBox(height: 14),
                  _AppField(
                    controller: sourceController,
                    hint: 'Source',
                    icon: Icons.account_circle_outlined,
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
                    items: incomeCategories.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(
                          item,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setSheetState(() {
                        selectedCategory = value ?? 'Salary';
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  _DatePickerField(
                    readableDate: readableDate(selectedDate),
                    savedDate: formatDate(selectedDate),
                    color: const Color(0xFF16A34A),
                    onTap: () {
                      pickIncomeDate(
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
                      icon: Icon(
                        isEdit ? Icons.save_outlined : Icons.add_circle_outline,
                      ),
                      label: Text(isEdit ? 'Update Income' : 'Save Income'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: () {
                        final title = titleController.text.trim();
                        final source = sourceController.text.trim();
                        final amount =
                            double.tryParse(amountController.text.trim()) ?? 0;

                        if (title.isEmpty || source.isEmpty || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter valid income data'),
                            ),
                          );
                          return;
                        }

                        final newRecord = IncomeRecord(
                          title: title,
                          source: source,
                          category: selectedCategory,
                          amount: amount,
                          date: formatDate(selectedDate),
                        );

                        if (isEdit) {
                          context.read<FinanceProvider>().updateIncome(
                                oldRecord: existingIncome,
                                newRecord: newRecord,
                              );
                        } else {
                          context.read<FinanceProvider>().addIncome(newRecord);
                        }

                        Navigator.pop(sheetContext);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit
                                  ? 'Income updated successfully'
                                  : 'Income added successfully',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void deleteIncome(IncomeRecord item) {
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
              Expanded(child: Text('Delete Income')),
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
                context.read<FinanceProvider>().deleteIncome(item);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Income deleted')),
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
  void initState() {
    super.initState();

    if (widget.openAddForm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        openIncomeSheet();
      });
    }
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
    final sourceFilterItems = sourceFilters(finance.incomes);

    if (!sourceFilterItems.contains(selectedSourceFilter)) {
      selectedSourceFilter = 'All';
    }

    final items = getFilteredIncomes(finance.incomes);
    final filteredTotal = items.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1060),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IncomeHeroHeader(
                    totalIncome: currency.formatAmount(finance.totalIncome),
                    totalRecords: finance.incomes.length,
                    filteredTotal: currency.formatAmount(filteredTotal),
                    filteredCount: items.length,
                    onBack: () => Navigator.pop(context),
                    onAdd: () => openIncomeSheet(),
                  ),
                  const SizedBox(height: 18),
                  _SummaryGrid(
                    cards: [
                      _SummaryInfo(
                        title: 'Total Income',
                        value: currency.formatAmount(finance.totalIncome),
                        subtitle: 'All saved income',
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFF16A34A),
                      ),
                      _SummaryInfo(
                        title: 'Records',
                        value: finance.incomes.length.toString(),
                        subtitle: 'Income entries',
                        icon: Icons.storage_outlined,
                        color: const Color(0xFF2563EB),
                      ),
                      _SummaryInfo(
                        title: 'Top Category',
                        value: topCategory(finance.incomes),
                        subtitle: 'Highest earning type',
                        icon: Icons.category_outlined,
                        color: const Color(0xFF7C3AED),
                      ),
                      _SummaryInfo(
                        title: 'Top Source',
                        value: topSource(finance.incomes),
                        subtitle: 'Highest income source',
                        icon: Icons.account_circle_outlined,
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SearchFilterPanel(
                    searchController: searchController,
                    search: search,
                    selectedCategory: selectedCategoryFilter,
                    selectedSource: selectedSourceFilter,
                    sourceItems: sourceFilterItems,
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
                    onSourceChanged: (value) {
                      setState(() {
                        selectedSourceFilter = value;
                      });
                    },
                    onClear: clearFilters,
                  ),
                  const SizedBox(height: 18),
                  _ListHeader(
                    count: items.length,
                    amount: currency.formatAmount(filteredTotal),
                    onAdd: () => openIncomeSheet(),
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    _EmptyState(
                      hasFilters: search.trim().isNotEmpty ||
                          selectedCategoryFilter != 'All' ||
                          selectedSourceFilter != 'All',
                      onAdd: () => openIncomeSheet(),
                      onClear: clearFilters,
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];

                        return _IncomeCard(
                          item: item,
                          currency: currency,
                          readableDate: readableDateFromText(item.date),
                          onEdit: () => openIncomeSheet(existingIncome: item),
                          onDelete: () => deleteIncome(item),
                        );
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

class _IncomeHeroHeader extends StatelessWidget {
  const _IncomeHeroHeader({
    required this.totalIncome,
    required this.totalRecords,
    required this.filteredTotal,
    required this.filteredCount,
    required this.onBack,
    required this.onAdd,
  });

  final String totalIncome;
  final int totalRecords;
  final String filteredTotal;
  final int filteredCount;
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
            Color(0xFF16A34A),
            Color(0xFF22C55E),
            Color(0xFF06B6D4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withOpacity(0.22),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF052E16).withOpacity(0.94),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -75,
              top: -90,
              child: _GlowCircle(
                size: 220,
                color: Color(0xFF22C55E),
              ),
            ),
            const Positioned(
              left: -90,
              bottom: -120,
              child: _GlowCircle(
                size: 230,
                color: Color(0xFF38BDF8),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 820;

                final left = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _HeroPill(
                          icon: Icons.storage_outlined,
                          label: '$totalRecords Records',
                        ),
                        _HeroPill(
                          icon: Icons.filter_alt_outlined,
                          label: '$filteredCount Showing',
                        ),
                        const _HeroPill(
                          icon: Icons.verified_outlined,
                          label: 'Income Workspace',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _HeaderIconButton(
                          icon: Icons.arrow_back,
                          onTap: onBack,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Income',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Manage salary, business, rent, freelance, gifts, and other income sources.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _HeroActionButton(
                          icon: Icons.add_circle_outline,
                          label: 'Add Income',
                          onTap: onAdd,
                        ),
                      ],
                    ),
                  ],
                );

                final right = _HeroMetricPanel(
                  totalIncome: totalIncome,
                  filteredTotal: filteredTotal,
                  filteredCount: filteredCount,
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

class _HeroMetricPanel extends StatelessWidget {
  const _HeroMetricPanel({
    required this.totalIncome,
    required this.filteredTotal,
    required this.filteredCount,
  });

  final String totalIncome;
  final String filteredTotal;
  final int filteredCount;

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
                  'Income Summary',
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
          _HeroMetricRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Total Income',
            value: totalIncome,
          ),
          const SizedBox(height: 10),
          _HeroMetricRow(
            icon: Icons.filter_alt_outlined,
            label: 'Filtered Total',
            value: filteredTotal,
          ),
          const SizedBox(height: 10),
          _HeroMetricRow(
            icon: Icons.list_alt_outlined,
            label: 'Filtered Records',
            value: filteredCount.toString(),
          ),
        ],
      ),
    );
  }
}

class _HeroMetricRow extends StatelessWidget {
  const _HeroMetricRow({
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

class _HeroPill extends StatelessWidget {
  const _HeroPill({
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
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_circle_outline,
                color: Color(0xFF16A34A),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF16A34A),
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

class _SummaryInfo {
  const _SummaryInfo({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.cards,
  });

  final List<_SummaryInfo> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 850;
        final isTablet = constraints.maxWidth > 560;
        final crossAxisCount = isWide
            ? 4
            : isTablet
                ? 2
                : 1;

        return GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isWide
                ? 1.30
                : isTablet
                    ? 2.35
                    : 3.35,
          ),
          itemBuilder: (context, index) {
            final item = cards[index];

            return _SummaryCard(item: item);
          },
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.item,
  });

  final _SummaryInfo item;

  @override
  Widget build(BuildContext context) {
    return _HoverScale(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(0.07),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: item.color.withOpacity(0.12),
              child: Icon(item.icon, color: item.color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

class _SearchFilterPanel extends StatelessWidget {
  const _SearchFilterPanel({
    required this.searchController,
    required this.search,
    required this.selectedCategory,
    required this.selectedSource,
    required this.sourceItems,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onSourceChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final String search;
  final String selectedCategory;
  final String selectedSource;
  final List<String> sourceItems;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSourceChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasFilters = search.trim().isNotEmpty ||
        selectedCategory != 'All' ||
        selectedSource != 'All';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search income by title, source, category, date...',
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
              final isWide = constraints.maxWidth > 720;

              final categoryDropdown = _FilterDropdown(
                label: 'Category',
                value: selectedCategory,
                items: const [
                  'All',
                  'Salary',
                  'Business',
                  'Rent',
                  'Freelance',
                  'Gift',
                  'Other',
                ],
                onChanged: onCategoryChanged,
              );

              final sourceDropdown = _FilterDropdown(
                label: 'Source',
                value: selectedSource,
                items: sourceItems,
                onChanged: onSourceChanged,
              );

              final clearButton = _ClearFilterButton(
                enabled: hasFilters,
                onTap: onClear,
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: categoryDropdown),
                    const SizedBox(width: 12),
                    Expanded(child: sourceDropdown),
                    const SizedBox(width: 12),
                    clearButton,
                  ],
                );
              }

              return Column(
                children: [
                  categoryDropdown,
                  const SizedBox(height: 12),
                  sourceDropdown,
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: clearButton,
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
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
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
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    label == 'Source' && item.length > 28
                        ? '${item.substring(0, 28)}...'
                        : item,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            onChanged(value);
          },
        ),
      ),
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
      label: const Text('Clear Filters'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF16A34A),
        disabledForegroundColor: const Color(0xFF94A3B8),
        side: BorderSide(
          color: enabled ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
        ),
        minimumSize: const Size(150, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.count,
    required this.amount,
    required this.onAdd,
  });

  final int count;
  final String amount;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFDCFCE7),
          child: Icon(
            Icons.list_alt_outlined,
            color: Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Income Records',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$count records • $amount',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _IncomeCard extends StatelessWidget {
  const _IncomeCard({
    required this.item,
    required this.currency,
    required this.readableDate,
    required this.onEdit,
    required this.onDelete,
  });

  final IncomeRecord item;
  final CurrencyProvider currency;
  final String readableDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _HoverScale(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF16A34A).withOpacity(0.06),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 620;

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IncomeCardMainInfo(
                    item: item,
                    readableDate: readableDate,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        currency.formatAmount(item.amount),
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      _ActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        color: const Color(0xFF2563EB),
                        onTap: onEdit,
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        color: const Color(0xFFDC2626),
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _IncomeCardMainInfo(
                        item: item,
                        readableDate: readableDate,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  currency.formatAmount(item.amount),
                  style: const TextStyle(
                    color: Color(0xFF16A34A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 12),
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
          },
        ),
      ),
    );
  }
}

class _IncomeCardMainInfo extends StatelessWidget {
  const _IncomeCardMainInfo({
    required this.item,
    required this.readableDate,
  });

  final IncomeRecord item;
  final String readableDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF16A34A).withOpacity(0.12),
          child: const Icon(
            Icons.trending_up_outlined,
            color: Color(0xFF16A34A),
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
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${item.category} • ${item.source} • $readableDate',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
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

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.readableDate,
    required this.savedDate,
    required this.color,
    required this.onTap,
  });

  final String readableDate;
  final String savedDate;
  final Color color;
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
              Icon(
                Icons.edit_calendar_outlined,
                color: color,
              ),
            ],
          ),
        ),
      ),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
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

class _SheetContainer extends StatelessWidget {
  const _SheetContainer({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
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
          top: Radius.circular(30),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({
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
          radius: 26,
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
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            hasFilters ? Icons.search_off_outlined : Icons.trending_up_outlined,
            size: 60,
            color: const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            hasFilters ? 'No matching income found' : 'No income found',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilters
                ? 'Try clearing filters or searching another keyword.'
                : 'Add your first income record to start tracking.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add Income'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              if (hasFilters)
                OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Clear Filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF16A34A),
                    side: const BorderSide(color: Color(0xFFBBF7D0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
            ],
          ),
        ],
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
          color: color.withOpacity(0.13),
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
        scale: isHovered ? 1.014 : 1,
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
