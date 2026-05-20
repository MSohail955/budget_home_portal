import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/currency_provider.dart';
import '../../../core/providers/finance_provider.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final searchController = TextEditingController();

  String search = '';

  List<BillRecord> getFilteredBills(List<BillRecord> bills) {
    if (search.trim().isEmpty) return bills;

    return bills.where((item) {
      final value = search.toLowerCase();

      return item.title.toLowerCase().contains(value) ||
          item.category.toLowerCase().contains(value) ||
          item.dueDate.toLowerCase().contains(value) ||
          item.status.toLowerCase().contains(value) ||
          item.amount.toString().contains(value);
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

  void openBillSheet({BillRecord? existingBill}) {
    final isEdit = existingBill != null;

    final titleController = TextEditingController(
      text: existingBill?.title ?? '',
    );

    final amountController = TextEditingController(
      text: existingBill == null ? '' : existingBill.amount.toStringAsFixed(0),
    );

    String selectedCategory = existingBill?.category ?? 'Electricity';
    bool isPaid = existingBill?.isPaid ?? false;
    DateTime selectedDueDate = parseSavedDate(existingBill?.dueDate ?? '');

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
                        ),
                        const SizedBox(height: 14),
                        _AppField(
                          controller: amountController,
                          hint: 'Amount',
                          icon: Icons.payments_outlined,
                          keyboardType: TextInputType.number,
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
                          onChanged: (value) {
                            setSheetState(() {
                              selectedCategory = value ?? 'Electricity';
                            });
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
                              final title = titleController.text.trim();
                              final amount =
                                  double.tryParse(amountController.text.trim()) ??
                                      0;

                              if (title.isEmpty || amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter valid bill data'),
                                  ),
                                );
                                return;
                              }

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
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final finance = context.watch<FinanceProvider>();
    final items = getFilteredBills(finance.bills);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                    const _EmptyState()
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

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
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
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final BillRecord item;
  final CurrencyProvider currency;
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

  @override
  Widget build(BuildContext context) {
    final statusColor =
        item.isPaid ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(30),
                  child: _StatusPill(
                    label: item.status,
                    color: statusColor,
                  ),
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
                  color: statusColor,
                ),
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
  const _EmptyState();

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
            'Add your first bill to start tracking.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}