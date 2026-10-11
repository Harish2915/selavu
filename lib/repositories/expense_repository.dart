import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/expense_model.dart';
import '../services/preferences_service.dart';
import '../services/supabase_service.dart';

class ExpenseRepository {
  final PreferencesService _prefs;
  final _uuid = const Uuid();

  ExpenseRepository(this._prefs);

  /// Gets all expenses for a given trip, ordered by expenseDate descending
  Future<List<ExpenseModel>> getExpenses(String tripId) async {
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      try {
        final client = SupabaseService.client!;
        final expenseRows = await client
            .from(AppConstants.tableExpenses)
            .select()
            .eq('trip_id', tripId)
            .order('expense_date', ascending: false);

        final List<ExpenseModel> expenses = [];
        for (final row in expenseRows) {
          final expId = row['id'] as String;
          final shareRows = await client
              .from(AppConstants.tableExpenseShares)
              .select()
              .eq('expense_id', expId);

          final shares = (shareRows as List)
              .map((s) => ExpenseShareModel.fromJson(s as Map<String, dynamic>))
              .toList();

          expenses.add(ExpenseModel.fromJson(row, shares: shares));
        }

        // Cache locally
        await _prefs.saveLocalExpenses(
          tripId,
          expenses.map((e) {
            final map = e.toJson();
            map['shares'] = e.shares.map((s) => s.toJson()).toList();
            return map;
          }).toList(),
        );

        return expenses;
      } catch (_) {
        return _getLocalExpenses(tripId);
      }
    } else {
      return _getLocalExpenses(tripId);
    }
  }

  List<ExpenseModel> _getLocalExpenses(String tripId) {
    final cached = _prefs.getLocalExpenses(tripId);
    return cached.map((map) {
      final sharesList = (map['shares'] as List? ?? [])
          .map((s) => ExpenseShareModel.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList();
      return ExpenseModel.fromJson(map, shares: sharesList);
    }).toList();
  }

  /// Adds a new expense with individual shares
  Future<ExpenseModel> addExpense({
    required String tripId,
    required String payerId,
    required String category,
    required String description,
    required int amountPaise,
    required DateTime expenseDate,
    required String splitType,
    required Map<String, int> memberShares, // memberId -> sharePaise
  }) async {
    final expenseId = _uuid.v4();
    final now = DateTime.now();

    final List<ExpenseShareModel> shares = memberShares.entries.map((entry) {
      return ExpenseShareModel(
        id: _uuid.v4(),
        expenseId: expenseId,
        memberId: entry.key,
        sharePaise: entry.value,
      );
    }).toList();

    final expense = ExpenseModel(
      id: expenseId,
      tripId: tripId,
      payerId: payerId,
      category: category,
      description: description.trim(),
      amountPaise: amountPaise,
      expenseDate: expenseDate,
      splitType: splitType,
      shares: shares,
      createdBy: SupabaseService.currentUserId,
      createdAt: now,
      updatedAt: now,
    );

    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      try {
        final client = SupabaseService.client!;
        await client.from(AppConstants.tableExpenses).insert(expense.toJson());
        await client.from(AppConstants.tableExpenseShares).insert(
              shares.map((s) => s.toJson()).toList(),
            );
      } catch (_) {}
    }

    final localList = _prefs.getLocalExpenses(tripId);
    final map = expense.toJson();
    map['shares'] = shares.map((s) => s.toJson()).toList();
    localList.insert(0, map);
    await _prefs.saveLocalExpenses(tripId, localList);

    return expense;
  }

  /// Updates an existing expense and updates its participant shares
  Future<ExpenseModel> updateExpense({
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
    final now = DateTime.now();

    final List<ExpenseShareModel> shares = memberShares.entries.map((entry) {
      return ExpenseShareModel(
        id: _uuid.v4(),
        expenseId: expenseId,
        memberId: entry.key,
        sharePaise: entry.value,
      );
    }).toList();

    final updated = ExpenseModel(
      id: expenseId,
      tripId: tripId,
      payerId: payerId,
      category: category,
      description: description.trim(),
      amountPaise: amountPaise,
      expenseDate: expenseDate,
      splitType: splitType,
      shares: shares,
      createdAt: now,
      updatedAt: now,
    );

    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      try {
        final client = SupabaseService.client!;
        await client
            .from(AppConstants.tableExpenses)
            .update(updated.toJson())
            .eq('id', expenseId);

        // Delete previous shares and insert updated ones
        await client
            .from(AppConstants.tableExpenseShares)
            .delete()
            .eq('expense_id', expenseId);

        await client
            .from(AppConstants.tableExpenseShares)
            .insert(shares.map((s) => s.toJson()).toList());
      } catch (_) {}
    }

    final localList = _prefs.getLocalExpenses(tripId);
    for (int i = 0; i < localList.length; i++) {
      if (localList[i]['id'] == expenseId) {
        final map = updated.toJson();
        map['shares'] = shares.map((s) => s.toJson()).toList();
        localList[i] = map;
        break;
      }
    }
    await _prefs.saveLocalExpenses(tripId, localList);

    return updated;
  }

  /// Deletes an expense
  Future<void> deleteExpense({
    required String tripId,
    required String expenseId,
  }) async {
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      try {
        await SupabaseService.client!
            .from(AppConstants.tableExpenses)
            .delete()
            .eq('id', expenseId);
      } catch (_) {}
    }

    final localList = _prefs.getLocalExpenses(tripId);
    localList.removeWhere((e) => e['id'] == expenseId);
    await _prefs.saveLocalExpenses(tripId, localList);
  }
}
