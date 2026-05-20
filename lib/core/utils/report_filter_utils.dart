class ReportFilterUtils {
  static bool matchesMonthAndYear({
    required String selectedMonth,
    required String selectedYear,
    required String dateText,
  }) {
    final cleanDate = dateText.trim().toLowerCase();

    if (cleanDate.isEmpty) return false;

    final recordMonth = extractMonth(cleanDate);
    final recordYear = extractYear(cleanDate);

    final monthMatches = selectedMonth == 'All' ||
        recordMonth == _monthNumber(selectedMonth) ||
        cleanDate.contains(selectedMonth.toLowerCase()) ||
        cleanDate.contains(_shortMonth(selectedMonth));

    final yearMatches = selectedYear == 'All' ||
        recordYear == int.tryParse(selectedYear) ||
        cleanDate.contains(selectedYear);

    return monthMatches && yearMatches;
  }

  static bool matchesMonth({
    required String selectedMonth,
    required String dateText,
  }) {
    return matchesMonthAndYear(
      selectedMonth: selectedMonth,
      selectedYear: 'All',
      dateText: dateText,
    );
  }

  static bool matchesYear({
    required String selectedYear,
    required String dateText,
  }) {
    return matchesMonthAndYear(
      selectedMonth: 'All',
      selectedYear: selectedYear,
      dateText: dateText,
    );
  }

  static int extractMonth(String dateText) {
    final cleanDate = dateText.trim().toLowerCase();

    if (cleanDate.isEmpty) return 0;

    if (cleanDate == 'today') {
      return DateTime.now().month;
    }

    final monthByName = _monthFromText(cleanDate);
    if (monthByName != 0) return monthByName;

    final isoDate = RegExp(r'\b\d{4}-(\d{1,2})-\d{1,2}\b');
    final isoMatch = isoDate.firstMatch(cleanDate);
    if (isoMatch != null) {
      return _safeMonth(isoMatch.group(1));
    }

    final slashDate = RegExp(r'\b\d{1,2}/(\d{1,2})/\d{4}\b');
    final slashMatch = slashDate.firstMatch(cleanDate);
    if (slashMatch != null) {
      return _safeMonth(slashMatch.group(1));
    }

    final dashDate = RegExp(r'\b\d{1,2}-(\d{1,2})-\d{4}\b');
    final dashMatch = dashDate.firstMatch(cleanDate);
    if (dashMatch != null) {
      return _safeMonth(dashMatch.group(1));
    }

    final usSlashDate = RegExp(r'\b(\d{1,2})/\d{1,2}/\d{4}\b');
    final usSlashMatch = usSlashDate.firstMatch(cleanDate);
    if (usSlashMatch != null) {
      final possibleMonth = _safeMonth(usSlashMatch.group(1));
      if (possibleMonth != 0) return possibleMonth;
    }

    final usDashDate = RegExp(r'\b(\d{1,2})-\d{1,2}-\d{4}\b');
    final usDashMatch = usDashDate.firstMatch(cleanDate);
    if (usDashMatch != null) {
      final possibleMonth = _safeMonth(usDashMatch.group(1));
      if (possibleMonth != 0) return possibleMonth;
    }

    final textWithMonthNumber = RegExp(r'\bmonth[:\s-]*(\d{1,2})\b');
    final textMonthMatch = textWithMonthNumber.firstMatch(cleanDate);
    if (textMonthMatch != null) {
      return _safeMonth(textMonthMatch.group(1));
    }

    return 0;
  }

  static int extractYear(String dateText) {
    final cleanDate = dateText.trim().toLowerCase();

    if (cleanDate.isEmpty) return 0;

    if (cleanDate == 'today') {
      return DateTime.now().year;
    }

    final yearMatch = RegExp(r'\b(20\d{2}|19\d{2})\b').firstMatch(cleanDate);

    if (yearMatch != null) {
      return int.tryParse(yearMatch.group(1) ?? '') ?? 0;
    }

    return DateTime.now().year;
  }

  static int _safeMonth(String? value) {
    final month = int.tryParse(value ?? '') ?? 0;

    if (month < 1 || month > 12) return 0;

    return month;
  }

  static String _shortMonth(String month) {
    if (month == 'All' || month.length < 3) return '';

    return month.substring(0, 3).toLowerCase();
  }

  static int _monthFromText(String value) {
    final cleanValue = value.toLowerCase();

    if (cleanValue.contains('january') || cleanValue.contains('jan')) {
      return 1;
    }

    if (cleanValue.contains('february') || cleanValue.contains('feb')) {
      return 2;
    }

    if (cleanValue.contains('march') || cleanValue.contains('mar')) {
      return 3;
    }

    if (cleanValue.contains('april') || cleanValue.contains('apr')) {
      return 4;
    }

    if (cleanValue.contains('may')) {
      return 5;
    }

    if (cleanValue.contains('june') || cleanValue.contains('jun')) {
      return 6;
    }

    if (cleanValue.contains('july') || cleanValue.contains('jul')) {
      return 7;
    }

    if (cleanValue.contains('august') || cleanValue.contains('aug')) {
      return 8;
    }

    if (cleanValue.contains('september') || cleanValue.contains('sep')) {
      return 9;
    }

    if (cleanValue.contains('october') || cleanValue.contains('oct')) {
      return 10;
    }

    if (cleanValue.contains('november') || cleanValue.contains('nov')) {
      return 11;
    }

    if (cleanValue.contains('december') || cleanValue.contains('dec')) {
      return 12;
    }

    return 0;
  }

  static int _monthNumber(String month) {
    switch (month) {
      case 'January':
        return 1;
      case 'February':
        return 2;
      case 'March':
        return 3;
      case 'April':
        return 4;
      case 'May':
        return 5;
      case 'June':
        return 6;
      case 'July':
        return 7;
      case 'August':
        return 8;
      case 'September':
        return 9;
      case 'October':
        return 10;
      case 'November':
        return 11;
      case 'December':
        return 12;
      default:
        return 0;
    }
  }
}