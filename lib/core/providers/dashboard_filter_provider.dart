import 'package:flutter/material.dart';

class DashboardFilterProvider extends ChangeNotifier {
  String _selectedMonth = _currentMonthName();
  String _selectedYear = DateTime.now().year.toString();

  String get selectedMonth => _selectedMonth;
  String get selectedYear => _selectedYear;

  List<String> get months {
    return const [
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
  }

  List<String> get years {
    final currentYear = DateTime.now().year;

    return [
      for (int year = currentYear - 5; year <= currentYear + 5; year++)
        year.toString(),
    ];
  }

  void changeMonth(String value) {
    if (!months.contains(value)) return;

    _selectedMonth = value;
    notifyListeners();
  }

  void changeYear(String value) {
    if (!years.contains(value)) return;

    _selectedYear = value;
    notifyListeners();
  }

  void reset() {
    _selectedMonth = _currentMonthName();
    _selectedYear = DateTime.now().year.toString();
    notifyListeners();
  }

  static String _currentMonthName() {
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

    return months[DateTime.now().month - 1];
  }
}