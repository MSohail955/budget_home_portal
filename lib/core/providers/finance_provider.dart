import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FinanceProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _currentUserId;

  final List<ExpenseRecord> expenses = [];
  final List<IncomeRecord> incomes = [];
  final List<BillRecord> bills = [];
  final List<RentRecord> rents = [];
  final List<LoanRecord> loans = [];

  String get _financeStorageKey {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return 'finance_records_data_guest';
    }

    return 'finance_records_data_$_currentUserId';
  }

  void setUserId(String? userId) {
    if (_currentUserId == userId) return;

    _currentUserId = userId;

    if (userId == null || userId.isEmpty) {
      _clearMemoryOnly();
      notifyListeners();
      return;
    }

    loadSavedFinanceData();
  }

  void _clearMemoryOnly() {
    expenses.clear();
    incomes.clear();
    bills.clear();
    rents.clear();
    loans.clear();
  }

  double get totalExpenses {
    return expenses.fold(0, (sum, item) => sum + item.amount);
  }

  double get totalIncome {
    return incomes.fold(0, (sum, item) => sum + item.amount);
  }

  double get totalRent {
    return rents.fold(0, (sum, item) => sum + item.amount);
  }

  double get rentCollected {
    return rents
        .where((item) => item.isPaid)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get pendingRent {
    return rents
        .where((item) => !item.isPaid)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get totalBills {
    return bills.fold(0, (sum, item) => sum + item.amount);
  }

  double get unpaidBills {
    return bills
        .where((item) => !item.isPaid)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get totalLoans {
    return loans.fold(0, (sum, item) => sum + item.amount);
  }

  double get pendingLoans {
    return loans
        .where((item) => !item.isPaid)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get paidLoans {
    return loans
        .where((item) => item.isPaid)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get givenLoans {
    return loans
        .where((item) => item.loanType == 'Given')
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get takenLoans {
    return loans
        .where((item) => item.loanType == 'Taken')
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get totalInflow {
    return totalIncome + rentCollected;
  }

  double get netBalance {
    return totalInflow - totalExpenses;
  }

  double get savingsRate {
    if (totalInflow == 0) return 0;
    return (netBalance / totalInflow) * 100;
  }

  double get expenseRate {
    if (totalInflow == 0) return 0;
    return (totalExpenses / totalInflow) * 100;
  }

  Future<void> loadSavedFinanceData() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return;

    try {
      final savedData = await _storage.read(key: _financeStorageKey);

      if (savedData == null || savedData.trim().isEmpty) {
        _clearMemoryOnly();
        await _saveAll();
        notifyListeners();
        return;
      }

      final decoded = jsonDecode(savedData) as Map<String, dynamic>;

      expenses
        ..clear()
        ..addAll(
          ((decoded['expenses'] as List?) ?? [])
              .map((item) => ExpenseRecord.fromJson(item)),
        );

      incomes
        ..clear()
        ..addAll(
          ((decoded['incomes'] as List?) ?? [])
              .map((item) => IncomeRecord.fromJson(item)),
        );

      bills
        ..clear()
        ..addAll(
          ((decoded['bills'] as List?) ?? [])
              .map((item) => BillRecord.fromJson(item)),
        );

      rents
        ..clear()
        ..addAll(
          ((decoded['rents'] as List?) ?? [])
              .map((item) => RentRecord.fromJson(item)),
        );

      loans
        ..clear()
        ..addAll(
          ((decoded['loans'] as List?) ?? [])
              .map((item) => LoanRecord.fromJson(item)),
        );

      notifyListeners();
    } catch (_) {
      _clearMemoryOnly();
      await _saveAll();
      notifyListeners();
    }
  }

  Future<void> _saveAll() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return;

    try {
      final data = {
        'expenses': expenses.map((item) => item.toJson()).toList(),
        'incomes': incomes.map((item) => item.toJson()).toList(),
        'bills': bills.map((item) => item.toJson()).toList(),
        'rents': rents.map((item) => item.toJson()).toList(),
        'loans': loans.map((item) => item.toJson()).toList(),
      };

      await _storage.write(
        key: _financeStorageKey,
        value: jsonEncode(data),
      );
    } catch (_) {
      // App still works in memory even if storage fails.
    }
  }

  void addExpense(ExpenseRecord record) {
    expenses.insert(0, record);
    notifyListeners();
    _saveAll();
  }

  void updateExpense({
    required ExpenseRecord oldRecord,
    required ExpenseRecord newRecord,
  }) {
    final index = expenses.indexOf(oldRecord);
    if (index == -1) return;

    expenses[index] = newRecord;
    notifyListeners();
    _saveAll();
  }

  void deleteExpense(ExpenseRecord record) {
    expenses.remove(record);
    notifyListeners();
    _saveAll();
  }

  void addIncome(IncomeRecord record) {
    incomes.insert(0, record);
    notifyListeners();
    _saveAll();
  }

  void updateIncome({
    required IncomeRecord oldRecord,
    required IncomeRecord newRecord,
  }) {
    final index = incomes.indexOf(oldRecord);
    if (index == -1) return;

    incomes[index] = newRecord;
    notifyListeners();
    _saveAll();
  }

  void deleteIncome(IncomeRecord record) {
    incomes.remove(record);
    notifyListeners();
    _saveAll();
  }

  void addBill(BillRecord record) {
    bills.insert(0, record);
    notifyListeners();
    _saveAll();
  }

  void updateBill({
    required BillRecord oldRecord,
    required BillRecord newRecord,
  }) {
    final index = bills.indexOf(oldRecord);
    if (index == -1) return;

    bills[index] = newRecord;
    notifyListeners();
    _saveAll();
  }

  void deleteBill(BillRecord record) {
    bills.remove(record);
    notifyListeners();
    _saveAll();
  }

  void toggleBillPaid(BillRecord record) {
    record.isPaid = !record.isPaid;
    notifyListeners();
    _saveAll();
  }

  void addRent(RentRecord record) {
    rents.insert(0, record);
    notifyListeners();
    _saveAll();
  }

  void updateRent({
    required RentRecord oldRecord,
    required RentRecord newRecord,
  }) {
    final index = rents.indexOf(oldRecord);
    if (index == -1) return;

    rents[index] = newRecord;
    notifyListeners();
    _saveAll();
  }

  void deleteRent(RentRecord record) {
    rents.remove(record);
    notifyListeners();
    _saveAll();
  }

  void toggleRentStatus(RentRecord record) {
    record.isPaid = !record.isPaid;
    record.paymentDate = record.isPaid ? 'Today' : '';
    notifyListeners();
    _saveAll();
  }

  void addLoan(LoanRecord record) {
    loans.insert(0, record);
    notifyListeners();
    _saveAll();
  }

  void updateLoan({
    required LoanRecord oldRecord,
    required LoanRecord newRecord,
  }) {
    final index = loans.indexOf(oldRecord);
    if (index == -1) return;

    loans[index] = newRecord;
    notifyListeners();
    _saveAll();
  }

  void deleteLoan(LoanRecord record) {
    loans.remove(record);
    notifyListeners();
    _saveAll();
  }

  void toggleLoanStatus(LoanRecord record) {
    record.isPaid = !record.isPaid;
    notifyListeners();
    _saveAll();
  }

  Future<bool> importFinanceDataFromJson(String jsonText) async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return false;

    try {
      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;

      final importedExpenses = ((decoded['expenses'] as List?) ?? [])
          .map((item) => ExpenseRecord.fromJson(item))
          .where((item) => item.title.trim().isNotEmpty && item.amount > 0)
          .toList();

      final importedIncomes = ((decoded['incomes'] as List?) ?? [])
          .map((item) => IncomeRecord.fromJson(item))
          .where((item) => item.title.trim().isNotEmpty && item.amount > 0)
          .toList();

      final importedBills = ((decoded['bills'] as List?) ?? [])
          .map((item) => BillRecord.fromJson(item))
          .where((item) => item.title.trim().isNotEmpty && item.amount > 0)
          .toList();

      final importedRents = ((decoded['rents'] as List?) ?? [])
          .map((item) => RentRecord.fromJson(item))
          .where(
            (item) =>
                item.propertyName.trim().isNotEmpty &&
                item.tenantName.trim().isNotEmpty &&
                item.amount > 0,
          )
          .toList();

      final importedLoans = ((decoded['loans'] as List?) ?? [])
          .map((item) => LoanRecord.fromJson(item))
          .where((item) => item.personName.trim().isNotEmpty && item.amount > 0)
          .toList();

      expenses
        ..clear()
        ..addAll(importedExpenses);

      incomes
        ..clear()
        ..addAll(importedIncomes);

      bills
        ..clear()
        ..addAll(importedBills);

      rents
        ..clear()
        ..addAll(importedRents);

      loans
        ..clear()
        ..addAll(importedLoans);

      notifyListeners();
      await _saveAll();

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> resetAllData() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return;

    await _storage.delete(key: _financeStorageKey);

    _clearMemoryOnly();

    notifyListeners();
    await _saveAll();
  }
}

class ExpenseRecord {
  ExpenseRecord({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.paymentMethod,
  });

  final String title;
  final String category;
  final double amount;
  final String date;
  final String paymentMethod;

  factory ExpenseRecord.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);

    return ExpenseRecord(
      title: map['title']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Other',
      amount: double.tryParse(map['amount'].toString()) ?? 0,
      date: map['date']?.toString() ?? '',
      paymentMethod: map['paymentMethod']?.toString() ?? 'Cash',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'date': date,
      'paymentMethod': paymentMethod,
    };
  }
}

class IncomeRecord {
  IncomeRecord({
    required this.title,
    required this.source,
    required this.category,
    required this.amount,
    required this.date,
  });

  final String title;
  final String source;
  final String category;
  final double amount;
  final String date;

  factory IncomeRecord.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);

    return IncomeRecord(
      title: map['title']?.toString() ?? '',
      source: map['source']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Other',
      amount: double.tryParse(map['amount'].toString()) ?? 0,
      date: map['date']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'source': source,
      'category': category,
      'amount': amount,
      'date': date,
    };
  }
}

class BillRecord {
  BillRecord({
    required this.title,
    required this.category,
    required this.amount,
    required this.dueDate,
    required this.isPaid,
  });

  final String title;
  final String category;
  final double amount;
  final String dueDate;
  bool isPaid;

  String get status => isPaid ? 'Paid' : 'Unpaid';

  factory BillRecord.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);

    return BillRecord(
      title: map['title']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Other',
      amount: double.tryParse(map['amount'].toString()) ?? 0,
      dueDate: map['dueDate']?.toString() ?? '',
      isPaid: map['isPaid'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'dueDate': dueDate,
      'isPaid': isPaid,
    };
  }
}

class RentRecord {
  RentRecord({
    required this.propertyName,
    required this.tenantName,
    required this.amount,
    required this.month,
    required this.year,
    required this.dueDate,
    required this.isPaid,
    required this.paymentDate,
    required this.notes,
  });

  final String propertyName;
  final String tenantName;
  final double amount;
  final String month;
  final String year;
  final String dueDate;
  bool isPaid;
  String paymentDate;
  final String notes;

  String get status => isPaid ? 'Paid' : 'Unpaid';

  factory RentRecord.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);

    return RentRecord(
      propertyName: map['propertyName']?.toString() ?? '',
      tenantName: map['tenantName']?.toString() ?? '',
      amount: double.tryParse(map['amount'].toString()) ?? 0,
      month: map['month']?.toString() ?? 'May',
      year: map['year']?.toString() ?? '2026',
      dueDate: map['dueDate']?.toString() ?? '',
      isPaid: map['isPaid'] == true,
      paymentDate: map['paymentDate']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyName': propertyName,
      'tenantName': tenantName,
      'amount': amount,
      'month': month,
      'year': year,
      'dueDate': dueDate,
      'isPaid': isPaid,
      'paymentDate': paymentDate,
      'notes': notes,
    };
  }
}

class LoanRecord {
  LoanRecord({
    required this.personName,
    required this.loanType,
    required this.loanPurpose,
    required this.amount,
    required this.date,
    required this.isPaid,
    required this.notes,
  });

  final String personName;
  final String loanType;
  final String loanPurpose;
  final double amount;
  final String date;
  bool isPaid;
  final String notes;

  String get status => isPaid ? 'Paid' : 'Pending';

  factory LoanRecord.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);

    return LoanRecord(
      personName: map['personName']?.toString() ?? '',
      loanType: map['loanType']?.toString() ?? 'Given',
      loanPurpose: map['loanPurpose']?.toString() ?? 'Personal',
      amount: double.tryParse(map['amount'].toString()) ?? 0,
      date: map['date']?.toString() ?? '',
      isPaid: map['isPaid'] == true,
      notes: map['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'personName': personName,
      'loanType': loanType,
      'loanPurpose': loanPurpose,
      'amount': amount,
      'date': date,
      'isPaid': isPaid,
      'notes': notes,
    };
  }
}