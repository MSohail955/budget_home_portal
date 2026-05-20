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

  Map<String, dynamic> toJson() {
    return {
      'billRemindersEnabled': _billRemindersEnabled,
      'rentRemindersEnabled': _rentRemindersEnabled,
      'loanRemindersEnabled': _loanRemindersEnabled,
      'monthlySummaryEnabled': _monthlySummaryEnabled,
      'internetBillDay': _internetBillDay,
      'schoolFeesDay': _schoolFeesDay,
      'electricityBillDay': _electricityBillDay,
      'rentReminderStartDay': _rentReminderStartDay,
      'rentReminderEndDay': _rentReminderEndDay,
      'remindBeforeDays': _remindBeforeDays,
      'reminderChannel': _reminderChannel,
    };
  }

  void importFromJson(Map<String, dynamic>? data) {
    if (data == null) return;

    _billRemindersEnabled =
        _readBool(data['billRemindersEnabled'], _billRemindersEnabled);
    _rentRemindersEnabled =
        _readBool(data['rentRemindersEnabled'], _rentRemindersEnabled);
    _loanRemindersEnabled =
        _readBool(data['loanRemindersEnabled'], _loanRemindersEnabled);
    _monthlySummaryEnabled =
        _readBool(data['monthlySummaryEnabled'], _monthlySummaryEnabled);

    _internetBillDay = _readMonthDay(
      data['internetBillDay'],
      _internetBillDay,
    );

    _schoolFeesDay = _readMonthDay(
      data['schoolFeesDay'],
      _schoolFeesDay,
    );

    _electricityBillDay = _readMonthDay(
      data['electricityBillDay'],
      _electricityBillDay,
    );

    _rentReminderStartDay = _readMonthDay(
      data['rentReminderStartDay'],
      _rentReminderStartDay,
    );

    _rentReminderEndDay = _readMonthDay(
      data['rentReminderEndDay'],
      _rentReminderEndDay,
    );

    if (_rentReminderStartDay > _rentReminderEndDay) {
      _rentReminderEndDay = _rentReminderStartDay;
    }

    _remindBeforeDays = _readIntInRange(
      data['remindBeforeDays'],
      _remindBeforeDays,
      min: 0,
      max: 15,
    );

    final channel = data['reminderChannel']?.toString();

    if (channel != null && reminderChannels.contains(channel)) {
      _reminderChannel = channel;
    }

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

  bool _readBool(Object? value, bool fallback) {
    if (value is bool) return value;

    if (value is String) {
      final lower = value.toLowerCase();

      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }

    return fallback;
  }

  int _readMonthDay(Object? value, int fallback) {
    final parsed = int.tryParse(value?.toString() ?? '');

    if (parsed == null) return fallback;
    if (!_isValidMonthDay(parsed)) return fallback;

    return parsed;
  }

  int _readIntInRange(
    Object? value,
    int fallback, {
    required int min,
    required int max,
  }) {
    final parsed = int.tryParse(value?.toString() ?? '');

    if (parsed == null) return fallback;
    if (parsed < min || parsed > max) return fallback;

    return parsed;
  }
}