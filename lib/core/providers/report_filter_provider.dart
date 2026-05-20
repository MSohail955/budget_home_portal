import 'package:flutter/material.dart';

class ReportFilterProvider extends ChangeNotifier {
  String _selectedMonth = 'All';
  String _selectedYear = DateTime.now().year.toString();

  String get selectedMonth => _selectedMonth;
  String get selectedYear => _selectedYear;

  List<String> get months {
    return const [
      'All',
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
      'All',
      for (int year = currentYear - 5; year <= currentYear + 2; year++)
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
    _selectedMonth = 'All';
    _selectedYear = DateTime.now().year.toString();
    notifyListeners();
  }
}