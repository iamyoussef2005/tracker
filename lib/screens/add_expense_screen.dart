import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';
import '../data/database_helper.dart';
import '../models/category.dart';
import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({
    super.key,
    this.initialDate,
    this.expenseToEdit,
    this.monthToRefresh,
  });

  final DateTime? initialDate;
  final Expense? expenseToEdit;
  final DateTime? monthToRefresh;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<Category> _categories = const [];
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingCategories = true;
  bool _isSubmitting = false;

  bool get _isEditing => widget.expenseToEdit != null;

  @override
  void initState() {
    super.initState();
    final expenseToEdit = widget.expenseToEdit;
    _amountController.text = expenseToEdit?.amount.toStringAsFixed(2) ?? '';
    _noteController.text = expenseToEdit?.note ?? '';
    _selectedDate = expenseToEdit?.date ?? widget.initialDate ?? DateTime.now();
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _databaseHelper.getCategoriesEnsuringDefaults();

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = categories;
        _selectedCategory = _categoryForEditedExpense(categories);
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingCategories = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load categories.')),
      );
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  void _submit() {
    final selectedCategory = _selectedCategory;
    if (!_formKey.currentState!.validate() || selectedCategory == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final expense = Expense(
      id: widget.expenseToEdit?.id,
      amount: double.parse(_amountController.text.trim()),
      date: _selectedDate,
      categoryId: selectedCategory.id!,
      note: _noteController.text.trim(),
    );

    if (_isEditing) {
      context.read<FinanceBloc>().add(
        UpdateExpenseRequested(
          expense: expense,
          monthToRefresh: widget.monthToRefresh ?? _selectedDate,
        ),
      );
    } else {
      context.read<FinanceBloc>().add(AddExpenseRequested(expense));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FinanceBloc, FinanceState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (!_isSubmitting) {
          return;
        }

        if (state.status == FinanceStatus.success) {
          setState(() {
            _isSubmitting = false;
          });
          Navigator.of(context).pop(true);
        } else if (state.status == FinanceStatus.failure) {
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to save expense.'),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
        ),
        body: _isLoadingCategories
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _FormHero(
                        title: _isEditing
                            ? 'Refine this expense'
                            : 'Capture a new expense',
                        subtitle: _isEditing
                            ? 'Update the amount, category, date, or note.'
                            : 'Add the details now so your monthly picture stays accurate.',
                        icon: _isEditing
                            ? FontAwesomeIcons.penToSquare
                            : FontAwesomeIcons.receipt,
                      ),
                      const SizedBox(height: 16),
                      _FormSection(
                        title: 'Money',
                        subtitle: 'How much did this cost?',
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            border: OutlineInputBorder(),
                            prefixText: '\$ ',
                          ),
                          validator: (value) {
                            final amount = double.tryParse(
                              value?.trim() ?? '',
                            );
                            if (amount == null || amount <= 0) {
                              return 'Enter a valid amount.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FormSection(
                        title: 'Details',
                        subtitle: 'Categorize it and choose when it happened.',
                        child: Column(
                          children: [
                            DropdownButtonFormField<Category>(
                              initialValue: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                              items: _categories
                                  .map(
                                    (category) => DropdownMenuItem<Category>(
                                      value: category,
                                      child: Text(category.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Select a category.' : null,
                            ),
                            const SizedBox(height: 14),
                            InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: FaIcon(
                                      FontAwesomeIcons.calendarDays,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                child: Text(_formatDate(_selectedDate)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FormSection(
                        title: 'Note',
                        subtitle: 'Optional context for future you.',
                        child: TextFormField(
                          controller: _noteController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Notes (optional)',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox.shrink()
                            : FaIcon(
                                _isEditing
                                    ? FontAwesomeIcons.circleCheck
                                    : FontAwesomeIcons.circlePlus,
                                size: 17,
                              ),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_isEditing
                                  ? 'Save Expense Changes'
                                  : 'Add Expense'),
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

  Category? _categoryForEditedExpense(List<Category> categories) {
    final expenseToEdit = widget.expenseToEdit;
    if (expenseToEdit == null) {
      return categories.isNotEmpty ? categories.first : null;
    }

    for (final category in categories) {
      if (category.id == expenseToEdit.categoryId) {
        return category;
      }
    }

    return categories.isNotEmpty ? categories.first : null;
  }
}

class _FormHero extends StatelessWidget {
  const _FormHero({
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
          colors: [Color(0xFF006D77), Color(0xFF83C5BE)],
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

class _FormSection extends StatelessWidget {
  const _FormSection({
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
