import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';
import '../data/database_helper.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../utils/category_color.dart';
import '../widgets/budget_list_section.dart';
import '../widgets/savings_goals_section.dart';
import 'add_expense_screen.dart';
import 'dashboard_screen.dart';
import 'manage_budgets_screen.dart';
import 'manage_savings_goals_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedMonth;
  late Future<List<Category>> _categoriesFuture;
  Expense? _pendingDeletedExpense;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _categoriesFuture = DatabaseHelper.instance.getCategoriesEnsuringDefaults();
    context.read<FinanceBloc>().add(RefreshFinanceOverview(_selectedMonth));
  }

  Future<void> _openAddExpenseScreen() async {
    final didSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          initialDate: _initialExpenseDateForSelectedMonth(),
        ),
      ),
    );

    if (didSave == true && mounted) {
      context.read<FinanceBloc>().add(RefreshFinanceOverview(_selectedMonth));
    }
  }

  Future<void> _openEditExpenseScreen(Expense expense) async {
    final didSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          expenseToEdit: expense,
          monthToRefresh: _selectedMonth,
        ),
      ),
    );

    if (didSave == true && mounted) {
      context.read<FinanceBloc>().add(RefreshFinanceOverview(_selectedMonth));
    }
  }

  Future<void> _openDashboardScreen() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DashboardScreen()));
  }

  Future<void> _openProfileScreen() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  Future<void> _openManageBudgetsScreen() async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ManageBudgetsScreen(selectedMonth: _selectedMonth),
      ),
    );

    if (shouldRefresh == true && mounted) {
      context.read<FinanceBloc>().add(RefreshFinanceOverview(_selectedMonth));
    }
  }

  Future<void> _openManageSavingsGoalsScreen() async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ManageSavingsGoalsScreen()),
    );

    if (shouldRefresh == true && mounted) {
      context.read<FinanceBloc>().add(RefreshFinanceOverview(_selectedMonth));
    }
  }

  Future<void> _openMonthlyIncomeDialog(double? currentIncome) async {
    final result = await showDialog<_IncomeDialogResult>(
      context: context,
      builder: (context) => _MonthlyIncomeDialog(
        currentIncome: currentIncome,
        selectedMonthLabel: _monthLabel(_selectedMonth),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    if (result.shouldClear) {
      context.read<FinanceBloc>().add(
        ClearMonthlyIncomeRequested(_selectedMonth),
      );
      return;
    }

    final amount = result.amount;
    if (amount != null) {
      context.read<FinanceBloc>().add(
        SetMonthlyIncomeRequested(month: _selectedMonth, amount: amount),
      );
    }
  }

  Future<void> _confirmAndDeleteExpense(Expense expense) async {
    if (expense.id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text(
          'This will remove the \$${expense.amount.toStringAsFixed(2)} '
          'expense from ${_monthLabel(_selectedMonth)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    _pendingDeletedExpense = expense;
    context.read<FinanceBloc>().add(
      DeleteExpenseRequested(expenseId: expense.id!, month: _selectedMonth),
    );
  }

  void _showUndoDeleteSnackBar(Expense expense) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Expense deleted.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              context.read<FinanceBloc>().add(AddExpenseRequested(expense));
            },
          ),
        ),
      );
  }

  void _goToPreviousMonth() {
    if (!_canGoToPreviousMonth()) {
      return;
    }

    _changeSelectedMonth(
      DateTime(_selectedMonth.year, _selectedMonth.month - 1),
    );
  }

  void _goToNextMonth() {
    if (!_canGoToNextMonth()) {
      return;
    }

    _changeSelectedMonth(
      DateTime(_selectedMonth.year, _selectedMonth.month + 1),
    );
  }

  void _goToCurrentMonth() {
    final now = DateTime.now();
    _changeSelectedMonth(DateTime(now.year, now.month));
  }

  void _changeSelectedMonth(DateTime month) {
    final normalizedMonth = DateTime(month.year, month.month);

    setState(() {
      _selectedMonth = normalizedMonth;
    });
    context.read<FinanceBloc>().add(RefreshFinanceOverview(normalizedMonth));
  }

  bool _canGoToPreviousMonth() {
    return _selectedMonth.isAfter(DateTime(2020));
  }

  bool _canGoToNextMonth() {
    return _selectedMonth.isBefore(DateTime(2100, 12));
  }

  DateTime _initialExpenseDateForSelectedMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year == now.year && _selectedMonth.month == now.month) {
      return now;
    }

    return DateTime(_selectedMonth.year, _selectedMonth.month);
  }

  bool _isViewingCurrentMonth() {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('Overview'),
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final user = state.user;
              return IconButton(
                onPressed: _openProfileScreen,
                icon: CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFF006D77),
                  child: Text(
                    _profileInitial(user?.displayName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                tooltip: 'Profile',
              );
            },
          ),
          IconButton(
            onPressed: _openDashboardScreen,
            icon: const FaIcon(FontAwesomeIcons.chartPie),
            tooltip: 'Dashboard',
          ),
        ],
      ),
      body: BlocConsumer<FinanceBloc, FinanceState>(
        listener: (context, state) {
          if (state.status == FinanceStatus.success &&
              _pendingDeletedExpense != null) {
            final deletedExpense = _pendingDeletedExpense!;
            _pendingDeletedExpense = null;
            _showUndoDeleteSnackBar(deletedExpense);
          }

          if (state.status == FinanceStatus.failure &&
              state.errorMessage != null) {
            _pendingDeletedExpense = null;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          if (state.status == FinanceStatus.loading &&
              state.expenses.isEmpty &&
              state.monthlyBudgets.isEmpty) {
            return const _HomeLoadingState();
          }

          return FutureBuilder<List<Category>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              final categories = snapshot.data ?? const <Category>[];
              final categoryNames = {
                for (final category in categories)
                  if (category.id != null) category.id!: category.name,
              };
              final categoriesById = {
                for (final category in categories)
                  if (category.id != null) category.id!: category,
              };

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<FinanceBloc>().add(
                    RefreshFinanceOverview(_selectedMonth),
                  );
                  setState(() {
                    _categoriesFuture = DatabaseHelper.instance
                        .getCategoriesEnsuringDefaults();
                  });
                },
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.04, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _DashboardHeader(
                            key: ValueKey(_monthLabel(_selectedMonth)),
                            state: state,
                            selectedMonthLabel: _monthLabel(_selectedMonth),
                            isViewingCurrentMonth: _isViewingCurrentMonth(),
                            canGoToPreviousMonth: _canGoToPreviousMonth(),
                            canGoToNextMonth: _canGoToNextMonth(),
                            onPreviousMonth: _goToPreviousMonth,
                            onNextMonth: _goToNextMonth,
                            onCurrentMonth: _goToCurrentMonth,
                            onEditIncome: () =>
                                _openMonthlyIncomeDialog(state.monthlyIncome),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: SavingsGoalsSection(
                            key: ValueKey(
                              'goals-${state.savingsGoals.length}-${state.savingsGoals.fold<double>(0, (sum, goal) => sum + goal.savedAmount)}',
                            ),
                            goals: state.savingsGoals,
                            onManageGoals: _openManageSavingsGoalsScreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: BudgetListSection(
                            key: ValueKey(
                              'budgets-${_monthLabel(_selectedMonth)}-${state.monthlyBudgets.length}',
                            ),
                            budgets: state.monthlyBudgets,
                            expenses: state.expenses,
                            categories: categories,
                            onManageBudgets: _openManageBudgetsScreen,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Expenses for ${_monthLabel(_selectedMonth)}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: state.expenses.isEmpty
                              ? _EmptyExpenseState(
                                  key: ValueKey(
                                    'empty-expenses-${_monthLabel(_selectedMonth)}',
                                  ),
                                  monthLabel: _monthLabel(_selectedMonth),
                                  onAddExpense: _openAddExpenseScreen,
                                )
                              : Column(
                                  key: ValueKey(
                                    'expenses-${_monthLabel(_selectedMonth)}-${state.expenses.length}',
                                  ),
                                  children: state.expenses.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final expense = entry.value;
                                    final category =
                                        categoriesById[expense.categoryId];
                                    final categoryName =
                                        categoryNames[expense.categoryId] ??
                                        'Unknown';

                                    return Dismissible(
                                      key: ValueKey(
                                        'expense-${expense.id ?? '${expense.date}-${expense.amount}-${expense.note}'}',
                                      ),
                                      direction: DismissDirection.horizontal,
                                      background: const _SwipeActionBackground(
                                        alignment: Alignment.centerLeft,
                                        color: Color(0xFF2A9D8F),
                                        icon: FontAwesomeIcons.penToSquare,
                                        label: 'Edit',
                                      ),
                                      secondaryBackground:
                                          const _SwipeActionBackground(
                                            alignment: Alignment.centerRight,
                                            color: Color(0xFFD62828),
                                            icon: FontAwesomeIcons.trashCan,
                                            label: 'Delete',
                                          ),
                                      confirmDismiss: (direction) async {
                                        if (direction ==
                                            DismissDirection.startToEnd) {
                                          await _openEditExpenseScreen(expense);
                                        } else {
                                          await _confirmAndDeleteExpense(
                                            expense,
                                          );
                                        }

                                        return false;
                                      },
                                      child: _ExpenseCard(
                                        expense: expense,
                                        category: category,
                                        categoryName: categoryName,
                                        formattedDate: _formatDate(
                                          expense.date,
                                        ),
                                        revealDelay: Duration(
                                          milliseconds: index * 45,
                                        ),
                                        onEdit: () =>
                                            _openEditExpenseScreen(expense),
                                        onDelete: () =>
                                            _confirmAndDeleteExpense(expense),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _monthLabel(DateTime date) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${monthNames[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _profileInitial(String? name) {
    final cleanName = name?.trim();
    if (cleanName == null || cleanName.isEmpty) {
      return '?';
    }

    return cleanName.substring(0, 1).toUpperCase();
  }
}

class _IncomeDialogResult {
  const _IncomeDialogResult.set(this.amount) : shouldClear = false;

  const _IncomeDialogResult.clear() : amount = null, shouldClear = true;

  final double? amount;
  final bool shouldClear;
}

class _HomeLoadingState extends StatelessWidget {
  const _HomeLoadingState();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _LoadingCard(height: 260, borderRadius: 30),
            SizedBox(height: 16),
            _LoadingCard(height: 150),
            SizedBox(height: 14),
            _LoadingCard(height: 118),
            SizedBox(height: 14),
            _LoadingCard(height: 118),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.height, this.borderRadius = 22});

  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 0.95),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyExpenseState extends StatelessWidget {
  const _EmptyExpenseState({
    super.key,
    required this.monthLabel,
    required this.onAddExpense,
  });

  final String monthLabel;
  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    return _RevealOnBuild(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
                color: const Color(0xFF006D77).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const FaIcon(
                FontAwesomeIcons.receipt,
                color: Color(0xFF006D77),
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses in $monthLabel',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first expense to start building this month\'s spending picture.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64707A)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAddExpense,
              icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
              label: const Text('Add Expense'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealOnBuild extends StatelessWidget {
  const _RevealOnBuild({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final delayedValue = delay == Duration.zero
            ? value
            : ((value * (360 + delay.inMilliseconds) - delay.inMilliseconds) /
                      360)
                  .clamp(0.0, 1.0)
                  .toDouble();

        return Opacity(
          opacity: delayedValue,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - delayedValue)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.category,
    required this.categoryName,
    required this.formattedDate,
    required this.revealDelay,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final Category? category;
  final String categoryName;
  final String formattedDate;
  final Duration revealDelay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final categoryColor = CategoryColor.fromHex(category?.colorHex);

    return _RevealOnBuild(
      delay: revealDelay,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: categoryColor.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  _categoryInitial(categoryName),
                  style: TextStyle(
                    color: categoryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _CategoryChip(
                              label: categoryName,
                              color: categoryColor,
                            ),
                            _DateChip(label: formattedDate),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '\$${expense.amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1F2933),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    expense.note.isEmpty ? 'No note added' : expense.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: expense.note.isEmpty
                          ? const Color(0xFF8A9299)
                          : const Color(0xFF39424E),
                      fontStyle: expense.note.isEmpty ? FontStyle.italic : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _ExpenseActionButton(
                        icon: FontAwesomeIcons.penToSquare,
                        label: 'Edit',
                        onPressed: onEdit,
                      ),
                      _ExpenseActionButton(
                        icon: FontAwesomeIcons.trashCan,
                        label: 'Delete',
                        onPressed: onDelete,
                        isDestructive: true,
                      ),
                      Text(
                        'Swipe for actions',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF8A9299),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryInitial(String name) {
    if (name.isEmpty) {
      return '?';
    }

    return name.substring(0, 1).toUpperCase();
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(
            FontAwesomeIcons.calendarDays,
            size: 12,
            color: Color(0xFF6B747C),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF6B747C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseActionButton extends StatelessWidget {
  const _ExpenseActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? const Color(0xFFD62828)
        : const Color(0xFF006D77);

    return TextButton.icon(
      onPressed: onPressed,
      icon: FaIcon(icon, size: 15),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: color,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}

class _SwipeActionBackground extends StatelessWidget {
  const _SwipeActionBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isStart = alignment == Alignment.centerLeft;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: isStart ? TextDirection.ltr : TextDirection.rtl,
        children: [
          FaIcon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyIncomeDialog extends StatefulWidget {
  const _MonthlyIncomeDialog({
    required this.currentIncome,
    required this.selectedMonthLabel,
  });

  final double? currentIncome;
  final String selectedMonthLabel;

  @override
  State<_MonthlyIncomeDialog> createState() => _MonthlyIncomeDialogState();
}

class _MonthlyIncomeDialogState extends State<_MonthlyIncomeDialog> {
  late final TextEditingController _incomeController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _incomeController = TextEditingController(
      text: widget.currentIncome?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  void _saveIncome() {
    final amount = double.tryParse(_incomeController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() {
        _errorText = 'Enter a valid income amount.';
      });
      return;
    }

    Navigator.of(context).pop(_IncomeDialogResult.set(amount));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Monthly Income'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set income for ${widget.selectedMonthLabel}.'),
          const SizedBox(height: 16),
          TextField(
            controller: _incomeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Income amount',
              prefixText: '\$ ',
              errorText: _errorText,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() {
                  _errorText = null;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        if (widget.currentIncome != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(const _IncomeDialogResult.clear());
            },
            child: const Text('Clear'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _saveIncome, child: const Text('Save')),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    super.key,
    required this.state,
    required this.selectedMonthLabel,
    required this.isViewingCurrentMonth,
    required this.canGoToPreviousMonth,
    required this.canGoToNextMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onCurrentMonth,
    required this.onEditIncome,
  });

  final FinanceState state;
  final String selectedMonthLabel;
  final bool isViewingCurrentMonth;
  final bool canGoToPreviousMonth;
  final bool canGoToNextMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onCurrentMonth;
  final VoidCallback onEditIncome;

  @override
  Widget build(BuildContext context) {
    final monthlyCashflow = state.monthlyCashflow;
    final cashflowIsPositive = monthlyCashflow == null || monthlyCashflow >= 0;
    final cashflowTitle = monthlyCashflow == null
        ? 'Remaining'
        : cashflowIsPositive
        ? 'Remaining'
        : 'Over income';
    final cashflowValue = monthlyCashflow == null
        ? 'Set income'
        : _money(monthlyCashflow.abs());
    final cashflowIcon = cashflowIsPositive
        ? FontAwesomeIcons.piggyBank
        : FontAwesomeIcons.triangleExclamation;
    final cashflowAccent = cashflowIsPositive
        ? const Color(0xFFB7E4C7)
        : const Color(0xFFFFB4A2);
    final cashflowMessage = monthlyCashflow == null
        ? 'Add monthly income to unlock cashflow insights.'
        : cashflowIsPositive
        ? 'You still have ${_money(monthlyCashflow)} available.'
        : 'Spending is ${_money(monthlyCashflow.abs())} above income.';
    final budgetLimit = state.totalBudgetLimit;
    final budgetProgress = budgetLimit <= 0
        ? 0.0
        : state.totalSpent / budgetLimit;
    final budgetPercent = budgetLimit <= 0 ? 0 : (budgetProgress * 100).round();
    final budgetBalance = budgetLimit - state.totalSpent;
    final budgetStatus = budgetLimit <= 0
        ? 'No budget set'
        : budgetProgress >= 1
        ? 'Over budget'
        : budgetProgress >= 0.8
        ? 'Watch closely'
        : 'On track';
    final budgetProgressColor = budgetLimit <= 0
        ? Colors.white70
        : budgetProgress >= 1
        ? const Color(0xFFFFB4A2)
        : budgetProgress >= 0.8
        ? const Color(0xFFFFE8A3)
        : const Color(0xFFB7E4C7);
    final budgetCaption = budgetLimit <= 0
        ? 'Set a monthly budget to track how much room you have left.'
        : budgetBalance >= 0
        ? '${_money(budgetBalance)} left before reaching your budget.'
        : '${_money(budgetBalance.abs())} above your budget limit.';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004E59).withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF003D45),
                    Color(0xFF006D77),
                    Color(0xFFE29578),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FINANCE SNAPSHOT',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.6,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedMonthLabel,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isViewingCurrentMonth
                                ? 'Current month overview'
                                : 'Historical month overview',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _HeaderIconButton(
                      tooltip: 'Previous month',
                      icon: FontAwesomeIcons.chevronLeft,
                      onPressed: canGoToPreviousMonth ? onPreviousMonth : null,
                    ),
                    const SizedBox(width: 8),
                    _HeaderIconButton(
                      tooltip: 'Next month',
                      icon: FontAwesomeIcons.chevronRight,
                      onPressed: canGoToNextMonth ? onNextMonth : null,
                    ),
                  ],
                ),
                if (!isViewingCurrentMonth) ...[
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: onCurrentMonth,
                    icon: const FaIcon(FontAwesomeIcons.calendarDay, size: 16),
                    label: const Text('Back to Current Month'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth < 460
                        ? (constraints.maxWidth - 12) / 2
                        : (constraints.maxWidth - 36) / 4;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _HeaderMetricCard(
                          width: cardWidth,
                          title: 'Spent',
                          value: _money(state.totalSpent),
                          icon: FontAwesomeIcons.arrowTrendDown,
                          accentColor: const Color(0xFFFFDDD2),
                        ),
                        _HeaderMetricCard(
                          width: cardWidth,
                          title: 'Income',
                          value: state.monthlyIncome == null
                              ? 'Not set'
                              : _money(state.monthlyIncome!),
                          icon: FontAwesomeIcons.moneyBillWave,
                          accentColor: const Color(0xFF83C5BE),
                        ),
                        _HeaderMetricCard(
                          width: cardWidth,
                          title: cashflowTitle,
                          value: cashflowValue,
                          icon: cashflowIcon,
                          accentColor: cashflowAccent,
                        ),
                        _HeaderMetricCard(
                          width: cardWidth,
                          title: 'Budget',
                          value: _money(state.totalBudgetLimit),
                          icon: FontAwesomeIcons.wallet,
                          accentColor: const Color(0xFFFFE8A3),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                _BudgetProgressPanel(
                  status: budgetStatus,
                  caption: budgetCaption,
                  percentLabel: '$budgetPercent%',
                  progress: budgetProgress.clamp(0.0, 1.0).toDouble(),
                  progressColor: budgetProgressColor,
                  spentLabel: _money(state.totalSpent),
                  budgetLabel: _money(budgetLimit),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final incomeAction = OutlinedButton.icon(
                      onPressed: onEditIncome,
                      icon: const FaIcon(
                        FontAwesomeIcons.penToSquare,
                        size: 15,
                      ),
                      label: Text(
                        state.monthlyIncome == null
                            ? 'Set Income'
                            : 'Edit Income',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.50),
                        ),
                      ),
                    );
                    final cashflowMessageWidget = Text(
                      cashflowMessage,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                    );

                    if (constraints.maxWidth < 420) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          cashflowMessageWidget,
                          const SizedBox(height: 12),
                          incomeAction,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: cashflowMessageWidget),
                        const SizedBox(width: 12),
                        incomeAction,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _money(double amount) => '\$${amount.toStringAsFixed(2)}';
}

class _HeaderMetricCard extends StatelessWidget {
  const _HeaderMetricCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FaIcon(icon, color: accentColor, size: 18),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetProgressPanel extends StatelessWidget {
  const _BudgetProgressPanel({
    required this.status,
    required this.caption,
    required this.percentLabel,
    required this.progress,
    required this.progressColor,
    required this.spentLabel,
    required this.budgetLabel,
  });

  final String status;
  final String caption;
  final String percentLabel;
  final double progress;
  final Color progressColor;
  final String spentLabel;
  final String budgetLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: FaIcon(
                  FontAwesomeIcons.gaugeHigh,
                  color: progressColor,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget Progress',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                percentLabel,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$spentLabel spent',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$budgetLabel budget',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: FaIcon(icon, size: 17),
      color: Colors.white,
      disabledColor: Colors.white38,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.16),
      ),
    );
  }
}
