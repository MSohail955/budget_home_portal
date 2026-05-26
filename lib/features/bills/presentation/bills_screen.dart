import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/currency_provider.dart';
import '../../../core/providers/finance_provider.dart';
import '../../../core/providers/reminder_provider.dart';

enum BillStatusFilter {
  all,
  paid,
  pending,
  dueSoon,
  overdue,
}

class BillsScreen extends StatefulWidget {
  const BillsScreen({
    super.key,
    this.openAddForm = false,
  });

  final bool openAddForm;

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final searchController = TextEditingController();

  String search = '';
  BillStatusFilter selectedFilter = BillStatusFilter.all;

  List<BillRecord> getFilteredBills({
    required List<BillRecord> bills,
    required ReminderProvider reminder,
  }) {
    var filteredBills = bills;

    filteredBills = filteredBills.where((item) {
      if (selectedFilter == BillStatusFilter.all) return true;

      if (selectedFilter == BillStatusFilter.paid) {
        return item.isPaid;
      }

      if (selectedFilter == BillStatusFilter.pending) {
        return !item.isPaid;
      }

      if (selectedFilter == BillStatusFilter.dueSoon) {
        return isDueSoon(item, reminder.remindBeforeDays);
      }

      if (selectedFilter == BillStatusFilter.overdue) {
        return isOverdue(item);
      }

      return true;
    }).toList();

    if (search.trim().isEmpty) return filteredBills;

    return filteredBills.where((item) {
      final value = search.toLowerCase();

      return item.title.toLowerCase().contains(value) ||
          item.category.toLowerCase().contains(value) ||
          item.dueDate.toLowerCase().contains(value) ||
          item.status.toLowerCase().contains(value) ||
          item.amount.toString().contains(value);
    }).toList();
  }

  DateTime todayOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime? tryParseDate(String value) {
    return DateTime.tryParse(value.trim());
  }

  bool isOverdue(BillRecord item) {
    if (item.isPaid) return false;

    final dueDate = tryParseDate(item.dueDate);
    if (dueDate == null) return false;

    final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);

    return dueOnly.isBefore(todayOnly());
  }

  bool isDueSoon(BillRecord item, int remindBeforeDays) {
    if (item.isPaid) return false;

    final dueDate = tryParseDate(item.dueDate);
    if (dueDate == null) return false;

    final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = dueOnly.difference(todayOnly()).inDays;

    return diff >= 0 && diff <= remindBeforeDays;
  }

  int countPaid(List<BillRecord> bills) {
    return bills.where((item) => item.isPaid).length;
  }

  int countPending(List<BillRecord> bills) {
    return bills.where((item) => !item.isPaid).length;
  }

  int countDueSoon(List<BillRecord> bills, ReminderProvider reminder) {
    return bills.where((item) => isDueSoon(item, reminder.remindBeforeDays)).length;
  }

  int countOverdue(List<BillRecord> bills) {
    return bills.where(isOverdue).length;
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
    final months = const [
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

  DateTime buildDueDateForCurrentMonth(int day) {
    final now = DateTime.now();
    final safeDay = clampDayForMonth(now.year, now.month, day);

    return DateTime(now.year, now.month, safeDay);
  }

  int clampDayForMonth(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;

    if (day < 1) return 1;
    if (day > lastDay) return lastDay;

    return day;
  }

  DateTime autoDueDateByCategory({
    required String category,
    required ReminderProvider reminder,
    required DateTime currentDate,
  }) {
    final year = currentDate.year;
    final month = currentDate.month;

    if (category == 'Internet') {
      return DateTime(
        year,
        month,
        clampDayForMonth(year, month, reminder.internetBillDay),
      );
    }

    if (category == 'School Fees') {
      return DateTime(
        year,
        month,
        clampDayForMonth(year, month, reminder.schoolFeesDay),
      );
    }

    if (category == 'Electricity') {
      return DateTime(
        year,
        month,
        clampDayForMonth(year, month, reminder.electricityBillDay),
      );
    }

    return currentDate;
  }

  String reminderHintForCategory({
    required String category,
    required ReminderProvider reminder,
  }) {
    if (category == 'Internet') {
      return 'Auto due date from Reminder Settings: day ${reminder.internetBillDay}';
    }

    if (category == 'School Fees') {
      return 'Auto due date from Reminder Settings: day ${reminder.schoolFeesDay}';
    }

    if (category == 'Electricity') {
      return 'Auto due date from Reminder Settings: day ${reminder.electricityBillDay}';
    }

    return 'Select due date manually for this bill category';
  }

  Future<void> pickBillDate({
    required DateTime selectedDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime(DateTime.now().year + 10),
      helpText: 'Select bill due date',
    );

    if (pickedDate == null) return;

    onPicked(pickedDate);
  }


  String? requiredTextValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }

    if (value.trim().length < 2) {
      return '$label must be at least 2 characters';
    }

    return null;
  }

  String? amountValidator(String? value) {
    final cleanValue = value?.trim() ?? '';

    if (cleanValue.isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(cleanValue);

    if (amount == null) {
      return 'Enter a valid amount';
    }

    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }

    if (amount > 999999999) {
      return 'Amount is too large';
    }

    return null;
  }

  void openBillSheet({BillRecord? existingBill}) {
    final reminder = context.read<ReminderProvider>();
    final isEdit = existingBill != null;
    final formKey = GlobalKey<FormState>();
    var autoValidateMode = AutovalidateMode.disabled;

    final titleController = TextEditingController(
      text: existingBill?.title ?? '',
    );

    final amountController = TextEditingController(
      text: existingBill == null ? '' : existingBill.amount.toStringAsFixed(0),
    );

    String selectedCategory = existingBill?.category ?? 'Electricity';
    bool isPaid = existingBill?.isPaid ?? false;
    DateTime selectedDueDate = existingBill == null
        ? autoDueDateByCategory(
            category: selectedCategory,
            reminder: reminder,
            currentDate: DateTime.now(),
          )
        : parseSavedDate(existingBill.dueDate);

    final categories = const [
      'Electricity',
      'Internet',
      'Water',
      'Gas',
      'School Fees',
      'House Rent',
      'Maintenance',
      'Other',
    ];

    if (!categories.contains(selectedCategory)) {
      selectedCategory = 'Electricity';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final liveReminder = context.watch<ReminderProvider>();

            return Container(
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
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Form(
                      key: formKey,
                      autovalidateMode: autoValidateMode,
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Bill' : 'Add Bill',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isEdit
                              ? 'Update bill details and payment status.'
                              : 'Add household bills and track paid/unpaid status.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 20),
                        _AppField(
                          controller: titleController,
                          hint: 'Bill title',
                          icon: Icons.receipt_long_outlined,
                          validator: (value) =>
                              requiredTextValidator(value, 'Bill title'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                        _AppField(
                          controller: amountController,
                          hint: 'Amount',
                          icon: Icons.payments_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: amountValidator,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\\d*\\.?\\d{0,2}'),
                            ),
                          ],
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: _inputDecoration(
                            'Category',
                            Icons.category_outlined,
                          ),
                          items: categories.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            );
                          }).toList(),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Category is required';
                            }

                            return null;
                          },
                          onChanged: (value) {
                            if (value == null) return;

                            setSheetState(() {
                              selectedCategory = value;
                              selectedDueDate = autoDueDateByCategory(
                                category: selectedCategory,
                                reminder: liveReminder,
                                currentDate: selectedDueDate,
                              );
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        _ReminderHintCard(
                          text: reminderHintForCategory(
                            category: selectedCategory,
                            reminder: liveReminder,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _DatePickerField(
                          title: 'Due Date',
                          readableDate: readableDate(selectedDueDate),
                          savedDate: formatDate(selectedDueDate),
                          color: const Color(0xFF2563EB),
                          onTap: () {
                            pickBillDate(
                              selectedDate: selectedDueDate,
                              onPicked: (pickedDate) {
                                setSheetState(() {
                                  selectedDueDate = pickedDate;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: isPaid,
                            activeColor: const Color(0xFF16A34A),
                            title: const Text(
                              'Mark as paid',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            subtitle: Text(
                              isPaid
                                  ? 'This bill is already paid.'
                                  : 'This bill is still unpaid.',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                              ),
                            ),
                            onChanged: (value) {
                              setSheetState(() {
                                isPaid = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: () {
                              FocusScope.of(context).unfocus();

                              setSheetState(() {
                                autoValidateMode =
                                    AutovalidateMode.onUserInteraction;
                              });

                              if (!(formKey.currentState?.validate() ?? false)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Please fix the highlighted fields'),
                                  ),
                                );
                                return;
                              }

                              final title = titleController.text.trim();
                              final amount =
                                  double.parse(amountController.text.trim());

                              final newRecord = BillRecord(
                                title: title,
                                category: selectedCategory,
                                amount: amount,
                                dueDate: formatDate(selectedDueDate),
                                isPaid: isPaid,
                              );

                              if (isEdit) {
                                context.read<FinanceProvider>().updateBill(
                                      oldRecord: existingBill,
                                      newRecord: newRecord,
                                    );
                              } else {
                                context.read<FinanceProvider>().addBill(
                                      newRecord,
                                    );
                              }

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEdit
                                        ? 'Bill updated successfully'
                                        : 'Bill added successfully',
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              isEdit ? 'Update Bill' : 'Save Bill',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

  void togglePaid(BillRecord item) {
    context.read<FinanceProvider>().toggleBillPaid(item);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          item.isPaid ? 'Bill marked as paid' : 'Bill marked as unpaid',
        ),
      ),
    );
  }

  void deleteBill(BillRecord item) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Bill'),
          content: Text(
            'Are you sure you want to delete "${item.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                context.read<FinanceProvider>().deleteBill(item);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bill deleted')),
                );
              },
              child: const Text('Delete'),
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
        openBillSheet();
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
    final reminder = context.watch<ReminderProvider>();

    final items = getFilteredBills(
      bills: finance.bills,
      reminder: reminder,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageHeader(
                    title: 'Bills',
                    onBack: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => openBillSheet(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Bill'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TotalBillsCard(
                    totalBills: finance.totalBills,
                    unpaidBills: finance.unpaidBills,
                    currency: currency,
                  ),
                  const SizedBox(height: 18),
                  _BillFilterBar(
                    selectedFilter: selectedFilter,
                    totalCount: finance.bills.length,
                    paidCount: countPaid(finance.bills),
                    pendingCount: countPending(finance.bills),
                    dueSoonCount: countDueSoon(finance.bills, reminder),
                    overdueCount: countOverdue(finance.bills),
                    onChanged: (filter) {
                      setState(() {
                        selectedFilter = filter;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        search = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search bills...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (items.isEmpty)
                    _EmptyState(
                      message: selectedFilter == BillStatusFilter.all
                          ? 'Add your first bill to start tracking.'
                          : 'No bills match this filter.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];

                        return _BillCard(
                          item: item,
                          currency: currency,
                          reminder: reminder,
                          isOverdue: isOverdue(item),
                          isDueSoon: isDueSoon(item, reminder.remindBeforeDays),
                          onEdit: () => openBillSheet(existingBill: item),
                          onToggle: () => togglePaid(item),
                          onDelete: () => deleteBill(item),
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

class _BillFilterBar extends StatelessWidget {
  const _BillFilterBar({
    required this.selectedFilter,
    required this.totalCount,
    required this.paidCount,
    required this.pendingCount,
    required this.dueSoonCount,
    required this.overdueCount,
    required this.onChanged,
  });

  final BillStatusFilter selectedFilter;
  final int totalCount;
  final int paidCount;
  final int pendingCount;
  final int dueSoonCount;
  final int overdueCount;
  final ValueChanged<BillStatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = [
      _FilterData(
        filter: BillStatusFilter.all,
        label: 'All',
        count: totalCount,
        icon: Icons.list_alt_outlined,
        color: const Color(0xFF2563EB),
      ),
      _FilterData(
        filter: BillStatusFilter.paid,
        label: 'Paid',
        count: paidCount,
        icon: Icons.check_circle_outline,
        color: const Color(0xFF16A34A),
      ),
      _FilterData(
        filter: BillStatusFilter.pending,
        label: 'Pending',
        count: pendingCount,
        icon: Icons.schedule_outlined,
        color: const Color(0xFFF59E0B),
      ),
      _FilterData(
        filter: BillStatusFilter.dueSoon,
        label: 'Due Soon',
        count: dueSoonCount,
        icon: Icons.notifications_active_outlined,
        color: const Color(0xFF7C3AED),
      ),
      _FilterData(
        filter: BillStatusFilter.overdue,
        label: 'Overdue',
        count: overdueCount,
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFDC2626),
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

class _FilterData {
  const _FilterData({
    required this.filter,
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final BillStatusFilter filter;
  final String label;
  final int count;
  final IconData icon;
  final Color color;
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.20),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.94),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -60,
              top: -70,
              child: _HeaderGlow(
                size: 170,
                color: const Color(0xFF06B6D4),
              ),
            ),
            Positioned(
              left: -70,
              bottom: -90,
              child: _HeaderGlow(
                size: 180,
                color: const Color(0xFF2563EB),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 720;

                final titleBlock = Row(
                  children: [
                    _HeaderBackButton(onTap: onBack),
                    const SizedBox(width: 14),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white.withOpacity(0.12),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Manage household bills, due dates, paid/unpaid status, and reminders.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final badge = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Premium Workspace',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: titleBlock),
                      const SizedBox(width: 14),
                      badge,
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: 14),
                    badge,
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

class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _HeaderGlow extends StatelessWidget {
  const _HeaderGlow({
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

class _TotalBillsCard extends StatelessWidget {
  const _TotalBillsCard({
    required this.totalBills,
    required this.unpaidBills,
    required this.currency,
  });

  final double totalBills;
  final double unpaidBills;
  final CurrencyProvider currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bills Overview',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currency.formatAmount(totalBills),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unpaid amount: ${currency.formatAmount(unpaidBills)}',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({
    required this.item,
    required this.currency,
    required this.reminder,
    required this.isOverdue,
    required this.isDueSoon,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final BillRecord item;
  final CurrencyProvider currency;
  final ReminderProvider reminder;
  final bool isOverdue;
  final bool isDueSoon;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  String readableDate(String value) {
    final parsed = DateTime.tryParse(value);

    if (parsed == null) return value;

    final months = const [
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

  String dueStatusText() {
    if (item.isPaid) return 'Paid';
    if (isOverdue) return 'Overdue';
    if (isDueSoon) return 'Due Soon';

    return 'Pending';
  }

  Color dueStatusColor() {
    if (item.isPaid) return const Color(0xFF16A34A);
    if (isOverdue) return const Color(0xFFDC2626);
    if (isDueSoon) return const Color(0xFF7C3AED);

    return const Color(0xFFF59E0B);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = dueStatusColor();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOverdue
              ? const Color(0xFFFECACA)
              : isDueSoon
                  ? const Color(0xFFDDD6FE)
                  : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.12),
                      child: Icon(
                        item.isPaid
                            ? Icons.check_circle_outline
                            : isOverdue
                                ? Icons.warning_amber_rounded
                                : isDueSoon
                                    ? Icons.notifications_active_outlined
                                    : Icons.schedule_outlined,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _BillTextInfo(
                        item: item,
                        readableDate: readableDate(item.dueDate),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InkWell(
                      onTap: onToggle,
                      borderRadius: BorderRadius.circular(30),
                      child: _StatusPill(
                        label: item.status,
                        color: item.isPaid
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                    _StatusPill(
                      label: dueStatusText(),
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      currency.formatAmount(item.amount),
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
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
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.12),
                child: Icon(
                  item.isPaid
                      ? Icons.check_circle_outline
                      : isOverdue
                          ? Icons.warning_amber_rounded
                          : isDueSoon
                              ? Icons.notifications_active_outlined
                              : Icons.schedule_outlined,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _BillTextInfo(
                      item: item,
                      readableDate: readableDate(item.dueDate),
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(30),
                child: _StatusPill(
                  label: item.status,
                  color: item.isPaid
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(
                label: dueStatusText(),
                color: statusColor,
              ),
              const SizedBox(width: 12),
              Text(
                currency.formatAmount(item.amount),
                style: const TextStyle(
                  color: Color(0xFF2563EB),
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
    );
  }
}

class _BillTextInfo extends StatelessWidget {
  const _BillTextInfo({
    required this.item,
    required this.readableDate,
  });

  final BillRecord item;
  final String readableDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${item.category} • Due: $readableDate',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ReminderHintCard extends StatelessWidget {
  const _ReminderHintCard({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            color: Color(0xFF2563EB),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.title,
    required this.readableDate,
    required this.savedDate,
    required this.color,
    required this.onTap,
  });

  final String title;
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
                      '$title: $readableDate',
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({
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
        vertical: 8,
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
          fontSize: 12,
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

class _AppField extends StatelessWidget {
  const _AppField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
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
    errorMaxLines: 2,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: Color(0xFF2563EB),
        width: 1.4,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: Color(0xFFDC2626),
        width: 1.2,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: Color(0xFFDC2626),
        width: 1.4,
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No bills found',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}