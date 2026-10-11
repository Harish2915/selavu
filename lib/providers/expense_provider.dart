import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/category_model.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repository;

  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;
  List<CategoryModel> _categories = [];

  ExpenseProvider(this._repository) {
    _initDefaultCategories();
  }

  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<CategoryModel> get categories => _categories;

  void _initDefaultCategories() {
    _categories = AppConstants.defaultCategories.map((c) {
      final hex = c['color']!.replaceAll('#', '');
      return CategoryModel(
        id: c['name']!.toLowerCase(),
        name: c['name']!,
        icon: c['icon']!,
        color: Color(int.parse('FF$hex', radix: 16)),
        isDefault: true,
      );
    }).toList();
  }

  /// Loads expenses for a specific trip
  Future<void> loadExpenses(String tripId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expenses = await _repository.getExpenses(tripId);
    } catch (e) {
      _errorMessage = "Couldn't load expenses.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new expense
  Future<ExpenseModel?> addExpense({
    required String tripId,
    required String payerId,
    required String category,
    required String description,
    required int amountPaise,
    required DateTime expenseDate,
    required String splitType,
    required Map<String, int> memberShares,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final expense = await _repository.addExpense(
        tripId: tripId,
        payerId: payerId,
        category: category,
        description: description,
        amountPaise: amountPaise,
        expenseDate: expenseDate,
        splitType: splitType,
        memberShares: memberShares,
      );
      _expenses.insert(0, expense);
      return expense;
    } catch (e) {
      _errorMessage = "Couldn't save the expense. Please try again.";
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates an existing expense
  Future<ExpenseModel?> updateExpense({
    required String expenseId,
    required String tripId,
    required String payerId,
    required String category,
    required String description,
    required int amountPaise,
    required DateTime expenseDate,
    required String splitType,
    required Map<String, int> memberShares,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updateExpense(
        expenseId: expenseId,
        tripId: tripId,
        payerId: payerId,
        category: category,
        description: description,
        amountPaise: amountPaise,
        expenseDate: expenseDate,
        splitType: splitType,
        memberShares: memberShares,
      );

      final index = _expenses.indexWhere((e) => e.id == expenseId);
      if (index != -1) {
        _expenses[index] = updated;
      }
      return updated;
    } catch (e) {
      _errorMessage = "Couldn't update expense. Please try again.";
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes an expense
  Future<bool> deleteExpense({
    required String tripId,
    required String expenseId,
  }) async {
    try {
      await _repository.deleteExpense(tripId: tripId, expenseId: expenseId);
      _expenses.removeWhere((e) => e.id == expenseId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Couldn't delete expense.";
      notifyListeners();
      return false;
    }
  }

  // --- Statistics Helpers ---
  int get totalSpendingPaise =>
      _expenses.fold(0, (sum, item) => sum + item.amountPaise);

  Map<String, int> get categorySpendingPaise {
    final Map<String, int> result = {};
    for (final exp in _expenses) {
      result[exp.category] = (result[exp.category] ?? 0) + exp.amountPaise;
    }
    return result;
  }

  String get mostUsedCategory {
    final map = categorySpendingPaise;
    if (map.isEmpty) return 'None';
    var topCategory = map.keys.first;
    var maxAmount = map.values.first;
    map.forEach((cat, amt) {
      if (amt > maxAmount) {
        maxAmount = amt;
        topCategory = cat;
      }
    });
    return topCategory;
  }
}
