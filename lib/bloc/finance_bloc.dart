import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database_helper.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../models/savings_goal.dart';
import 'finance_event.dart';
import 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  FinanceBloc({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
      super(const FinanceState()) {
    on<FetchMonthlyExpenses>(_onFetchMonthlyExpenses);
    on<AddExpenseRequested>(_onAddExpenseRequested);
    on<UpdateExpenseRequested>(_onUpdateExpenseRequested);
    on<DeleteExpenseRequested>(_onDeleteExpenseRequested);
    on<SetMonthlyIncomeRequested>(_onSetMonthlyIncomeRequested);
    on<ClearMonthlyIncomeRequested>(_onClearMonthlyIncomeRequested);
    on<FetchMonthlyBudgets>(_onFetchMonthlyBudgets);
    on<RefreshFinanceOverview>(_onRefreshFinanceOverview);
  }

  final DatabaseHelper _databaseHelper;

  Future<void> _onFetchMonthlyExpenses(
    FetchMonthlyExpenses event,
    Emitter<FinanceState> emit,
  ) async {
    final month = _normalizeMonth(event.month);
    final previousMonth = _previousMonth(month);

    emit(
      state.copyWith(
        status: FinanceStatus.loading,
        selectedMonth: month,
        clearErrorMessage: true,
      ),
    );

    try {
      final expenses = await _databaseHelper.getExpensesForMonth(month);
      final previousMonthExpenses = await _databaseHelper.getExpensesForMonth(
        previousMonth,
      );
      final monthlyIncome = await _databaseHelper.getMonthlyIncome(month);
      final savingsGoals = await _databaseHelper.getSavingsGoals();
      emit(
        state.copyWith(
          status: FinanceStatus.success,
          expenses: expenses,
          previousMonthExpenses: previousMonthExpenses,
          savingsGoals: savingsGoals,
          monthlyIncome: monthlyIncome,
          clearMonthlyIncome: monthlyIncome == null,
          selectedMonth: month,
          clearErrorMessage: true,
        ),
      );
    } on DatabaseException catch (error) {
      emit(_buildFailureState(month, error));
    } catch (error) {
      emit(_buildFailureState(month, error));
    }
  }

  Future<void> _onAddExpenseRequested(
    AddExpenseRequested event,
    Emitter<FinanceState> emit,
  ) async {
    final month = _normalizeMonth(event.expense.date);

    emit(
      state.copyWith(
        status: FinanceStatus.loading,
        selectedMonth: month,
        clearErrorMessage: true,
      ),
    );

    try {
      await _databaseHelper.insertExpense(event.expense);
      final expenses = await _databaseHelper.getExpensesForMonth(month);
      final budgets = await _databaseHelper.getBudgetsForMonth(month);
      final previousMonthExpenses = await _databaseHelper.getExpensesForMonth(
        _previousMonth(month),
      );
      final monthlyIncome = await _databaseHelper.getMonthlyIncome(month);
      final savingsGoals = await _databaseHelper.getSavingsGoals();

      emit(
        state.copyWith(
          status: FinanceStatus.success,
          expenses: expenses,
          previousMonthExpenses: previousMonthExpenses,
          monthlyBudgets: budgets,
          savingsGoals: savingsGoals,
          monthlyIncome: monthlyIncome,
          clearMonthlyIncome: monthlyIncome == null,
          selectedMonth: month,
          clearErrorMessage: true,
        ),
      );
    } on DatabaseException catch (error) {
      emit(_buildFailureState(month, error));
    } catch (error) {
      emit(_buildFailureState(month, error));
    }
  }

  Future<void> _onDeleteExpenseRequested(
    DeleteExpenseRequested event,
    Emitter<FinanceState> emit,
  ) async {
    final month = _normalizeMonth(event.month);

    emit(
      state.copyWith(
        status: FinanceStatus.loading,
        selectedMonth: month,
        clearErrorMessage: true,
      ),
    );

    try {
      await _databaseHelper.deleteExpense(event.expenseId);
      final expenses = await _databaseHelper.getExpensesForMonth(month);
      final budgets = await _databaseHelper.getBudgetsForMonth(month);
      final previousMonthExpenses = await _databaseHelper.getExpensesForMonth(
        _previousMonth(month),
      );
      final monthlyIncome = await _databaseHelper.getMonthlyIncome(month);
      final savingsGoals = await _databaseHelper.getSavingsGoals();

      emit(
        state.copyWith(
          status: FinanceStatus.success,
          expenses: expenses,
          previousMonthExpenses: previousMonthExpenses,
          monthlyBudgets: budgets,
          savingsGoals: savingsGoals,
          monthlyIncome: monthlyIncome,
          clearMonthlyIncome: monthlyIncome == null,
          selectedMonth: month,
          clearErrorMessage: true,
        ),
      );
    } on DatabaseException catch (error) {
      emit(_buildFailureState(month, error));
    } catch (error) {
      emit(_buildFailureState(month, error));
    }
  }

  Future<void> _onUpdateExpenseRequested(
    UpdateExpenseRequested event,
    Emitter<FinanceState> emit,
  ) async {
    final month = _normalizeMonth(event.monthToRefresh);

    emit(
      state.copyWith(
        status: FinanceStatus.loading,
        selectedMonth: month,
        clearErrorMessage: true,
      ),
    );

    try {
      await _databaseHelper.updateExpense(event.expense);
      final expenses = await _databaseHelper.getExpensesForMonth(month);
      final budgets = await _databaseHelper.getBudgetsForMonth(month);
      final previousMonthExpenses = await _databaseHelper.getExpensesForMonth(
        _previousMonth(month),
      );
      final monthlyIncome = await _databaseHelper.getMonthlyIncome(month);
      final savingsGoals = await _databaseHelper.getSavingsGoals();

      emit(
        state.copyWith(
          status: FinanceStatus.success,
          expenses: expenses,
          previousMonthExpenses: previousMonthExpenses,
          monthlyBudgets: budgets,
          savingsGoals: savingsGoals,
          monthlyIncome: monthlyIncome,
          clearMonthlyIncome: monthlyIncome == null,
          selectedMonth: month,
          clearErrorMessage: true,
        ),
      );
    } on DatabaseException catch (error) {
      emit(_buildFailureState(month, error));
    } catch (error) {
      emit(_buildFailureState(month, error));
    }
  }

  Future<void> _onFetchMonthlyBudgets(
    FetchMonthlyBudgets event,
    Emitter<FinanceState> emit,
  ) async {
    final month = _normalizeMonth(event.month);

    emit(
      state.copyWith(
        status: FinanceStatus.loading,
        selectedMonth: month,
        clearErrorMessage: true,
      ),
    );

    try {
      final budgets = await _databaseHelper.getBudgetsForMonth(month);
      final previousMonthExpenses = await _databaseHelper.getExpensesForMonth(
        _previousMonth(month),
      );
      final monthlyIncome = await _databaseHelper.getMonthlyIncome(month);
      final savingsGoals = await _databaseHelper.getSavingsGoals();
      emit(
        state.copyWith(
          status: FinanceStatus.success,
          previousMonthExpenses: previousMonthExpenses,
          monthlyBudgets: budgets,
          savingsGoals: savingsGoals,
          monthlyIncome: monthlyIncome,
          clearMonthlyIncome: monthlyIncome == null,
          selectedMonth: month,
          clearErrorMessage: true,
        ),
      );
    } on DatabaseException catch (error) {
      emit(_buildFailureState(month, error));
    } catch (error) {
      emit(_buildFailureState(month, error));
    }
  }

  Future<void> _onRefreshFinanceOverview(
    RefreshFinanceOverview event,
    Emitter<FinanceState> emit,
  ) async {
    final month = _normalizeMonth(event.month);
    final previousMonth = _previousMonth(month);

    emit(
      state.copyWith(
        status: FinanceStatus.loading,
        selectedMonth: month,
        clearErrorMessage: true,
      ),
    );

    try {
      final results = await Future.wait([
        _databaseHelper.getExpensesForMonth(month),
        _databaseHelper.getBudgetsForMonth(month),
        _databaseHelper.getExpensesForMonth(previousMonth),
        _databaseHelper.getMonthlyIncome(month),
        _databaseHelper.getSavingsGoals(),
      ]);

      final monthlyIncome = results[3] as double?;
      emit(
        state.copyWith(
          status: FinanceStatus.success,
          expenses: results[0] as List<Expense>,
          monthlyBudgets: results[1] as List<Budget>,
          previousMonthExpenses: results[2] as List<Expense>,
          savingsGoals: results[4] as List<SavingsGoal>,
          monthlyIncome: monthlyIncome,
          clearMonthlyIncome: monthlyIncome == null,
          selectedMonth: month,
          clearErrorMessage: true,
        ),
      );
    } on DatabaseException catch (error) {
      emit(_buildFailureState(month, error));
    } catch (error) {
      emit(_buildFailureState(month, error));
    }
  }

  Future<void> _onSetMonthlyIncomeRequested(
    SetMonthlyIncomeRequested event,
    Emitter<FinanceState> emit,
  ) async {
    final month = _normalizeMonth(event.month);

    emit(
      state.copyWith(
        status: FinanceStatus.loading,
        selectedMonth: month,
        clearErrorMessage: true,
      ),
    );

    try {
      await _databaseHelper.upsertMonthlyIncome(
        month: month,
        amount: event.amount,
      );
      add(RefreshFinanceOverview(month));
    } on DatabaseException catch (error) {
      emit(_buildFailureState(month, error));
    } catch (error) {
      emit(_buildFailureState(month, error));
    }
  }

  Future<void> _onClearMonthlyIncomeRequested(
    ClearMonthlyIncomeRequested event,
    Emitter<FinanceState> emit,
  ) async {
    final month = _normalizeMonth(event.month);

    emit(
      state.copyWith(
        status: FinanceStatus.loading,
        selectedMonth: month,
        clearErrorMessage: true,
      ),
    );

    try {
      await _databaseHelper.deleteMonthlyIncome(month);
      add(RefreshFinanceOverview(month));
    } on DatabaseException catch (error) {
      emit(_buildFailureState(month, error));
    } catch (error) {
      emit(_buildFailureState(month, error));
    }
  }

  FinanceState _buildFailureState(DateTime month, Object error) {
    return state.copyWith(
      status: FinanceStatus.failure,
      selectedMonth: month,
      errorMessage: 'Database operation failed: $error',
    );
  }

  DateTime _normalizeMonth(DateTime date) => DateTime(date.year, date.month);

  DateTime _previousMonth(DateTime month) =>
      DateTime(month.year, month.month - 1);
}
