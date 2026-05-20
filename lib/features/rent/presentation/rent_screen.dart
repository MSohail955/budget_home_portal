import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/currency_provider.dart';
import '../../../core/providers/finance_provider.dart';

class RentScreen extends StatefulWidget {
  const RentScreen({super.key});

  @override
  State<RentScreen> createState() => _RentScreenState();
}

class _RentScreenState extends State<RentScreen> {
  final searchController = TextEditingController();

  String search = '';

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

  List<String> get years {
    final currentYear = DateTime.now().year;

    return [
      for (int year = currentYear - 5; year <= currentYear + 5; year++)
        year.toString(),
    ];
  }

  List<RentRecord> getFilteredRents(List<RentRecord> rents) {
    if (search.trim().isEmpty) return rents;

    return rents.where((item) {
      final value = search.toLowerCase();

      return item.propertyName.toLowerCase().contains(value) ||
          item.tenantName.toLowerCase().contains(value) ||
          item.month.toLowerCase().contains(value) ||
          item.year.toLowerCase().contains(value) ||
          item.dueDate.toLowerCase().contains(value) ||
          item.paymentDate.toLowerCase().contains(value) ||
          item.notes.toLowerCase().contains(value) ||
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
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> pickDate({
    required DateTime selectedDate,
    required String helpText,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime(DateTime.now().year + 10),
      helpText: helpText,
    );

    if (pickedDate == null) return;

    onPicked(pickedDate);
  }

  void openRentSheet({RentRecord? existingRent}) {
    final isEdit = existingRent != null;

    final propertyController = TextEditingController(
      text: existingRent?.propertyName ?? '',
    );

    final tenantController = TextEditingController(
      text: existingRent?.tenantName ?? '',
    );

    final amountController = TextEditingController(
      text: existingRent == null ? '' : existingRent.amount.toStringAsFixed(0),
    );

    final notesController = TextEditingController(
      text: existingRent?.notes ?? '',
    );

    DateTime selectedDueDate = parseSavedDate(existingRent?.dueDate ?? '');
    DateTime? selectedPaymentDate =
        existingRent?.paymentDate.trim().isEmpty ?? true
            ? null
            : parseSavedDate(existingRent?.paymentDate ?? '');

    String selectedMonth = existingRent?.month ?? months[selectedDueDate.month - 1];
    String selectedYear = existingRent?.year ?? selectedDueDate.year.toString();
    bool isPaid = existingRent?.isPaid ?? false;

    if (!months.contains(selectedMonth)) {
      selectedMonth = months[selectedDueDate.month - 1];
    }

    if (!years.contains(selectedYear)) {
      selectedYear = DateTime.now().year.toString();
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
                          isEdit ? 'Edit Rent Record' : 'Add Rent Record',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isEdit
                              ? 'Update tenant rent details and payment status.'
                              : 'Track tenant rent, due date, and paid/unpaid status.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 20),
                        _AppField(
                          controller: propertyController,
                          hint: 'Property name',
                          icon: Icons.home_work_outlined,
                        ),
                        const SizedBox(height: 14),
                        _AppField(
                          controller: tenantController,
                          hint: 'Tenant name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 14),
                        _AppField(
                          controller: amountController,
                          hint: 'Amount',
                          icon: Icons.payments_outlined,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedMonth,
                                decoration: _inputDecoration(
                                  'Rent Month',
                                  Icons.calendar_month_outlined,
                                ),
                                items: months.map((item) {
                                  return DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setSheetState(() {
                                    selectedMonth = value ?? selectedMonth;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedYear,
                                decoration: _inputDecoration(
                                  'Rent Year',
                                  Icons.date_range_outlined,
                                ),
                                items: years.map((item) {
                                  return DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setSheetState(() {
                                    selectedYear = value ?? selectedYear;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _DatePickerField(
                          title: 'Due Date',
                          readableDate: readableDate(selectedDueDate),
                          savedDate: formatDate(selectedDueDate),
                          color: const Color(0xFF7C3AED),
                          onTap: () {
                            pickDate(
                              selectedDate: selectedDueDate,
                              helpText: 'Select rent due date',
                              onPicked: (pickedDate) {
                                setSheetState(() {
                                  selectedDueDate = pickedDate;
                                  selectedMonth = months[pickedDate.month - 1];
                                  selectedYear = pickedDate.year.toString();
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
                                  ? 'This rent is already collected.'
                                  : 'This rent is still pending.',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                              ),
                            ),
                            onChanged: (value) {
                              setSheetState(() {
                                isPaid = value;

                                if (isPaid) {
                                  selectedPaymentDate ??= DateTime.now();
                                } else {
                                  selectedPaymentDate = null;
                                }
                              });
                            },
                          ),
                        ),
                        if (isPaid) ...[
                          const SizedBox(height: 14),
                          _DatePickerField(
                            title: 'Payment Date',
                            readableDate: readableDate(
                              selectedPaymentDate ?? DateTime.now(),
                            ),
                            savedDate: formatDate(
                              selectedPaymentDate ?? DateTime.now(),
                            ),
                            color: const Color(0xFF16A34A),
                            onTap: () {
                              pickDate(
                                selectedDate:
                                    selectedPaymentDate ?? DateTime.now(),
                                helpText: 'Select rent payment date',
                                onPicked: (pickedDate) {
                                  setSheetState(() {
                                    selectedPaymentDate = pickedDate;
                                  });
                                },
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 14),
                        _AppField(
                          controller: notesController,
                          hint: 'Notes optional',
                          icon: Icons.notes_outlined,
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: () {
                              final property = propertyController.text.trim();
                              final tenant = tenantController.text.trim();
                              final notes = notesController.text.trim();
                              final amount =
                                  double.tryParse(amountController.text.trim()) ??
                                      0;

                              if (property.isEmpty ||
                                  tenant.isEmpty ||
                                  amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter valid rent data'),
                                  ),
                                );
                                return;
                              }

                              final newRecord = RentRecord(
                                propertyName: property,
                                tenantName: tenant,
                                amount: amount,
                                month: selectedMonth,
                                year: selectedYear,
                                dueDate: formatDate(selectedDueDate),
                                isPaid: isPaid,
                                paymentDate: isPaid
                                    ? formatDate(
                                        selectedPaymentDate ?? DateTime.now(),
                                      )
                                    : '',
                                notes: notes,
                              );

                              if (isEdit) {
                                context.read<FinanceProvider>().updateRent(
                                      oldRecord: existingRent,
                                      newRecord: newRecord,
                                    );
                              } else {
                                context.read<FinanceProvider>().addRent(
                                      newRecord,
                                    );
                              }

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEdit
                                        ? 'Rent record updated successfully'
                                        : 'Rent record added successfully',
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              isEdit ? 'Update Rent' : 'Save Rent',
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

  void toggleStatus(RentRecord item) {
    context.read<FinanceProvider>().toggleRentStatus(item);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          item.isPaid ? 'Rent marked as paid' : 'Rent marked as unpaid',
        ),
      ),
    );
  }

  void deleteRent(RentRecord item) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Rent'),
          content: Text(
            'Are you sure you want to delete rent record for "${item.tenantName}"?',
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
                context.read<FinanceProvider>().deleteRent(item);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rent record deleted')),
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
    final items = getFilteredRents(finance.rents);

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
                    title: 'Rent',
                    onBack: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => openRentSheet(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Rent'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _RentOverviewCard(
                    totalRent: finance.totalRent,
                    collectedRent: finance.rentCollected,
                    pendingRent: finance.pendingRent,
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
                      hintText: 'Search rent records...',
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

                        return _RentCard(
                          item: item,
                          currency: currency,
                          onEdit: () => openRentSheet(existingRent: item),
                          onToggle: () => toggleStatus(item),
                          onDelete: () => deleteRent(item),
                          readableDate: readableDate,
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
        IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
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

class _RentOverviewCard extends StatelessWidget {
  const _RentOverviewCard({
    required this.totalRent,
    required this.collectedRent,
    required this.pendingRent,
    required this.currency,
  });

  final double totalRent;
  final double collectedRent;
  final double pendingRent;
  final CurrencyProvider currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rent Overview',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currency.formatAmount(totalRent),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniPill(
                label: 'Collected: ${currency.formatAmount(collectedRent)}',
                icon: Icons.check_circle_outline,
              ),
              _MiniPill(
                label: 'Pending: ${currency.formatAmount(pendingRent)}',
                icon: Icons.schedule_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RentCard extends StatelessWidget {
  const _RentCard({
    required this.item,
    required this.currency,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.readableDate,
  });

  final RentRecord item;
  final CurrencyProvider currency;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final String Function(DateTime date) readableDate;

  String displaySavedDate(String value) {
    final parsed = DateTime.tryParse(value);

    if (parsed == null) return value;

    return readableDate(parsed);
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
                            : Icons.home_work_outlined,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _RentTextInfo(
                        item: item,
                        dueDate: displaySavedDate(item.dueDate),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(30),
                  child: _StatusPill(label: item.status, color: statusColor),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      currency.formatAmount(item.amount),
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
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
                      : Icons.home_work_outlined,
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
                    child: _RentTextInfo(
                      item: item,
                      dueDate: displaySavedDate(item.dueDate),
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(30),
                child: _StatusPill(label: item.status, color: statusColor),
              ),
              const SizedBox(width: 12),
              Text(
                currency.formatAmount(item.amount),
                style: const TextStyle(
                  color: Color(0xFF7C3AED),
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

class _RentTextInfo extends StatelessWidget {
  const _RentTextInfo({
    required this.item,
    required this.dueDate,
  });

  final RentRecord item;
  final String dueDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.propertyName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${item.tenantName} • ${item.month} ${item.year} • Due: $dueDate',
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
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
              Icon(Icons.edit_calendar_outlined, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          child: Icon(icon, color: color, size: 20),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
            Icons.home_work_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No rent records found',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first rent record to start tracking.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}