import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/providers/finance_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/reminder_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void openProfileSheet(BuildContext context) {
    final profile = context.read<ProfileProvider>();

    final nameController = TextEditingController(text: profile.name);
    final emailController = TextEditingController(text: profile.email);
    final phoneController = TextEditingController(text: profile.phone);
    final addressController = TextEditingController(text: profile.address);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _SheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetTitle(
                title: 'Profile Information',
                subtitle: 'Update your personal profile details.',
              ),
              const SizedBox(height: 20),
              _AppField(
                controller: nameController,
                hint: 'Full name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              _AppField(
                controller: emailController,
                hint: 'Email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _AppField(
                controller: phoneController,
                hint: 'Phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _AppField(
                controller: addressController,
                hint: 'Address / Country',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    final phone = phoneController.text.trim();
                    final address = addressController.text.trim();

                    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter name, email, and phone'),
                        ),
                      );
                      return;
                    }

                    await context.read<ProfileProvider>().updateProfile(
                          name: name,
                          email: email,
                          phone: phone,
                          address: address.isEmpty ? 'Not provided' : address,
                        );

                    if (!context.mounted) return;

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully'),
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
  }

  void openChangePasswordSheet(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _SheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetTitle(
                title: 'Change Password',
                subtitle: 'Update your account password securely.',
              ),
              const SizedBox(height: 20),
              _AppField(
                controller: currentPasswordController,
                hint: 'Current password',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 14),
              _AppField(
                controller: newPasswordController,
                hint: 'New password',
                icon: Icons.lock_reset_outlined,
                obscureText: true,
              ),
              const SizedBox(height: 14),
              _AppField(
                controller: confirmPasswordController,
                hint: 'Confirm new password',
                icon: Icons.verified_user_outlined,
                obscureText: true,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.password_outlined),
                  label: const Text('Update Password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () async {
                    final result =
                        await context.read<AuthProvider>().changePassword(
                              currentPassword: currentPasswordController.text,
                              newPassword: newPasswordController.text,
                              confirmPassword: confirmPasswordController.text,
                            );

                    if (!context.mounted) return;

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result.message)),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void openReminderSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _SheetContainer(
          child: Consumer<ReminderProvider>(
            builder: (context, reminder, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SheetTitle(
                    title: 'Reminder Settings',
                    subtitle:
                        'Set smart reminders for bills, school fees, rent collection, and loans.',
                  ),
                  const SizedBox(height: 20),
                  _ReminderSwitchCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Bill Reminders',
                    subtitle: reminder.generalReminderText,
                    color: const Color(0xFF2563EB),
                    value: reminder.billRemindersEnabled,
                    onChanged: reminder.toggleBillReminders,
                  ),
                  const SizedBox(height: 14),
                  _ReminderDayCard(
                    icon: Icons.wifi_outlined,
                    title: 'Internet Bill',
                    subtitle: reminder.internetReminderText,
                    color: const Color(0xFF2563EB),
                    value: reminder.internetBillDay,
                    onChanged: reminder.changeInternetBillDay,
                  ),
                  const SizedBox(height: 14),
                  _ReminderDayCard(
                    icon: Icons.school_outlined,
                    title: 'School Fees',
                    subtitle: reminder.schoolFeesReminderText,
                    color: const Color(0xFF16A34A),
                    value: reminder.schoolFeesDay,
                    onChanged: reminder.changeSchoolFeesDay,
                  ),
                  const SizedBox(height: 14),
                  _ReminderDayCard(
                    icon: Icons.electric_bolt_outlined,
                    title: 'Electricity Bill',
                    subtitle: reminder.electricityReminderText,
                    color: const Color(0xFFF59E0B),
                    value: reminder.electricityBillDay,
                    onChanged: reminder.changeElectricityBillDay,
                  ),
                  const SizedBox(height: 14),
                  _ReminderSwitchCard(
                    icon: Icons.home_work_outlined,
                    title: 'Rent Collection Reminders',
                    subtitle: reminder.rentReminderText,
                    color: const Color(0xFF7C3AED),
                    value: reminder.rentRemindersEnabled,
                    onChanged: reminder.toggleRentReminders,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _SmallNumberPicker(
                          label: 'Rent Start Day',
                          value: reminder.rentReminderStartDay,
                          min: 1,
                          max: 31,
                          onChanged: reminder.changeRentStartDay,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SmallNumberPicker(
                          label: 'Rent End Day',
                          value: reminder.rentReminderEndDay,
                          min: 1,
                          max: 31,
                          onChanged: reminder.changeRentEndDay,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ReminderSwitchCard(
                    icon: Icons.handshake_outlined,
                    title: 'Loan Reminders',
                    subtitle: 'Remind before selected loan due date.',
                    color: const Color(0xFFEF4444),
                    value: reminder.loanRemindersEnabled,
                    onChanged: reminder.toggleLoanReminders,
                  ),
                  const SizedBox(height: 14),
                  _SmallNumberPicker(
                    label: 'Remind Before Days',
                    value: reminder.remindBeforeDays,
                    min: 0,
                    max: 15,
                    onChanged: reminder.changeRemindBeforeDays,
                  ),
                  const SizedBox(height: 14),
                  _ReminderChannelPicker(reminder: reminder),
                  const SizedBox(height: 14),
                  _ReminderSwitchCard(
                    icon: Icons.analytics_outlined,
                    title: 'Monthly Summary',
                    subtitle:
                        'Monthly summary reminder for income and expenses.',
                    color: const Color(0xFF0F172A),
                    value: reminder.monthlySummaryEnabled,
                    onChanged: reminder.toggleMonthlySummary,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset Default Reminder Settings'),
                      onPressed: reminder.resetDefaults,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Note: In-app reminders are configured now. Email/SMS sending needs backend integration in the next version.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void openReminderContactSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _SheetContainer(
          child: Consumer2<ProfileProvider, ReminderProvider>(
            builder: (context, profile, reminder, _) {
              final email = profile.email.trim().isEmpty
                  ? 'No email added'
                  : profile.email.trim();

              final phone = profile.phone.trim().isEmpty
                  ? 'No phone number added'
                  : profile.phone.trim();

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SheetTitle(
                    title: 'Reminder Contact Setup',
                    subtitle:
                        'Review the email and phone number used for future reminder delivery.',
                  ),
                  const SizedBox(height: 20),
                  _ReminderContactCard(
                    icon: Icons.email_outlined,
                    title: 'Registered Email',
                    value: email,
                    subtitle:
                        'Email reminders will be sent to this address after backend integration.',
                    color: const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 14),
                  _ReminderContactCard(
                    icon: Icons.phone_outlined,
                    title: 'Registered Phone',
                    value: phone,
                    subtitle:
                        'SMS or phone reminders will use this number after backend integration.',
                    color: const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 14),
                  _ReminderContactCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'Preferred Reminder Channel',
                    value: reminder.reminderChannel,
                    subtitle:
                        'You can change this from Reminder Settings anytime.',
                    color: const Color(0xFF7C3AED),
                  ),
                  const SizedBox(height: 14),
                  _TestReminderPreviewCard(
                    reminder: reminder,
                    profile: profile,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Preview Test Reminder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Test reminder preview ready for ${reminder.reminderChannel}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Profile Contact Details'),
                      onPressed: () {
                        Navigator.pop(context);
                        openProfileSheet(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Note: This screen prepares reminder contact details. Actual email/SMS sending needs backend service such as SMTP, Firebase Functions, Twilio, or another provider.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void openAboutAppSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _SheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetTitle(
                title: 'About Budget Home Portal',
                subtitle:
                    'A smart home finance management app for bills, rent, loans, income, expenses, reports, and reminders.',
              ),
              const SizedBox(height: 20),
              const _AboutInfoCard(
                icon: Icons.apps_outlined,
                title: 'App Version',
                value: '1.0.0 Frontend Preview',
                color: Color(0xFF2563EB),
              ),
              const SizedBox(height: 14),
              const _AboutInfoCard(
                icon: Icons.storage_outlined,
                title: 'Data Storage',
                value:
                    'Your current data is stored locally in the app. Backend and database integration will be added in the next phase.',
                color: Color(0xFF16A34A),
              ),
              const SizedBox(height: 14),
              const _AboutInfoCard(
                icon: Icons.notifications_active_outlined,
                title: 'Reminder System',
                value:
                    'In-app reminder calculations are available now. Real email/SMS notifications require backend scheduler integration.',
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(height: 14),
              const _AboutInfoCard(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Note',
                value:
                    'This frontend version does not send your finance records to any server. Exported backup files should be kept safely.',
                color: Color(0xFF7C3AED),
              ),
              const SizedBox(height: 14),
              const _AboutInfoCard(
                icon: Icons.engineering_outlined,
                title: 'Next Production Step',
                value:
                    'Backend API, secure authentication, database, cloud backup, and real notification delivery.',
                color: Color(0xFF0F172A),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Got it'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
            'Are you sure you want to clear all your saved finance records? This will remove your expenses, income, bills, rent, and loans for this account.',
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
              onPressed: () async {
                await context.read<FinanceProvider>().resetAllData();

                if (!context.mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All finance records have been cleared'),
                  ),
                );
              },
              child: const Text('Clear Data'),
            ),
          ],
        );
      },
    );
  }

  void confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout from this account?',
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
              onPressed: () async {
                await context.read<AuthProvider>().logout();

                if (!context.mounted) return;

                Navigator.pop(context);
                context.go('/login');
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete this account? This will remove your account, profile, and all saved finance records.',
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
              onPressed: () async {
                final result =
                    await context.read<AuthProvider>().deleteCurrentAccount();

                if (!context.mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.message)),
                );

                if (result.success) {
                  context.go('/login');
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  String buildJsonExport({
    required FinanceProvider finance,
    required ReminderProvider reminder,
    required ProfileProvider profile,
    required CurrencyProvider currency,
  }) {
    final data = {
      'expenses': finance.expenses.map((item) => item.toJson()).toList(),
      'incomes': finance.incomes.map((item) => item.toJson()).toList(),
      'bills': finance.bills.map((item) => item.toJson()).toList(),
      'rents': finance.rents.map((item) => item.toJson()).toList(),
      'loans': finance.loans.map((item) => item.toJson()).toList(),
      'reminderSettings': reminder.toJson(),
      'profileContact': {
        'name': profile.name,
        'email': profile.email,
        'phone': profile.phone,
        'address': profile.address,
      },
      'currency': {
        'code': currency.currencyCode,
      },
      'exportedAt': DateTime.now().toIso8601String(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  String cleanCsvValue(Object? value) {
    final text = value?.toString() ?? '';
    final escaped = text.replaceAll('"', '""');
    return '"$escaped"';
  }

  String buildCsvExport({
    required FinanceProvider finance,
    required ReminderProvider reminder,
    required ProfileProvider profile,
    required CurrencyProvider currency,
  }) {
    final rows = <List<Object?>>[
      [
        'Type',
        'Title/Name',
        'Category/Purpose',
        'Amount',
        'Date/Due Date',
        'Status',
        'Extra',
      ],
    ];

    for (final item in finance.expenses) {
      rows.add([
        'Expense',
        item.title,
        item.category,
        item.amount,
        item.date,
        item.paymentMethod,
        '',
      ]);
    }

    for (final item in finance.incomes) {
      rows.add([
        'Income',
        item.title,
        item.category,
        item.amount,
        item.date,
        item.source,
        '',
      ]);
    }

    for (final item in finance.bills) {
      rows.add([
        'Bill',
        item.title,
        item.category,
        item.amount,
        item.dueDate,
        item.status,
        '',
      ]);
    }

    for (final item in finance.rents) {
      rows.add([
        'Rent',
        item.propertyName,
        item.tenantName,
        item.amount,
        item.dueDate,
        item.status,
        '${item.month} ${item.year} | ${item.notes}',
      ]);
    }

    for (final item in finance.loans) {
      rows.add([
        'Loan',
        item.personName,
        item.loanPurpose,
        item.amount,
        item.date,
        item.status,
        '${item.loanType} | ${item.notes}',
      ]);
    }

    rows.add([]);
    rows.add(['Settings', 'Name', 'Value', '', '', '', '']);

    rows.add(['Profile Contact', 'Name', profile.name, '', '', '', '']);
    rows.add(['Profile Contact', 'Email', profile.email, '', '', '', '']);
    rows.add(['Profile Contact', 'Phone', profile.phone, '', '', '', '']);
    rows.add(['Profile Contact', 'Address', profile.address, '', '', '', '']);
    rows.add(['Currency', 'Code', currency.currencyCode, '', '', '', '']);

    rows.add([
      'Reminder Setting',
      'Bill Reminders Enabled',
      reminder.billRemindersEnabled,
      '',
      '',
      '',
      '',
    ]);

    rows.add([
      'Reminder Setting',
      'Internet Bill Day',
      reminder.internetBillDay,
      '',
      '',
      '',
      '',
    ]);

    rows.add([
      'Reminder Setting',
      'School Fees Day',
      reminder.schoolFeesDay,
      '',
      '',
      '',
      '',
    ]);

    rows.add([
      'Reminder Setting',
      'Electricity Bill Day',
      reminder.electricityBillDay,
      '',
      '',
      '',
      '',
    ]);

    rows.add([
      'Reminder Setting',
      'Rent Reminders Enabled',
      reminder.rentRemindersEnabled,
      '',
      '',
      '',
      '',
    ]);

    rows.add([
      'Reminder Setting',
      'Rent Reminder Window',
      '${reminder.rentReminderStartDay} to ${reminder.rentReminderEndDay}',
      '',
      '',
      '',
      '',
    ]);

    rows.add([
      'Reminder Setting',
      'Loan Reminders Enabled',
      reminder.loanRemindersEnabled,
      '',
      '',
      '',
      '',
    ]);

    rows.add([
      'Reminder Setting',
      'Monthly Summary Enabled',
      reminder.monthlySummaryEnabled,
      '',
      '',
      '',
      '',
    ]);

    rows.add([
      'Reminder Setting',
      'Remind Before Days',
      reminder.remindBeforeDays,
      '',
      '',
      '',
      '',
    ]);

    rows.add([
      'Reminder Setting',
      'Reminder Channel',
      reminder.reminderChannel,
      '',
      '',
      '',
      '',
    ]);

    return rows.map((row) => row.map(cleanCsvValue).join(',')).join('\n');
  }

  String buildFileName(String extension) {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return 'budget_home_export_$date.$extension';
  }

  void downloadTextFile({
    required String content,
    required String fileName,
    required String mimeType,
  }) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    html.Url.revokeObjectUrl(url);
  }

  Future<void> copyToClipboard(
    BuildContext context,
    String value,
    String label,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));

    if (!context.mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  void showDownloadMessage(BuildContext context, String label) {
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label download started')),
    );
  }

  Future<void> importJsonText(
    BuildContext context,
    String jsonText,
  ) async {
    try {
      final decoded = jsonDecode(jsonText);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid backup format');
      }

      final financeSuccess =
          await context.read<FinanceProvider>().importFinanceDataFromJson(
                jsonText,
              );

      if (!context.mounted) return;

      if (!financeSuccess) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid JSON backup format'),
          ),
        );
        return;
      }

      final reminderSettings = decoded['reminderSettings'];

      if (reminderSettings is Map<String, dynamic>) {
        context.read<ReminderProvider>().importFromJson(reminderSettings);
      }

      final currencyData = decoded['currency'];

      if (currencyData is Map<String, dynamic>) {
        final code = currencyData['code']?.toString();

        if (code != null &&
            context
                .read<CurrencyProvider>()
                .availableCurrencies
                .contains(code)) {
          context.read<CurrencyProvider>().changeCurrency(code);
        }
      }

      final profileContact = decoded['profileContact'];

      if (profileContact is Map<String, dynamic>) {
        final currentProfile = context.read<ProfileProvider>();

        await currentProfile.updateProfile(
          name: profileContact['name']?.toString().trim().isNotEmpty == true
              ? profileContact['name'].toString()
              : currentProfile.name,
          email: profileContact['email']?.toString().trim().isNotEmpty == true
              ? profileContact['email'].toString()
              : currentProfile.email,
          phone: profileContact['phone']?.toString() ?? currentProfile.phone,
          address:
              profileContact['address']?.toString() ?? currentProfile.address,
        );
      }

      if (!context.mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup imported successfully with reminder settings'),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid JSON backup format'),
        ),
      );
    }
  }

  void selectAndImportJsonFile(BuildContext context) {
    final input = html.FileUploadInputElement()
      ..accept = '.json,application/json'
      ..click();

    input.onChange.listen((event) {
      final files = input.files;

      if (files == null || files.isEmpty) return;

      final file = files.first;
      final reader = html.FileReader();

      reader.onLoadEnd.listen((event) async {
        final result = reader.result;

        if (result == null) {
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to read selected file'),
            ),
          );
          return;
        }

        await importJsonText(context, result.toString());
      });

      reader.readAsText(file);
    });
  }

  void openExportSheet(BuildContext context) {
    final finance = context.read<FinanceProvider>();
    final reminder = context.read<ReminderProvider>();
    final profile = context.read<ProfileProvider>();
    final currency = context.read<CurrencyProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _SheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetTitle(
                title: 'Export Data',
                subtitle:
                    'Download or copy your finance records, reminder settings, profile contact, and currency.',
              ),
              const SizedBox(height: 20),
              _ExportOptionCard(
                icon: Icons.download_outlined,
                title: 'Download JSON File',
                subtitle: 'Best for full backup and restoring later.',
                color: const Color(0xFF2563EB),
                onTap: () {
                  downloadTextFile(
                    content: buildJsonExport(
                      finance: finance,
                      reminder: reminder,
                      profile: profile,
                      currency: currency,
                    ),
                    fileName: buildFileName('json'),
                    mimeType: 'application/json',
                  );

                  showDownloadMessage(context, 'JSON file');
                },
              ),
              const SizedBox(height: 14),
              _ExportOptionCard(
                icon: Icons.download_for_offline_outlined,
                title: 'Download CSV File',
                subtitle:
                    'Best for Excel, Google Sheets, reports, and reminder settings.',
                color: const Color(0xFF16A34A),
                onTap: () {
                  downloadTextFile(
                    content: buildCsvExport(
                      finance: finance,
                      reminder: reminder,
                      profile: profile,
                      currency: currency,
                    ),
                    fileName: buildFileName('csv'),
                    mimeType: 'text/csv',
                  );

                  showDownloadMessage(context, 'CSV file');
                },
              ),
              const SizedBox(height: 14),
              _ExportOptionCard(
                icon: Icons.data_object,
                title: 'Copy JSON Export',
                subtitle: 'Copy full backup data directly to clipboard.',
                color: const Color(0xFF7C3AED),
                onTap: () {
                  copyToClipboard(
                    context,
                    buildJsonExport(
                      finance: finance,
                      reminder: reminder,
                      profile: profile,
                      currency: currency,
                    ),
                    'JSON export',
                  );
                },
              ),
              const SizedBox(height: 14),
              _ExportOptionCard(
                icon: Icons.table_chart_outlined,
                title: 'Copy CSV Export',
                subtitle:
                    'Copy CSV records and settings directly to clipboard.',
                color: const Color(0xFFF59E0B),
                onTap: () {
                  copyToClipboard(
                    context,
                    buildCsvExport(
                      finance: finance,
                      reminder: reminder,
                      profile: profile,
                      currency: currency,
                    ),
                    'CSV export',
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Tip: JSON is best for restore. CSV is best for Excel/report review and now includes reminder settings too.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void openImportSheet(BuildContext context) {
    final importController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _SheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetTitle(
                title: 'Import JSON Backup',
                subtitle:
                    'Select a JSON backup file or paste exported JSON below.',
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.file_open_outlined),
                  label: const Text('Select JSON File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => selectAndImportJsonFile(context),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: importController,
                minLines: 8,
                maxLines: 14,
                decoration: InputDecoration(
                  hintText: 'Paste JSON backup here...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 150),
                    child: Icon(Icons.data_object),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Import Pasted JSON'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () async {
                    final jsonText = importController.text.trim();

                    if (jsonText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please paste JSON backup first'),
                        ),
                      );
                      return;
                    }

                    await importJsonText(context, jsonText);
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Important: Import will replace current saved records and restore reminder settings if available.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final finance = context.watch<FinanceProvider>();
    final profile = context.watch<ProfileProvider>();

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
                  const _SettingsHeader(),
                  const SizedBox(height: 22),
                  _ProfilePreviewCard(profile: profile),
                  const SizedBox(height: 14),
                  _QuickStatsCard(
                    totalRecords: finance.expenses.length +
                        finance.incomes.length +
                        finance.bills.length +
                        finance.rents.length +
                        finance.loans.length,
                    expenses: finance.expenses.length,
                    incomes: finance.incomes.length,
                    bills: finance.bills.length,
                    rents: finance.rents.length,
                    loans: finance.loans.length,
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    icon: Icons.person_outline,
                    title: 'Profile Information',
                    subtitle: 'Edit your name, email, phone and address.',
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => openProfileSheet(context),
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    icon: Icons.password_outlined,
                    title: 'Change Password',
                    subtitle: 'Update your login password for this account.',
                    iconColor: const Color(0xFF7C3AED),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => openChangePasswordSheet(context),
                  ),
                  const SizedBox(height: 14),
                  Container(
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
                          radius: 24,
                          backgroundColor:
                              const Color(0xFF16A34A).withOpacity(0.12),
                          child: const Icon(
                            Icons.currency_exchange,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Currency',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Default is PKR. You can change it anytime.',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: currencyProvider.currencyCode,
                              borderRadius: BorderRadius.circular(18),
                              items: currencyProvider.availableCurrencies
                                  .map(
                                    (currency) => DropdownMenuItem(
                                      value: currency,
                                      child: Text(
                                        currency,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;

                                currencyProvider.changeCurrency(value);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Currency changed to $value'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    icon: Icons.dark_mode_outlined,
                    title: 'Theme Mode',
                    subtitle: 'Light mode is active for clean visibility.',
                    trailing: const Text(
                      'Light',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dark mode will be available soon'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    icon: Icons.notifications_outlined,
                    title: 'Reminder Settings',
                    subtitle:
                        'Configure internet, school, electricity, rent and loan reminders.',
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => openReminderSettingsSheet(context),
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    icon: Icons.contact_mail_outlined,
                    title: 'Reminder Contact Setup',
                    subtitle:
                        'Review email, phone and reminder channel before backend delivery.',
                    iconColor: const Color(0xFF16A34A),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => openReminderContactSheet(context),
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    icon: Icons.backup_outlined,
                    title: 'Data Backup / Export',
                    subtitle:
                        'Download records, reminders, profile contact, and currency.',
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => openExportSheet(context),
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    icon: Icons.upload_file_outlined,
                    title: 'Import JSON Backup',
                    subtitle:
                        'Restore records and reminder settings from JSON backup.',
                    iconColor: const Color(0xFF7C3AED),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => openImportSheet(context),
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    icon: Icons.info_outline,
                    title: 'About App',
                    subtitle: 'App version, privacy note, and production roadmap.',
                    iconColor: const Color(0xFF0F172A),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => openAboutAppSheet(context),
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    icon: Icons.delete_sweep_outlined,
                    title: 'Clear All Data',
                    subtitle:
                        'Clear all your saved expenses, income, bills, rent and loans.',
                    iconColor: const Color(0xFFDC2626),
                    trailing: const Icon(
                      Icons.warning_amber_rounded,
                      size: 22,
                      color: Color(0xFFDC2626),
                    ),
                    onTap: () => confirmClearData(context),
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    icon: Icons.person_remove_outlined,
                    title: 'Delete Account',
                    subtitle:
                        'Permanently delete this account and its saved records.',
                    iconColor: const Color(0xFFDC2626),
                    trailing: const Icon(
                      Icons.warning_amber_rounded,
                      size: 22,
                      color: Color(0xFFDC2626),
                    ),
                    onTap: () => confirmDeleteAccount(context),
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    icon: Icons.logout,
                    title: 'Logout',
                    subtitle: 'Sign out from your account.',
                    iconColor: const Color(0xFFDC2626),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFFDC2626),
                    ),
                    onTap: () => confirmLogout(context),
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

class _SheetContainer extends StatelessWidget {
  const _SheetContainer({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
          top: Radius.circular(30),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _ProfilePreviewCard extends StatelessWidget {
  const _ProfilePreviewCard({
    required this.profile,
  });

  final ProfileProvider profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.name.trim().isEmpty ? 'User' : profile.name.trim();
    final email =
        profile.email.trim().isEmpty ? 'No email added' : profile.email;
    final phone = profile.phone.trim().isEmpty ? 'No phone' : profile.phone;
    final address =
        profile.address.trim().isEmpty ? 'No address' : profile.address;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.18),
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$phone • $address',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
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
                'Settings',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Manage currency, data, security and app preferences.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.currency_exchange, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  currency.currencyCode,
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

class _QuickStatsCard extends StatelessWidget {
  const _QuickStatsCard({
    required this.totalRecords,
    required this.expenses,
    required this.incomes,
    required this.bills,
    required this.rents,
    required this.loans,
  });

  final int totalRecords;
  final int expenses;
  final int incomes;
  final int bills;
  final int rents;
  final int loans;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(
                  Icons.storage_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Stored Records',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$totalRecords total records saved locally',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatsPill(label: 'Expenses: $expenses'),
              _StatsPill(label: 'Income: $incomes'),
              _StatsPill(label: 'Bills: $bills'),
              _StatsPill(label: 'Rent: $rents'),
              _StatsPill(label: 'Loans: $loans'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsPill extends StatelessWidget {
  const _StatsPill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ReminderContactCard extends StatelessWidget {
  const _ReminderContactCard({
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
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
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
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

class _TestReminderPreviewCard extends StatelessWidget {
  const _TestReminderPreviewCard({
    required this.reminder,
    required this.profile,
  });

  final ReminderProvider reminder;
  final ProfileProvider profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.name.trim().isEmpty ? 'User' : profile.name.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFDBEAFE),
            child: Icon(
              Icons.message_outlined,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Test Reminder Message',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hi $name, this is a reminder preview. Your selected reminder channel is ${reminder.reminderChannel}, and reminders will trigger ${reminder.remindBeforeDays} day(s) before the due date.',
                  style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
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

class _ReminderSwitchCard extends StatelessWidget {
  const _ReminderSwitchCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
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
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ReminderDayCard extends StatelessWidget {
  const _ReminderDayCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
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
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _DayDropdown(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DayDropdown extends StatelessWidget {
  const _DayDropdown({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: value,
        borderRadius: BorderRadius.circular(18),
        items: List.generate(31, (index) => index + 1)
            .map(
              (day) => DropdownMenuItem(
                value: day,
                child: Text(
                  day.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          onChanged(value);
        },
      ),
    );
  }
}

class _SmallNumberPicker extends StatelessWidget {
  const _SmallNumberPicker({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final values = [
      for (int item = min; item <= max; item++) item,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              borderRadius: BorderRadius.circular(18),
              items: values
                  .map(
                    (day) => DropdownMenuItem(
                      value: day,
                      child: Text(
                        day.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w900),
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
        ],
      ),
    );
  }
}

class _ReminderChannelPicker extends StatelessWidget {
  const _ReminderChannelPicker({
    required this.reminder,
  });

  final ReminderProvider reminder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFEFF6FF),
            child: Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Reminder Channel',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: reminder.reminderChannel,
              borderRadius: BorderRadius.circular(18),
              items: reminder.reminderChannels
                  .map(
                    (channel) => DropdownMenuItem(
                      value: channel,
                      child: Text(
                        channel,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                reminder.changeReminderChannel(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportOptionCard extends StatelessWidget {
  const _ExportOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDownload = icon == Icons.download_outlined ||
        icon == Icons.download_for_offline_outlined ||
        icon == Icons.file_open_outlined;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
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
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isDownload ? Icons.file_download_outlined : Icons.copy_outlined,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutInfoCard extends StatelessWidget {
  const _AboutInfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
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
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.iconColor = const Color(0xFF2563EB),
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;
  final Color iconColor;

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
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: iconColor.withOpacity(0.12),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing,
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
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}