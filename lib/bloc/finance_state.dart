import 'package:equatable/equatable.dart';

import '../models/budget.dart';
import '../models/expense.dart';
import '../models/savings_goal.dart';

enum FinanceStatus { initial, loading, success, failure }

class FinanceState extends Equatable {
  const FinanceState({
    this.status = FinanceStatus.initial,
    this.expenses = const [],
    this.previousMonthExpenses = const [],
    this.monthlyBudgets = const [],
    this.savingsGoals = const [],
    this.monthlyIncome,
    this.selectedMonth,
    this.errorMessage,
  });

  final FinanceStatus status;
  final List<Expense> expenses;
  final List<Expense> previousMonthExpenses;
  final List<Budget> monthlyBudgets;
  final List<SavingsGoal> savingsGoals;
  final double? monthlyIncome;
  final DateTime? selectedMonth;
  final String? errorMessage;

  double get totalSpent =>
      expenses.fold(0, (sum, expense) => sum + expense.amount);

  double get totalBudgetLimit =>
      monthlyBudgets.fold(0, (sum, budget) => sum + budget.limitAmount);

  double? get monthlyCashflow =>
      monthlyIncome == null ? null : monthlyIncome! - totalSpent;

  FinanceState copyWith({
    FinanceStatus? status,
    List<Expense>? expenses,
    List<Expense>? previousMonthExpenses,
    List<Budget>? monthlyBudgets,
    List<SavingsGoal>? savingsGoals,
    double? monthlyIncome,
    bool clearMonthlyIncome = false,
    DateTime? selectedMonth,
    bool clearSelectedMonth = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return FinanceState(
      status: status ?? this.status,
      expenses: expenses ?? this.expenses,
      previousMonthExpenses:
          previousMonthExpenses ?? this.previousMonthExpenses,
      monthlyBudgets: monthlyBudgets ?? this.monthlyBudgets,
      savingsGoals: savingsGoals ?? this.savingsGoals,
      monthlyIncome: clearMonthlyIncome
          ? null
          : monthlyIncome ?? this.monthlyIncome,
      selectedMonth: clearSelectedMonth
          ? null
          : selectedMonth ?? this.selectedMonth,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    expenses,
    previousMonthExpenses,
    monthlyBudgets,
    savingsGoals,
    monthlyIncome,
    selectedMonth?.year,
    selectedMonth?.month,
    errorMessage,
  ];
}
