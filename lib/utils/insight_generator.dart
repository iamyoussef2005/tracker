import '../models/budget.dart';
import '../models/category.dart';
import '../models/expense.dart';

class InsightGenerator {
  const InsightGenerator._();

  static List<String> generateInsights({
    required List<Expense> currentMonthExpenses,
    required List<Expense> previousMonthExpenses,
    List<Category> categories = const [],
    List<Budget> currentMonthBudgets = const [],
    double? monthlyIncome,
    DateTime? today,
  }) {
    final insights = <String>[];
    final now = today ?? DateTime.now();

    final categoryNames = {
      for (final category in categories)
        if (category.id != null) category.id!: category.name,
    };

    insights.addAll(
      _buildCategoryComparisonInsights(
        currentMonthExpenses: currentMonthExpenses,
        previousMonthExpenses: previousMonthExpenses,
        categoryNames: categoryNames,
      ),
    );

    final projectedSavingsInsight = _buildProjectedSavingsInsight(
      currentMonthExpenses: currentMonthExpenses,
      monthlyIncome: monthlyIncome,
      today: now,
    );
    if (projectedSavingsInsight != null) {
      insights.add(projectedSavingsInsight);
    }

    final budgetWarningInsight = _buildBudgetWarningInsight(
      currentMonthExpenses: currentMonthExpenses,
      currentMonthBudgets: currentMonthBudgets,
      today: now,
    );
    if (budgetWarningInsight != null) {
      insights.add(budgetWarningInsight);
    }

    final monthOverMonthInsight = _buildOverallTrendInsight(
      currentMonthExpenses: currentMonthExpenses,
      previousMonthExpenses: previousMonthExpenses,
    );
    if (monthOverMonthInsight != null) {
      insights.add(monthOverMonthInsight);
    }

    if (insights.isEmpty) {
      insights.add(
        'Keep tracking your expenses this month to unlock personalized insights.',
      );
    }

    return insights;
  }

  static List<String> _buildCategoryComparisonInsights({
    required List<Expense> currentMonthExpenses,
    required List<Expense> previousMonthExpenses,
    required Map<int, String> categoryNames,
  }) {
    final currentTotals = _groupByCategory(currentMonthExpenses);
    final previousTotals = _groupByCategory(previousMonthExpenses);

    final insights = <String>[];
    final categoryIds = {...currentTotals.keys, ...previousTotals.keys};

    for (final categoryId in categoryIds) {
      final currentTotal = currentTotals[categoryId] ?? 0;
      final previousTotal = previousTotals[categoryId] ?? 0;

      if (previousTotal <= 0 || currentTotal <= previousTotal) {
        continue;
      }

      final percentIncrease =
          ((currentTotal - previousTotal) / previousTotal) * 100;

      if (percentIncrease < 10) {
        continue;
      }

      final categoryName = categoryNames[categoryId] ?? 'Category $categoryId';
      insights.add(
        'You spent ${percentIncrease.round()}% more on $categoryName this month compared to last month.',
      );
    }

    insights.sort(
      (a, b) => _extractLeadingPercent(b).compareTo(_extractLeadingPercent(a)),
    );
    return insights.take(3).toList();
  }

  static String? _buildProjectedSavingsInsight({
    required List<Expense> currentMonthExpenses,
    required double? monthlyIncome,
    required DateTime today,
  }) {
    if (monthlyIncome == null || monthlyIncome <= 0) {
      return null;
    }

    final totalSpent = currentMonthExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final elapsedDays = today.day;
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;

    if (elapsedDays <= 0) {
      return null;
    }

    final projectedSpend = (totalSpent / elapsedDays) * daysInMonth;
    final projectedSavings = monthlyIncome - projectedSpend;

    if (projectedSavings >= 0) {
      return 'You are on track to save \$${projectedSavings.toStringAsFixed(2)} this month.';
    }

    return 'At your current pace, you may exceed your income by \$${projectedSavings.abs().toStringAsFixed(2)} this month.';
  }

  static String? _buildBudgetWarningInsight({
    required List<Expense> currentMonthExpenses,
    required List<Budget> currentMonthBudgets,
    required DateTime today,
  }) {
    if (currentMonthBudgets.isEmpty || today.day > 14) {
      return null;
    }

    final totalBudget = currentMonthBudgets.fold<double>(
      0,
      (sum, budget) => sum + budget.limitAmount,
    );
    if (totalBudget <= 0) {
      return null;
    }

    final totalSpent = currentMonthExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final usage = totalSpent / totalBudget;

    if (usage >= 0.9) {
      return 'Watch out, you have spent ${(usage * 100).round()}% of your total budget in the first two weeks.';
    }

    return null;
  }

  static String? _buildOverallTrendInsight({
    required List<Expense> currentMonthExpenses,
    required List<Expense> previousMonthExpenses,
  }) {
    final currentTotal = currentMonthExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final previousTotal = previousMonthExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    if (currentTotal <= 0 || previousTotal <= 0) {
      return null;
    }

    final difference = currentTotal - previousTotal;
    final percentChange = (difference / previousTotal) * 100;

    if (percentChange >= 10) {
      return 'Your overall spending is up ${percentChange.round()}% compared to last month.';
    }

    if (percentChange <= -10) {
      return 'Nice work, your overall spending is down ${percentChange.abs().round()}% compared to last month.';
    }

    return null;
  }

  static Map<int, double> _groupByCategory(List<Expense> expenses) {
    final totals = <int, double>{};

    for (final expense in expenses) {
      totals.update(
        expense.categoryId,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return totals;
  }

  static int _extractLeadingPercent(String insight) {
    final match = RegExp(r'(\d+)%').firstMatch(insight);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }
}
