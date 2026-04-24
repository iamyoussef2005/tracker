import 'package:equatable/equatable.dart';

import '../models/expense.dart';

abstract class FinanceEvent extends Equatable {
  const FinanceEvent();

  @override
  List<Object?> get props => [];
}

class FetchMonthlyExpenses extends FinanceEvent {
  const FetchMonthlyExpenses(this.month);

  final DateTime month;

  @override
  List<Object?> get props => [month.year, month.month];
}

class AddExpenseRequested extends FinanceEvent {
  const AddExpenseRequested(this.expense);

  final Expense expense;

  @override
  List<Object?> get props => [expense];
}

class UpdateExpenseRequested extends FinanceEvent {
  const UpdateExpenseRequested({
    required this.expense,
    required this.monthToRefresh,
  });

  final Expense expense;
  final DateTime monthToRefresh;

  @override
  List<Object?> get props => [
    expense,
    monthToRefresh.year,
    monthToRefresh.month,
  ];
}

class DeleteExpenseRequested extends FinanceEvent {
  const DeleteExpenseRequested({required this.expenseId, required this.month});

  final int expenseId;
  final DateTime month;

  @override
  List<Object?> get props => [expenseId, month.year, month.month];
}

class SetMonthlyIncomeRequested extends FinanceEvent {
  const SetMonthlyIncomeRequested({
    required this.month,
    required this.amount,
  });

  final DateTime month;
  final double amount;

  @override
  List<Object?> get props => [month.year, month.month, amount];
}

class ClearMonthlyIncomeRequested extends FinanceEvent {
  const ClearMonthlyIncomeRequested(this.month);

  final DateTime month;

  @override
  List<Object?> get props => [month.year, month.month];
}

class FetchMonthlyBudgets extends FinanceEvent {
  const FetchMonthlyBudgets(this.month);

  final DateTime month;

  @override
  List<Object?> get props => [month.year, month.month];
}

class RefreshFinanceOverview extends FinanceEvent {
  const RefreshFinanceOverview(this.month);

  final DateTime month;

  @override
  List<Object?> get props => [month.year, month.month];
}
