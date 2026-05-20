import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/currency_provider.dart';
import '../../../core/providers/finance_provider.dart';
import '../../../core/providers/reminder_provider.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final searchController = TextEditingController();

  String search = '';

  List<LoanRecord> getFilteredLoans(List<LoanRecord> loans) {
    if (search.trim().isEmpty) return loans;

    return loans.where((item) {
      final value = search.toLowerCase();

      return item.personName.toLowerCase().contains(value) ||
          item.loanType.toLowerCase().contains(value) ||
          item.loanPurpose.toLowerCase().contains(value) ||
          item.date.toLowerCase().contains(value) ||
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

  String loanReminderText(ReminderProvider reminder) {
    if (!reminder.loanRemindersEnabled) {
      return 'Loan reminders are currently disabled in Reminder Settings.';
    }

    return 'Loan reminder will show ${reminder.remindBeforeDays} days before this due date using ${reminder.reminderChannel}.';
  }

  Future<void> pickLoanDate({
    required DateTime selectedDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime(DateTime.now().year + 10),
      helpText: 'Select loan due date',
    );

    if (pickedDate == null) return;

    onPicked(pickedDate);
  }

  void openLoanSheet({LoanRecord? existingLoan}) {
    final isEdit = existingLoan != null;

    final personController = TextEditingController(
      text: existingLoan?.personName ?? '',
    );

    final amountController = TextEditingController(
      text: existingLoan == null ? '' : existingLoan.amount.toStringAsFixed(0),
    );

    final notesController = TextEditingController(
      text: existingLoan?.notes ?? '',
    );

    String selectedLoanType = existingLoan?.loanType ?? 'Given';
    String selectedPurpose = existingLoan?.loanPurpose ?? 'Personal';
    bool isPaid = existingLoan?.isPaid ?? false;
    DateTime selectedDate = parseSavedDate(existingLoan?.date ?? '');

    final loanTypes = const [
      'Taken',
      'Given',
    ];

    final purposes = const [
      'Car',
      'Home',
      'Medical',
      'Education',
      'Business',
      'Personal',
      'Other',
    ];

    if (!loanTypes.contains(selectedLoanType)) {
      selectedLoanType = 'Given';
    }

    if (!purposes.contains(selectedPurpose)) {
      selectedPurpose = 'Personal';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final reminder = context.watch<ReminderProvider>();

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
                          isEdit ? 'Edit Loan' : 'Add Loan',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isEdit
                              ? 'Update loan details, due date, and payment status.'
                              : 'Track loans taken or given with due date reminders.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 20),
                        _AppField(
                          controller: personController,
                          hint: 'Person name',
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
                                value: selectedLoanType,
                                decoration: _inputDecoration(
                                  'Loan type',
                                  Icons.swap_vert_circle_outlined,
                                ),
                                items: loanTypes.map((item) {
                                  return DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setSheetState(() {
                                    selectedLoanType = value ?? 'Given';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedPurpose,
                                decoration: _inputDecoration(
                                  'Purpose',
                                  Icons.category_outlined,
                                ),
                                items: purposes.map((item) {
                                  return DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setSheetState(() {
                                    selectedPurpose = value ?? 'Personal';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _ReminderHintCard(
                          text: loanReminderText(reminder),
                        ),
                        const SizedBox(height: 14),
                        _DatePickerField(
                          title: 'Due Date / Reminder Date',
                          readableDate: readableDate(selectedDate),
                          savedDate: formatDate(selectedDate),
                          onTap: () {
                            pickLoanDate(
                              selectedDate: selectedDate,
                              onPicked: (pickedDate) {
                                setSheetState(() {
                                  selectedDate = pickedDate;
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
                                  ? 'This loan is fully paid.'
                                  : 'This loan is still pending.',
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
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: () {
                              final person = personController.text.trim();
                              final notes = notesController.text.trim();
                              final amount =
                                  double.tryParse(amountController.text.trim()) ??
                                      0;

                              if (person.isEmpty || amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Please enter valid loan data'),
                                  ),
                                );
                                return;
                              }

                              final newRecord = LoanRecord(
                                personName: person,
                                loanType: selectedLoanType,
                                loanPurpose: selectedPurpose,
                                amount: amount,
                                date: formatDate(selectedDate),
                                isPaid: isPaid,
                                notes: notes,
                              );

                              if (isEdit) {
                                context.read<FinanceProvider>().updateLoan(
                                      oldRecord: existingLoan,
                                      newRecord: newRecord,
                                    );
                              } else {
                                context.read<FinanceProvider>().addLoan(
                                      newRecord,
                                    );
                              }

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEdit
                                        ? 'Loan updated successfully'
                                        : 'Loan added successfully',
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              isEdit ? 'Update Loan' : 'Save Loan',
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

  void toggleStatus(LoanRecord item) {
    context.read<FinanceProvider>().toggleLoanStatus(item);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          item.isPaid ? 'Loan marked as paid' : 'Loan marked as pending',
        ),
      ),
    );
  }

  void deleteLoan(LoanRecord item) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Loan'),
          content: Text(
            'Are you sure you want to delete loan record for "${item.personName}"?',
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
                context.read<FinanceProvider>().deleteLoan(item);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loan deleted')),
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
    final items = getFilteredLoans(finance.loans);

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
                    title: 'Loans',
                    onBack: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => openLoanSheet(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Loan'),
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
                  _LoansOverviewCard(
                    totalLoans: finance.totalLoans,
                    pendingLoans: finance.pendingLoans,
                    paidLoans: finance.paidLoans,
                    givenLoans: finance.givenLoans,
                    takenLoans: finance.takenLoans,
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
                      hintText: 'Search loans...',
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

                        return _LoanCard(
                          item: item,
                          currency: currency,
                          onEdit: () => openLoanSheet(existingLoan: item),
                          onToggle: () => toggleStatus(item),
                          onDelete: () => deleteLoan(item),
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

class _LoansOverviewCard extends StatelessWidget {
  const _LoansOverviewCard({
    required this.totalLoans,
    required this.pendingLoans,
    required this.paidLoans,
    required this.givenLoans,
    required this.takenLoans,
    required this.currency,
  });

  final double totalLoans;
  final double pendingLoans;
  final double paidLoans;
  final double givenLoans;
  final double takenLoans;
  final CurrencyProvider currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Loans Overview',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currency.formatAmount(totalLoans),
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
                label: 'Pending: ${currency.formatAmount(pendingLoans)}',
                icon: Icons.schedule_outlined,
              ),
              _MiniPill(
                label: 'Paid: ${currency.formatAmount(paidLoans)}',
                icon: Icons.check_circle_outline,
              ),
              _MiniPill(
                label: 'Given: ${currency.formatAmount(givenLoans)}',
                icon: Icons.north_east_outlined,
              ),
              _MiniPill(
                label: 'Taken: ${currency.formatAmount(takenLoans)}',
                icon: Icons.south_west_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({
    required this.item,
    required this.currency,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final LoanRecord item;
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

    final typeColor = item.loanType == 'Given'
        ? const Color(0xFF2563EB)
        : const Color(0xFF7C3AED);

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
                      backgroundColor: typeColor.withOpacity(0.12),
                      child: Icon(
                        item.loanType == 'Given'
                            ? Icons.north_east_outlined
                            : Icons.south_west_outlined,
                        color: typeColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _LoanTextInfo(
                        item: item,
                        readableDate: readableDate(item.date),
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
                        color: Color(0xFFF59E0B),
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
                backgroundColor: typeColor.withOpacity(0.12),
                child: Icon(
                  item.loanType == 'Given'
                      ? Icons.north_east_outlined
                      : Icons.south_west_outlined,
                  color: typeColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _LoanTextInfo(
                      item: item,
                      readableDate: readableDate(item.date),
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
                  color: Color(0xFFF59E0B),
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

class _LoanTextInfo extends StatelessWidget {
  const _LoanTextInfo({
    required this.item,
    required this.readableDate,
  });

  final LoanRecord item;
  final String readableDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.personName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${item.loanType} • ${item.loanPurpose} • Due: $readableDate',
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
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF92400E),
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
    required this.onTap,
  });

  final String title;
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
                      'Saved as $savedDate for reports and reminders',
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
                color: Color(0xFFF59E0B),
              ),
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
            Icons.handshake_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No loans found',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first loan record to start tracking.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}