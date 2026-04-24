import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../data/database_helper.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../utils/category_color.dart';

class ManageBudgetsScreen extends StatefulWidget {
  const ManageBudgetsScreen({super.key, required this.selectedMonth});

  final DateTime selectedMonth;

  @override
  State<ManageBudgetsScreen> createState() => _ManageBudgetsScreenState();
}

class _ManageBudgetsScreenState extends State<ManageBudgetsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<Budget> _budgets = const [];
  List<Category> _categories = const [];
  bool _isLoading = true;
  bool _didChangeBudgets = false;

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final budgets = await _databaseHelper.getBudgetsForMonth(
        widget.selectedMonth,
      );
      final categories = await _databaseHelper.getCategoriesEnsuringDefaults();

      if (!mounted) {
        return;
      }

      setState(() {
        _budgets = budgets;
        _categories = categories;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load budgets.')),
      );
    }
  }

  Future<void> _openBudgetForm([Budget? budget]) async {
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BudgetFormSheet(
        budget: budget,
        categories: _categories,
        selectedMonth: widget.selectedMonth,
      ),
    );

    if (didSave != true) {
      return;
    }

    _didChangeBudgets = true;
    await _loadBudgetData();
  }

  Future<void> _deleteBudget(Budget budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete budget?'),
        content: Text('This will remove "${budget.name}" from your budgets.'),
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

    if (confirmed != true || budget.id == null) {
      return;
    }

    try {
      await _databaseHelper.deleteBudget(budget.id!);
      _didChangeBudgets = true;
      await _loadBudgetData();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget deleted.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete budget.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        _closeScreen();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _closeScreen,
            icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
            tooltip: 'Back',
          ),
          title: Text('Budgets for ${_monthLabel(widget.selectedMonth)}'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _budgets.isEmpty
            ? _EmptyBudgetsState(onCreateBudget: () => _openBudgetForm())
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _budgets.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final budget = _budgets[index];
                  final categoryName = _categoryNameFor(budget.categoryId);
                  final category = _categoryFor(budget.categoryId);

                  return _BudgetCard(
                    budget: budget,
                    category: category,
                    categoryName: categoryName,
                    dateRange: _formatBudgetRange(budget),
                    onEdit: () => _openBudgetForm(budget),
                    onDelete: () => _deleteBudget(budget),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openBudgetForm(),
          icon: const FaIcon(FontAwesomeIcons.plus, size: 18),
          label: const Text('Add Budget'),
        ),
      ),
    );
  }

  void _closeScreen() {
    Navigator.of(context).pop(_didChangeBudgets);
  }

  String? _categoryNameFor(int? categoryId) {
    if (categoryId == null) {
      return 'Overall budget';
    }

    for (final category in _categories) {
      if (category.id == categoryId) {
        return category.name;
      }
    }

    return null;
  }

  Category? _categoryFor(int? categoryId) {
    if (categoryId == null) {
      return null;
    }

    for (final category in _categories) {
      if (category.id == categoryId) {
        return category;
      }
    }

    return null;
  }

  String _formatBudgetRange(Budget budget) {
    return '${_formatDate(budget.startDate)} to ${_formatDate(budget.endDate)}';
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
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.category,
    required this.categoryName,
    required this.dateRange,
    required this.onEdit,
    required this.onDelete,
  });

  final Budget budget;
  final Category? category;
  final String? categoryName;
  final String dateRange;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final categoryColor = CategoryColor.fromHex(category?.colorHex);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: categoryColor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _categoryInitial(categoryName ?? budget.name),
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
                        budget.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(categoryName ?? 'Unassigned category'),
                    ],
                  ),
                ),
                Text(
                  '\$${budget.limitAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: categoryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(dateRange, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 15),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: categoryColor,
                  ),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const FaIcon(FontAwesomeIcons.trashCan, size: 15),
                  label: const Text('Delete'),
                ),
              ],
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

class _EmptyBudgetsState extends StatelessWidget {
  const _EmptyBudgetsState({required this.onCreateBudget});

  final VoidCallback onCreateBudget;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.wallet,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Create your first budget',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Set an overall monthly limit or track spending for a specific category.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreateBudget,
              icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
              label: const Text('Create Budget'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetFormSheet extends StatefulWidget {
  const _BudgetFormSheet({
    required this.categories,
    required this.selectedMonth,
    this.budget,
  });

  final Budget? budget;
  final List<Category> categories;
  final DateTime selectedMonth;

  @override
  State<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<_BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  int? _selectedCategoryId;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSaving = false;

  bool get _isEditing => widget.budget != null;

  @override
  void initState() {
    super.initState();

    final budget = widget.budget;
    _nameController.text = budget?.name ?? '';
    _limitController.text = budget?.limitAmount.toStringAsFixed(2) ?? '';
    _selectedCategoryId = budget?.categoryId;
    _startDate = budget?.startDate ??
        DateTime(widget.selectedMonth.year, widget.selectedMonth.month);
    _endDate = budget?.endDate ??
        DateTime(widget.selectedMonth.year, widget.selectedMonth.month + 1, 0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      if (isStartDate) {
        _startDate = pickedDate;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = pickedDate;
        if (_startDate.isAfter(_endDate)) {
          _startDate = _endDate;
        }
      }
    });
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final budget = Budget(
      id: widget.budget?.id,
      name: _nameController.text.trim(),
      limitAmount: double.parse(_limitController.text.trim()),
      startDate: _startDate,
      endDate: _endDate,
      categoryId: _selectedCategoryId,
    );

    try {
      if (_isEditing) {
        await _databaseHelper.updateBudget(budget);
      } else {
        await _databaseHelper.insertBudget(budget);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Unable to update budget.' : 'Unable to create budget.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BudgetFormHero(
                  title: _isEditing ? 'Tune this budget' : 'Create a budget',
                  subtitle: _isEditing
                      ? 'Adjust the limit, category, or active dates.'
                      : 'Set a spending target and we will track progress against it.',
                  icon: _isEditing
                      ? FontAwesomeIcons.sliders
                      : FontAwesomeIcons.wallet,
                ),
                const SizedBox(height: 18),
                _BudgetFormSection(
                  title: 'Budget Basics',
                  subtitle: 'Name the budget and set a monthly limit.',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Budget name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Enter a budget name.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _limitController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Limit amount',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                        validator: (value) {
                          final amount = double.tryParse(value?.trim() ?? '');
                          if (amount == null || amount <= 0) {
                            return 'Enter a valid limit amount.';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _BudgetFormSection(
                  title: 'Scope',
                  subtitle: 'Choose whether it applies overall or to one category.',
                  child: DropdownButtonFormField<int?>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Overall budget'),
                      ),
                      ...widget.categories
                          .where((category) => category.id != null)
                          .map(
                            (category) => DropdownMenuItem<int?>(
                              value: category.id,
                              child: Text(category.name),
                            ),
                          ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _BudgetFormSection(
                  title: 'Active Dates',
                  subtitle: 'Define when this budget should be counted.',
                  child: Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Start date',
                          value: _formatDate(_startDate),
                          onTap: () => _pickDate(isStartDate: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
                          label: 'End date',
                          value: _formatDate(_endDate),
                          onTap: () => _pickDate(isStartDate: false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveBudget,
                    icon: _isSaving
                        ? const SizedBox.shrink()
                        : FaIcon(
                            _isEditing
                                ? FontAwesomeIcons.circleCheck
                                : FontAwesomeIcons.circlePlus,
                            size: 17,
                          ),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isEditing
                                  ? 'Save Budget Changes'
                                  : 'Create Budget',
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Padding(
            padding: EdgeInsets.only(top: 12),
            child: FaIcon(FontAwesomeIcons.calendarDays, size: 18),
          ),
        ),
        child: Text(value),
      ),
    );
  }
}

class _BudgetFormHero extends StatelessWidget {
  const _BudgetFormHero({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003D45), Color(0xFF006D77)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: FaIcon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetFormSection extends StatelessWidget {
  const _BudgetFormSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64707A)),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
