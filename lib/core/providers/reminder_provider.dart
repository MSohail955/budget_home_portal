import 'package:flutter/material.dart';

class ReminderProvider extends ChangeNotifier {
  bool _billRemindersEnabled = true;
  bool _rentRemindersEnabled = true;
  bool _loanRemindersEnabled = true;
  bool _monthlySummaryEnabled = false;

  int _internetBillDay = 10;
  int _schoolFeesDay = 10;
  int _electricityBillDay = 28;

  int _rentReminderStartDay = 5;
  int _rentReminderEndDay = 7;

  int _remindBeforeDays = 3;

  String _reminderChannel = 'In-App';

  bool get billRemindersEnabled => _billRemindersEnabled;
  bool get rentRemindersEnabled => _rentRemindersEnabled;
  bool get loanRemindersEnabled => _loanRemindersEnabled;
  bool get monthlySummaryEnabled => _monthlySummaryEnabled;

  int get internetBillDay => _internetBillDay;
  int get schoolFeesDay => _schoolFeesDay;
  int get electricityBillDay => _electricityBillDay;

  int get rentReminderStartDay => _rentReminderStartDay;
  int get rentReminderEndDay => _rentReminderEndDay;

  int get remindBeforeDays => _remindBeforeDays;

  String get reminderChannel => _reminderChannel;

  List<String> get reminderChannels {
    return const [
      'In-App',
      'Email',
      'Phone/SMS',
    ];
  }

  void toggleBillReminders(bool value) {
    _billRemindersEnabled = value;
    notifyListeners();
  }

  void toggleRentReminders(bool value) {
    _rentRemindersEnabled = value;
    notifyListeners();
  }

  void toggleLoanReminders(bool value) {
    _loanRemindersEnabled = value;
    notifyListeners();
  }

  void toggleMonthlySummary(bool value) {
    _monthlySummaryEnabled = value;
    notifyListeners();
  }

  void changeInternetBillDay(int value) {
    if (!_isValidMonthDay(value)) return;

    _internetBillDay = value;
    notifyListeners();
  }

  void changeSchoolFeesDay(int value) {
    if (!_isValidMonthDay(value)) return;

    _schoolFeesDay = value;
    notifyListeners();
  }

  void changeElectricityBillDay(int value) {
    if (!_isValidMonthDay(value)) return;

    _electricityBillDay = value;
    notifyListeners();
  }

  void changeRentStartDay(int value) {
    if (!_isValidMonthDay(value)) return;

    _rentReminderStartDay = value;

    if (_rentReminderStartDay > _rentReminderEndDay) {
      _rentReminderEndDay = _rentReminderStartDay;
    }

    notifyListeners();
  }

  void changeRentEndDay(int value) {
    if (!_isValidMonthDay(value)) return;

    _rentReminderEndDay = value;

    if (_rentReminderEndDay < _rentReminderStartDay) {
      _rentReminderStartDay = _rentReminderEndDay;
    }

    notifyListeners();
  }

  void changeRemindBeforeDays(int value) {
    if (value < 0 || value > 15) return;

    _remindBeforeDays = value;
    notifyListeners();
  }

  void changeReminderChannel(String value) {
    if (!reminderChannels.contains(value)) return;

    _reminderChannel = value;
    notifyListeners();
  }

  void resetDefaults() {
    _billRemindersEnabled = true;
    _rentRemindersEnabled = true;
    _loanRemindersEnabled = true;
    _monthlySummaryEnabled = false;

    _internetBillDay = 10;
    _schoolFeesDay = 10;
    _electricityBillDay = 28;

    _rentReminderStartDay = 5;
    _rentReminderEndDay = 7;

    _remindBeforeDays = 3;
    _reminderChannel = 'In-App';

    notifyListeners();
  }

  String get internetReminderText {
    return 'Internet bill reminder on day $_internetBillDay every month.';
  }

  String get schoolFeesReminderText {
    return 'School fees reminder on day $_schoolFeesDay every month.';
  }

  String get electricityReminderText {
    return 'Electricity bill reminder on day $_electricityBillDay every month.';
  }

  String get rentReminderText {
    return 'Rent collection reminder from day $_rentReminderStartDay to $_rentReminderEndDay every month.';
  }

  String get generalReminderText {
    return 'Reminder will show $_remindBeforeDays days before due date using $_reminderChannel.';
  }

  bool _isValidMonthDay(int value) {
    return value >= 1 && value <= 31;
  }
}