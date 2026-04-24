import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';
import '../data/database_helper.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../utils/category_color.dart';
import '../utils/insight_generator.dart';
import '../widgets/responsive_page.dart';
import 'add_expense_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  late final Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _databaseHelper.getCategoriesEnsuringDefaults();

    final selectedMonth = context.read<FinanceBloc>().state.selectedMonth;
    context.read<FinanceBloc>().add(
      RefreshFinanceOverview(selectedMonth ?? DateTime.now()),
    );
  }

  Future<void> _openAddExpenseScreen(DateTime selectedMonth) async {
    final didSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          initialDate: _initialExpenseDateForMonth(selectedMonth),
        ),
      ),
    );

    if (didSave == true && mounted) {
      context.read<FinanceBloc>().add(RefreshFinanceOverview(selectedMonth));
    }
  }

  DateTime _initialExpenseDateForMonth(DateTime selectedMonth) {
    final now = DateTime.now();
    if (selectedMonth.year == now.year && selectedMonth.month == now.month) {
      return now;
    }

    return DateTime(selectedMonth.year, selectedMonth.month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          if (state.status == FinanceStatus.loading && state.expenses.isEmpty) {
            return const _DashboardLoadingState();
          }

          if (state.status == FinanceStatus.failure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.errorMessage ?? 'Unable to load dashboard data.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return FutureBuilder<List<Category>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              final categories = snapshot.data ?? const <Category>[];
              final selectedMonth = state.selectedMonth ?? DateTime.now();
              final categoryTotals = FinanceChartMapper.groupExpensesByCategory(
                state.expenses,
                categories,
              );
              final dailySpending = FinanceChartMapper.groupExpensesByMonthDay(
                state.expenses,
                selectedMonth,
              );
              final insights = InsightGenerator.generateInsights(
                currentMonthExpenses: state.expenses,
                previousMonthExpenses: state.previousMonthExpenses,
                categories: categories,
                currentMonthBudgets: state.monthlyBudgets,
                monthlyIncome: state.monthlyIncome,
                today: _insightDateForMonth(selectedMonth),
              );

              return ResponsivePage(
                maxWidth: 1120,
                children: [
                  _RevealDashboardSection(
                    child: _OverviewBanner(
                      state: state,
                      selectedMonth: selectedMonth,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _RevealDashboardSection(
                    delay: const Duration(milliseconds: 80),
                    child: _ChartCard(
                      title: 'Smart Insights',
                      child: _InsightCarousel(insights: insights),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _RevealDashboardSection(
                    delay: const Duration(milliseconds: 140),
                    child: _ChartCard(
                      title: 'Monthly Spending by Category',
                      child: categoryTotals.isEmpty
                          ? _EmptyChart(
                              icon: FontAwesomeIcons.chartPie,
                              title: 'No category spending yet',
                              message:
                                  'Add an expense to see how your spending splits across categories.',
                              actionLabel: 'Add an expense',
                              onAction: () =>
                                  _openAddExpenseScreen(selectedMonth),
                            )
                          : _CategoryPieChart(data: categoryTotals),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _RevealDashboardSection(
                    delay: const Duration(milliseconds: 200),
                    child: _ChartCard(
                      title: 'Daily Spending in ${_monthLabel(selectedMonth)}',
                      child: dailySpending.every((entry) => entry.amount == 0)
                          ? _EmptyChart(
                              icon: FontAwesomeIcons.chartColumn,
                              title: 'No daily spending yet',
                              message:
                                  'Track a few expenses to reveal daily spending rhythm for this month.',
                              actionLabel: 'Add an expense',
                              onAction: () =>
                                  _openAddExpenseScreen(selectedMonth),
                            )
                          : _DailyBarChart(data: dailySpending),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class FinanceChartMapper {
  static List<CategorySpending> groupExpensesByCategory(
    List<Expense> expenses,
    List<Category> categories,
  ) {
    final categoryNames = {
      for (final category in categories)
        if (category.id != null) category.id!: category.name,
    };
    final categoryColors = {
      for (final category in categories)
        if (category.id != null) category.id!: category.colorHex,
    };

    final totals = <int, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.categoryId,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final grouped = List.generate(
      sortedEntries.length,
      (index) {
        final entry = sortedEntries[index];
        return CategorySpending(
          categoryId: entry.key,
          categoryName: categoryNames[entry.key] ?? 'Category ${entry.key}',
          amount: entry.value,
          color: CategoryColor.fromHex(
            categoryColors[entry.key],
            fallbackColor: CategoryColor.fallbackForIndex(index),
          ),
        );
      },
    );

    return grouped;
  }

  static List<DailySpending> groupExpensesByMonthDay(
    List<Expense> expenses,
    DateTime month,
  ) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final totals = <DateTime, double>{};
    for (var dayNumber = 1; dayNumber <= daysInMonth; dayNumber++) {
      final day = DateTime(month.year, month.month, dayNumber);
      totals[DateTime(day.year, day.month, day.day)] = 0;
    }

    for (final expense in expenses) {
      final expenseDay = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );

      if (totals.containsKey(expenseDay)) {
        totals.update(expenseDay, (value) => value + expense.amount);
      }
    }

    return totals.entries
        .map((entry) => DailySpending(date: entry.key, amount: entry.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}

class CategorySpending {
  const CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.color,
  });

  final int categoryId;
  final String categoryName;
  final double amount;
  final Color color;
}

class DailySpending {
  const DailySpending({required this.date, required this.amount});

  final DateTime date;
  final double amount;
}

class _OverviewBanner extends StatelessWidget {
  const _OverviewBanner({required this.state, required this.selectedMonth});

  final FinanceState state;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006D77), Color(0xFF83C5BE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Snapshot',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${state.totalSpent.toStringAsFixed(2)} spent in '
            '${_monthLabel(selectedMonth)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${state.expenses.length} expenses tracked',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _DashboardLoadingCard(height: 130),
            SizedBox(height: 20),
            _DashboardLoadingCard(height: 190),
            SizedBox(height: 20),
            _DashboardLoadingCard(height: 320),
            SizedBox(height: 20),
            _DashboardLoadingCard(height: 280),
          ],
        ),
      ),
    );
  }
}

class _DashboardLoadingCard extends StatelessWidget {
  const _DashboardLoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 0.92),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(24),
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

class _RevealDashboardSection extends StatelessWidget {
  const _RevealDashboardSection({
    required this.child,
    this.delay = Duration.zero,
  });

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
            offset: Offset(0, 16 * (1 - delayedValue)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _InsightCarousel extends StatefulWidget {
  const _InsightCarousel({required this.insights});

  final List<String> insights;

  @override
  State<_InsightCarousel> createState() => _InsightCarouselState();
}

class _InsightCarouselState extends State<_InsightCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.insights.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEDF6F9), Color(0xFFFFF3E0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.lightbulb,
                        color: Color(0xFFB26A00),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.insights[index],
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.insights.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: isActive ? 20 : 8,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF006D77)
                    : const Color(0xFFCAD2C5),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _CategoryPieChart extends StatefulWidget {
  const _CategoryPieChart({required this.data});

  final List<CategorySpending> data;

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final total = widget.data.fold<double>(
      0,
      (sum, category) => sum + category.amount,
    );

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    _touchedIndex =
                        response?.touchedSection?.touchedSectionIndex;
                  });
                },
              ),
              sections: List.generate(widget.data.length, (index) {
                final item = widget.data[index];
                final isTouched = index == _touchedIndex;
                final percent = total == 0 ? 0 : (item.amount / total) * 100;

                return PieChartSectionData(
                  color: item.color,
                  value: item.amount,
                  radius: isTouched ? 86 : 74,
                  title: '${percent.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(widget.data.length, (index) {
          final item = widget.data[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  height: 12,
                  width: 12,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(item.categoryName)),
                Text('\$${item.amount.toStringAsFixed(2)}'),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _DailyBarChart extends StatelessWidget {
  const _DailyBarChart({required this.data});

  final List<DailySpending> data;

  @override
  Widget build(BuildContext context) {
    final maxAmount = data.fold<double>(
      0,
      (currentMax, entry) => max(currentMax, entry.amount),
    );
    final maxY = maxAmount == 0 ? 10.0 : maxAmount * 1.3;

    return SizedBox(
      height: 280,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${value.toInt()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('${data[index].date.day}'),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(data.length, (index) {
            final entry = data[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entry.amount,
                  width: 18,
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEE6C4D), Color(0xFF3D5A80)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 62,
              width: 62,
              decoration: BoxDecoration(
                color: const Color(0xFF006D77).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: FaIcon(icon, color: const Color(0xFF006D77), size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64707A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const FaIcon(FontAwesomeIcons.plus, size: 15),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

DateTime _insightDateForMonth(DateTime selectedMonth) {
  final now = DateTime.now();
  if (selectedMonth.year == now.year && selectedMonth.month == now.month) {
    return now;
  }

  return DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
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
