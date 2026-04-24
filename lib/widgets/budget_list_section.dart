import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/budget.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../utils/category_color.dart';

class BudgetListSection extends StatelessWidget {
  const BudgetListSection({
    super.key,
    required this.budgets,
    required this.expenses,
    required this.categories,
    required this.onManageBudgets,
  });

  final List<Budget> budgets;
  final List<Expense> expenses;
  final List<Category> categories;
  final VoidCallback onManageBudgets;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (budgets.isEmpty) {
      return _BudgetReveal(
        child: _EmptyBudgetsCard(onCreateBudget: onManageBudgets),
      );
    }

    final categoryNames = {
      for (final category in categories)
        if (category.id != null) category.id!: category.name,
    };
    final categoriesById = {
      for (final category in categories)
        if (category.id != null) category.id!: category,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Budget Tracking', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onManageBudgets,
            icon: const FaIcon(FontAwesomeIcons.sliders, size: 16),
            label: const Text('Manage Budgets'),
          ),
        ),
        const SizedBox(height: 12),
        ...budgets.asMap().entries.map((entry) {
          final index = entry.key;
          final budget = entry.value;
          final spentAmount = _calculateSpentForBudget(
            budget: budget,
            expenses: expenses,
          );
          final progress = budget.limitAmount <= 0
              ? 0.0
              : spentAmount / budget.limitAmount;
          final progressColor = _progressColor(progress);
          final categoryLabel = budget.categoryId != null
              ? categoryNames[budget.categoryId!] ?? budget.name
              : budget.name;
          final categoryColor = budget.categoryId != null
              ? CategoryColor.fromHex(
                  categoriesById[budget.categoryId!]?.colorHex,
                )
              : CategoryColor.fallback;
          final budgetAccentColor = progress > 1 || progress >= 0.8
              ? progressColor
              : categoryColor;
          final remainingAmount = budget.limitAmount - spentAmount;
          final balanceLabel = remainingAmount >= 0
              ? '\$${remainingAmount.toStringAsFixed(2)}'
              : '\$${remainingAmount.abs().toStringAsFixed(2)}';
          final balanceCaption = remainingAmount >= 0
              ? 'remaining'
              : 'over budget';
          final progressLabel =
              '${(min(progress, 9.99) * 100).toStringAsFixed(0)}%';

          return _BudgetReveal(
            delay: Duration(milliseconds: index * 55),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: categoryColor.withValues(alpha: 0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            _categoryInitial(categoryLabel),
                            style: TextStyle(
                              color: categoryColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$categoryLabel Budget',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            _BudgetStatusPill(
                              label: _budgetStatusLabel(progress),
                              color: budgetAccentColor,
                            ),
                          ],
                        ),
                      ),
                      _BudgetProgressRing(
                        progress: progress.clamp(0.0, 1.0).toDouble(),
                        color: budgetAccentColor,
                        label: progressLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              balanceLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: budgetAccentColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              balanceCaption,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${spentAmount.toStringAsFixed(2)} spent\n'
                        'of \$${budget.limitAmount.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 12,
                      value: progress.clamp(0.0, 1.0).toDouble(),
                      backgroundColor: categoryColor.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        budgetAccentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  double _calculateSpentForBudget({
    required Budget budget,
    required List<Expense> expenses,
  }) {
    if (budget.categoryId == null) {
      return expenses
          .where((expense) => _expenseFallsWithinBudget(expense, budget))
          .fold(0, (sum, expense) => sum + expense.amount);
    }

    return expenses
        .where(
          (expense) =>
              expense.categoryId == budget.categoryId &&
              _expenseFallsWithinBudget(expense, budget),
        )
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  bool _expenseFallsWithinBudget(Expense expense, Budget budget) {
    final expenseDate = DateTime(
      expense.date.year,
      expense.date.month,
      expense.date.day,
    );
    final startDate = DateTime(
      budget.startDate.year,
      budget.startDate.month,
      budget.startDate.day,
    );
    final endDate = DateTime(
      budget.endDate.year,
      budget.endDate.month,
      budget.endDate.day,
    );

    return !expenseDate.isBefore(startDate) && !expenseDate.isAfter(endDate);
  }

  Color _progressColor(double progress) {
    if (progress > 1) {
      return const Color(0xFFD62828);
    }

    if (progress >= 0.8) {
      return const Color(0xFFF77F00);
    }

    return const Color(0xFF2A9D8F);
  }

  String _categoryInitial(String name) {
    if (name.isEmpty) {
      return '?';
    }

    return name.substring(0, 1).toUpperCase();
  }

  String _budgetStatusLabel(double progress) {
    if (progress > 1) {
      return 'Over budget';
    }

    if (progress >= 0.8) {
      return 'Watch';
    }

    return 'Healthy';
  }
}

class _BudgetStatusPill extends StatelessWidget {
  const _BudgetStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyBudgetsCard extends StatelessWidget {
  const _EmptyBudgetsCard({required this.onCreateBudget});

  final VoidCallback onCreateBudget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              color: CategoryColor.fallback.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const FaIcon(
              FontAwesomeIcons.wallet,
              color: CategoryColor.fallback,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No budgets yet',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Create an overall budget or category budget to see progress, health labels, and remaining amounts.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64707A)),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreateBudget,
            icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
            label: const Text('Create Budget'),
          ),
        ],
      ),
    );
  }
}

class _BudgetReveal extends StatelessWidget {
  const _BudgetReveal({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 340 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final delayedValue = delay == Duration.zero
            ? value
            : ((value * (340 + delay.inMilliseconds) - delay.inMilliseconds) /
                    340)
                .clamp(0.0, 1.0)
                .toDouble();

        return Opacity(
          opacity: delayedValue,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - delayedValue)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _BudgetProgressRing extends StatelessWidget {
  const _BudgetProgressRing({
    required this.progress,
    required this.color,
    required this.label,
  });

  final double progress;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 58,
            width: 58,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 7,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF243038),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
