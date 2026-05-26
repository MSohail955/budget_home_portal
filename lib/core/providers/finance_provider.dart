import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FinanceProvider extends ChangeNotifier {
  static const String baseUrl = 'http://localhost:5168/api';
  static const String _authTokenKey = 'budget_home_auth_token';

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


  Future<String?> _readToken() async {
    try {
      final token = await _storage.read(key: _authTokenKey);
      if (token == null || token.trim().isEmpty) return null;
      return token;
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> _apiRequest({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final token = await _readToken();

    if (token == null) {
      return null;
    }

    final completer = Completer<dynamic>();
    final request = html.HttpRequest();

    void completeFromResponse() {
      final statusCode = request.status ?? 0;
      final responseText = request.responseText ?? '';
      final isSuccess = statusCode >= 200 && statusCode < 300;

      if (!isSuccess) {
        completer.complete(null);
        return;
      }

      if (responseText.trim().isEmpty) {
        completer.complete(true);
        return;
      }

      try {
        completer.complete(jsonDecode(responseText));
      } catch (_) {
        completer.complete(responseText);
      }
    }

    try {
      request.open(method, '$baseUrl$path');
      request.setRequestHeader('Content-Type', 'application/json');
      request.setRequestHeader('Authorization', 'Bearer $token');

      request.onLoadEnd.listen((_) {
        if (!completer.isCompleted) {
          completeFromResponse();
        }
      });

      request.onError.listen((_) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      request.onTimeout.listen((_) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      request.timeout = 15000;
      request.send(body == null ? null : jsonEncode(body));

      return completer.future;
    } catch (_) {
      return null;
    }
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;

    if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response['items'] ?? response['result'];

      if (data is List) return data;
    }

    return [];
  }

  Map<String, dynamic>? _extractMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response['item'] ?? response['result'];

      if (data is Map<String, dynamic>) return data;

      return response;
    }

    return null;
  }

  Future<void> loadIncomeFromApi() async {
    final response = await _apiRequest(
      method: 'GET',
      path: '/income',
    );

    final items = _extractList(response);

    if (items.isEmpty && response == null) return;

    incomes
      ..clear()
      ..addAll(items.map((item) => IncomeRecord.fromJson(item)));

    notifyListeners();
    await _saveAll();
  }

  Future<void> loadExpensesFromApi() async {
    final response = await _apiRequest(
      method: 'GET',
      path: '/expenses',
    );

    final items = _extractList(response);

    if (items.isEmpty && response == null) return;

    expenses
      ..clear()
      ..addAll(items.map((item) => ExpenseRecord.fromJson(item)));

    notifyListeners();
    await _saveAll();
  }

  Future<void> loadBillsFromApi() async {
    final response = await _apiRequest(
      method: 'GET',
      path: '/bills',
    );

    final items = _extractList(response);

    if (items.isEmpty && response == null) return;

    bills
      ..clear()
      ..addAll(items.map((item) => BillRecord.fromJson(item)));

    notifyListeners();
    await _saveAll();
  }

  Future<void> loadRentsFromApi() async {
    final response = await _apiRequest(
      method: 'GET',
      path: '/rents',
    );

    final items = _extractList(response);

    if (items.isEmpty && response == null) return;

    rents
      ..clear()
      ..addAll(items.map((item) => RentRecord.fromJson(item)));

    notifyListeners();
    await _saveAll();
  }

  Future<void> loadLoansFromApi() async {
    final response = await _apiRequest(
      method: 'GET',
      path: '/loans',
    );

    final items = _extractList(response);

    if (items.isEmpty && response == null) return;

    loans
      ..clear()
      ..addAll(items.map((item) => LoanRecord.fromJson(item)));

    notifyListeners();
    await _saveAll();
  }

  Future<void> loadAllRecordsFromApi() async {
    await loadIncomeFromApi();
    await loadExpensesFromApi();
    await loadBillsFromApi();
    await loadRentsFromApi();
    await loadLoansFromApi();
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
        await loadAllRecordsFromApi();
        await loadExpensesFromApi();
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
      await loadIncomeFromApi();
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

  Future<void> addExpense(ExpenseRecord record) async {
    expenses.insert(0, record);
    notifyListeners();
    await _saveAll();

    final response = await _apiRequest(
      method: 'POST',
      path: '/expenses',
      body: record.toApiJson(),
    );

    final savedMap = _extractMap(response);

    if (savedMap == null) return;

    final savedRecord = ExpenseRecord.fromJson(savedMap);
    final index = expenses.indexOf(record);

    if (index != -1) {
      expenses[index] = savedRecord;
      notifyListeners();
      await _saveAll();
    }
  }

  Future<void> updateExpense({
    required ExpenseRecord oldRecord,
    required ExpenseRecord newRecord,
  }) async {
    final index = expenses.indexOf(oldRecord);
    if (index == -1) return;

    final recordToSave = newRecord.copyWith(id: oldRecord.id);

    expenses[index] = recordToSave;
    notifyListeners();
    await _saveAll();

    if (oldRecord.id == null || oldRecord.id!.isEmpty) return;

    final response = await _apiRequest(
      method: 'PUT',
      path: '/expenses/${oldRecord.id}',
      body: recordToSave.toApiJson(),
    );

    final savedMap = _extractMap(response);

    if (savedMap == null) return;

    expenses[index] = ExpenseRecord.fromJson(savedMap);
    notifyListeners();
    await _saveAll();
  }

  Future<void> deleteExpense(ExpenseRecord record) async {
    expenses.remove(record);
    notifyListeners();
    await _saveAll();

    if (record.id == null || record.id!.isEmpty) return;

    await _apiRequest(
      method: 'DELETE',
      path: '/expenses/${record.id}',
    );
  }

  Future<void> addIncome(IncomeRecord record) async {
    incomes.insert(0, record);
    notifyListeners();
    await _saveAll();

    final response = await _apiRequest(
      method: 'POST',
      path: '/income',
      body: record.toApiJson(),
    );

    final savedMap = _extractMap(response);

    if (savedMap == null) return;

    final savedRecord = IncomeRecord.fromJson(savedMap);
    final index = incomes.indexOf(record);

    if (index != -1) {
      incomes[index] = savedRecord;
      notifyListeners();
      await _saveAll();
    }
  }

  Future<void> updateIncome({
    required IncomeRecord oldRecord,
    required IncomeRecord newRecord,
  }) async {
    final index = incomes.indexOf(oldRecord);
    if (index == -1) return;

    final recordToSave = newRecord.copyWith(id: oldRecord.id);

    incomes[index] = recordToSave;
    notifyListeners();
    await _saveAll();

    if (oldRecord.id == null || oldRecord.id!.isEmpty) return;

    final response = await _apiRequest(
      method: 'PUT',
      path: '/income/${oldRecord.id}',
      body: recordToSave.toApiJson(),
    );

    final savedMap = _extractMap(response);

    if (savedMap == null) return;

    incomes[index] = IncomeRecord.fromJson(savedMap);
    notifyListeners();
    await _saveAll();
  }

  Future<void> deleteIncome(IncomeRecord record) async {
    incomes.remove(record);
    notifyListeners();
    await _saveAll();

    if (record.id == null || record.id!.isEmpty) return;

    await _apiRequest(
      method: 'DELETE',
      path: '/income/${record.id}',
    );
  }

  Future<void> addBill(BillRecord record) async {
    bills.insert(0, record);
    notifyListeners();
    await _saveAll();

    final response = await _apiRequest(
      method: 'POST',
      path: '/bills',
      body: record.toApiJson(),
    );

    final savedMap = _extractMap(response);

    if (savedMap == null) return;

    final savedRecord = BillRecord.fromJson(savedMap);
    final index = bills.indexOf(record);

    if (index != -1) {
      bills[index] = savedRecord;
      notifyListeners();
      await _saveAll();
    }
  }

  Future<void> updateBill({
    required BillRecord oldRecord,
    required BillRecord newRecord,
  }) async {
    final index = bills.indexOf(oldRecord);
    if (index == -1) return;

    final recordToSave = newRecord.copyWith(id: oldRecord.id);

    bills[index] = recordToSave;
    notifyListeners();
    await _saveAll();

    if (oldRecord.id == null || oldRecord.id!.isEmpty) return;

    final response = await _apiRequest(
      method: 'PUT',
      path: '/bills/${oldRecord.id}',
      body: recordToSave.toApiJson(),
    );

    final savedMap = _extractMap(response);

    if (savedMap == null) return;

    bills[index] = BillRecord.fromJson(savedMap);
    notifyListeners();
    await _saveAll();
  }

  Future<void> deleteBill(BillRecord record) async {
    bills.remove(record);
    notifyListeners();
    await _saveAll();

    if (record.id == null || record.id!.isEmpty) return;

    await _apiRequest(
      method: 'DELETE',
      path: '/bills/${record.id}',
    );
  }

  Future<void> toggleBillPaid(BillRecord record) async {
    record.isPaid = !record.isPaid;
    notifyListeners();
    await _saveAll();

    if (record.id == null || record.id!.isEmpty) return;

    final response = await _apiRequest(
      method: 'PATCH',
      path: '/bills/${record.id}/toggle-paid',
    );

    final savedMap = _extractMap(response);

    if (savedMap != null) {
      final index = bills.indexWhere((item) => item.id == record.id);
      if (index != -1) {
        bills[index] = BillRecord.fromJson(savedMap);
        notifyListeners();
        await _saveAll();
      }
    }
  }

  Future<void> addRent(RentRecord record) async {
    rents.insert(0, record);
    notifyListeners();
    await _saveAll();

    final response = await _apiRequest(
      method: 'POST',
      path: '/rents',
      body: record.toApiJson(),
    );

    final savedMap = _extractMap(response);

    if (savedMap == null) return;

    final savedRecord = RentRecord.fromJson(savedMap);
    final index = rents.indexOf(record);

    if (index != -1) {
      rents[index] = savedRecord;
      notifyListeners();
      await _saveAll();
    }
  }

  Future<void> updateRent({
    required RentRecord oldRecord,
    required RentRecord newRecord,
  }) async {
    final index = rents.indexOf(oldRecord);
    if (index == -1) return;

    final recordToSave = newRecord.copyWith(id: oldRecord.id);

    rents[index] = recordToSave;
    notifyListeners();
    await _saveAll();

    if (oldRecord.id == null || oldRecord.id!.isEmpty) return;

    final response = await _apiRequest(
      method: 'PUT',
      path: '/rents/${oldRecord.id}',
      body: recordToSave.toApiJson(),
    );

    final savedMap = _extractMap(response);

    if (savedMap == null) return;

    rents[index] = RentRecord.fromJson(savedMap);
    notifyListeners();
    await _saveAll();
  }

  Future<void> deleteRent(RentRecord record) async {
    rents.remove(record);
    notifyListeners();
    await _saveAll();

    if (record.id == null || record.id!.isEmpty) return;

    await _apiRequest(
      method: 'DELETE',
      path: '/rents/${record.id}',
    );
  }

  Future<void> toggleRentStatus(RentRecord record) async {
    record.isPaid = !record.isPaid;
    record.paymentDate = record.isPaid ? 'Today' : '';
    notifyListeners();
    await _saveAll();

    if (record.id == null || record.id!.isEmpty) return;

    final response = await _apiRequest(
      method: 'PATCH',
      path: '/rents/${record.id}/toggle-status',
    );

    final savedMap = _extractMap(response);

    if (savedMap != null) {
      final index = rents.indexWhere((item) => item.id == record.id);
      if (index != -1) {
        rents[index] = RentRecord.fromJson(savedMap);
        notifyListeners();
        await _saveAll();
      }
    }
  }

  Future<void> addLoan(LoanRecord record) async {
    loans.insert(0, record);
    notifyListeners();
    await _saveAll();

    final response = await _apiRequest(
      method: 'POST',
      path: '/loans',
      body: record.toApiJson(),
    );

    final savedMap = _extractMap(response);

    if (savedMap == null) return;

    final savedRecord = LoanRecord.fromJson(savedMap);
    final index = loans.indexOf(record);

    if (index != -1) {
      loans[index] = savedRecord;
      notifyListeners();
      await _saveAll();
    }
  }

  Future<void> updateLoan({
    required LoanRecord oldRecord,
    required LoanRecord newRecord,
  }) async {
    final index = loans.indexOf(oldRecord);
    if (index == -1) return;

    final recordToSave = newRecord.copyWith(id: oldRecord.id);

    loans[index] = recordToSave;
    notifyListeners();
    await _saveAll();

    if (oldRecord.id == null || oldRecord.id!.isEmpty) return;

    final response = await _apiRequest(
      method: 'PUT',
      path: '/loans/${oldRecord.id}',
      body: recordToSave.toApiJson(),
    );

    final savedMap = _extractMap(response);

    if (savedMap == null) return;

    loans[index] = LoanRecord.fromJson(savedMap);
    notifyListeners();
    await _saveAll();
  }

  Future<void> deleteLoan(LoanRecord record) async {
    loans.remove(record);
    notifyListeners();
    await _saveAll();

    if (record.id == null || record.id!.isEmpty) return;

    await _apiRequest(
      method: 'DELETE',
      path: '/loans/${record.id}',
    );
  }

  Future<void> toggleLoanStatus(LoanRecord record) async {
    record.isPaid = !record.isPaid;
    notifyListeners();
    await _saveAll();

    if (record.id == null || record.id!.isEmpty) return;

    final response = await _apiRequest(
      method: 'PATCH',
      path: '/loans/${record.id}/toggle-status',
    );

    final savedMap = _extractMap(response);

    if (savedMap != null) {
      final index = loans.indexWhere((item) => item.id == record.id);
      if (index != -1) {
        loans[index] = LoanRecord.fromJson(savedMap);
        notifyListeners();
        await _saveAll();
      }
    }
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
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.paymentMethod,
  });

  final String? id;
  final String title;
  final String category;
  final double amount;
  final String date;
  final String paymentMethod;

  ExpenseRecord copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    String? date,
    String? paymentMethod,
  }) {
    return ExpenseRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  factory ExpenseRecord.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);

    return ExpenseRecord(
      id: map['id']?.toString() ?? map['expenseId']?.toString(),
      title: map['title']?.toString() ?? map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Other',
      amount: double.tryParse(map['amount'].toString()) ?? 0,
      date: map['date']?.toString() ??
          map['expenseDate']?.toString() ??
          map['createdAt']?.toString() ??
          '',
      paymentMethod: map['paymentMethod']?.toString() ??
          map['method']?.toString() ??
          'Cash',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date,
      'paymentMethod': paymentMethod,
    };
  }

  Map<String, dynamic> toApiJson() {
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
    this.id,
    required this.title,
    required this.source,
    required this.category,
    required this.amount,
    required this.date,
  });

  final String? id;
  final String title;
  final String source;
  final String category;
  final double amount;
  final String date;

  IncomeRecord copyWith({
    String? id,
    String? title,
    String? source,
    String? category,
    double? amount,
    String? date,
  }) {
    return IncomeRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      source: source ?? this.source,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }

  factory IncomeRecord.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);

    return IncomeRecord(
      id: map['id']?.toString() ?? map['incomeId']?.toString(),
      title: map['title']?.toString() ?? map['name']?.toString() ?? '',
      source: map['source']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Other',
      amount: double.tryParse(map['amount'].toString()) ?? 0,
      date: map['date']?.toString() ??
          map['incomeDate']?.toString() ??
          map['createdAt']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'title': title,
      'source': source,
      'category': category,
      'amount': amount,
      'date': date,
    };
  }

  Map<String, dynamic> toApiJson() {
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
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.dueDate,
    required this.isPaid,
  });

  final String? id;
  final String title;
  final String category;
  final double amount;
  final String dueDate;
  bool isPaid;

  String get status => isPaid ? 'Paid' : 'Unpaid';

  BillRecord copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    String? dueDate,
    bool? isPaid,
  }) {
    return BillRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  factory BillRecord.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);

    final statusText = map['status']?.toString().toLowerCase() ?? '';

    return BillRecord(
      id: map['id']?.toString() ?? map['billId']?.toString(),
      title: map['title']?.toString() ?? map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Other',
      amount: double.tryParse(map['amount'].toString()) ?? 0,
      dueDate: map['dueDate']?.toString() ?? map['date']?.toString() ?? '',
      isPaid: map['isPaid'] == true || statusText == 'paid',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'dueDate': dueDate,
      'isPaid': isPaid,
    };
  }

  Map<String, dynamic> toApiJson() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'dueDate': dueDate,
      'isPaid': isPaid,
      'status': status,
    };
  }
}

class RentRecord {
  RentRecord({
    this.id,
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

  final String? id;
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

  RentRecord copyWith({
    String? id,
    String? propertyName,
    String? tenantName,
    double? amount,
    String? month,
    String? year,
    String? dueDate,
    bool? isPaid,
    String? paymentDate,
    String? notes,
  }) {
    return RentRecord(
      id: id ?? this.id,
      propertyName: propertyName ?? this.propertyName,
      tenantName: tenantName ?? this.tenantName,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
    );
  }

  factory RentRecord.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);
    final statusText = map['status']?.toString().toLowerCase() ?? '';

    return RentRecord(
      id: map['id']?.toString() ?? map['rentId']?.toString(),
      propertyName:
          map['propertyName']?.toString() ?? map['property']?.toString() ?? '',
      tenantName: map['tenantName']?.toString() ?? map['tenant']?.toString() ?? '',
      amount: double.tryParse(map['amount'].toString()) ?? 0,
      month: map['month']?.toString() ?? 'May',
      year: map['year']?.toString() ?? '2026',
      dueDate: map['dueDate']?.toString() ?? '',
      isPaid: map['isPaid'] == true || statusText == 'paid',
      paymentDate: map['paymentDate']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
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

  Map<String, dynamic> toApiJson() {
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
      'status': status,
    };
  }
}

class LoanRecord {
  LoanRecord({
    this.id,
    required this.personName,
    required this.loanType,
    required this.loanPurpose,
    required this.amount,
    required this.date,
    required this.isPaid,
    required this.notes,
  });

  final String? id;
  final String personName;
  final String loanType;
  final String loanPurpose;
  final double amount;
  final String date;
  bool isPaid;
  final String notes;

  String get status => isPaid ? 'Paid' : 'Pending';

  LoanRecord copyWith({
    String? id,
    String? personName,
    String? loanType,
    String? loanPurpose,
    double? amount,
    String? date,
    bool? isPaid,
    String? notes,
  }) {
    return LoanRecord(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      loanType: loanType ?? this.loanType,
      loanPurpose: loanPurpose ?? this.loanPurpose,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isPaid: isPaid ?? this.isPaid,
      notes: notes ?? this.notes,
    );
  }

  factory LoanRecord.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);
    final statusText = map['status']?.toString().toLowerCase() ?? '';

    return LoanRecord(
      id: map['id']?.toString() ?? map['loanId']?.toString(),
      personName: map['personName']?.toString() ?? map['person']?.toString() ?? '',
      loanType: map['loanType']?.toString() ?? map['type']?.toString() ?? 'Given',
      loanPurpose:
          map['loanPurpose']?.toString() ?? map['purpose']?.toString() ?? 'Personal',
      amount: double.tryParse(map['amount'].toString()) ?? 0,
      date: map['date']?.toString() ?? map['dueDate']?.toString() ?? '',
      isPaid: map['isPaid'] == true || statusText == 'paid',
      notes: map['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'personName': personName,
      'loanType': loanType,
      'loanPurpose': loanPurpose,
      'amount': amount,
      'date': date,
      'isPaid': isPaid,
      'notes': notes,
    };
  }

  Map<String, dynamic> toApiJson() {
    return {
      'personName': personName,
      'loanType': loanType,
      'loanPurpose': loanPurpose,
      'amount': amount,
      'date': date,
      'isPaid': isPaid,
      'notes': notes,
      'status': status,
    };
  }
}