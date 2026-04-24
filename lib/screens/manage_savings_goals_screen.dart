import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../data/database_helper.dart';
import '../models/savings_goal.dart';

class ManageSavingsGoalsScreen extends StatefulWidget {
  const ManageSavingsGoalsScreen({super.key});

  @override
  State<ManageSavingsGoalsScreen> createState() =>
      _ManageSavingsGoalsScreenState();
}

class _ManageSavingsGoalsScreenState extends State<ManageSavingsGoalsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<SavingsGoal> _goals = const [];
  bool _isLoading = true;
  bool _didChangeGoals = false;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final goals = await _databaseHelper.getSavingsGoals();

      if (!mounted) {
        return;
      }

      setState(() {
        _goals = goals;
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
        const SnackBar(content: Text('Unable to load savings goals.')),
      );
    }
  }

  Future<void> _openGoalForm([SavingsGoal? goal]) async {
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SavingsGoalFormSheet(goal: goal),
    );

    if (didSave != true) {
      return;
    }

    _didChangeGoals = true;
    await _loadGoals();
  }

  Future<void> _deleteGoal(SavingsGoal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text('This will remove "${goal.name}" from your goals.'),
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

    if (confirmed != true || goal.id == null) {
      return;
    }

    try {
      await _databaseHelper.deleteSavingsGoal(goal.id!);
      _didChangeGoals = true;
      await _loadGoals();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Savings goal deleted.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete savings goal.')),
      );
    }
  }

  void _closeScreen() {
    Navigator.of(context).pop(_didChangeGoals);
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
          title: const Text('Savings Goals'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _goals.isEmpty
                ? _EmptyGoalsState(onCreateGoal: () => _openGoalForm())
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _goals.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final goal = _goals[index];
                      return _ManageGoalCard(
                        goal: goal,
                        onEdit: () => _openGoalForm(goal),
                        onDelete: () => _deleteGoal(goal),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openGoalForm(),
          icon: const FaIcon(FontAwesomeIcons.plus, size: 18),
          label: const Text('Add Goal'),
        ),
      ),
    );
  }
}

class _ManageGoalCard extends StatelessWidget {
  const _ManageGoalCard({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  final SavingsGoal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress.clamp(0.0, 1.0).toDouble();
    final accent = progress >= 1
        ? const Color(0xFF2A9D8F)
        : const Color(0xFF3D5A80);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
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
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: FaIcon(
                    FontAwesomeIcons.bullseye,
                    color: accent,
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Deadline ${_formatDate(goal.deadline)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64707A),
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: accent.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '\$${goal.savedAmount.toStringAsFixed(2)} saved of '
            '\$${goal.targetAmount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64707A),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 15),
                label: const Text('Edit'),
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
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _EmptyGoalsState extends StatelessWidget {
  const _EmptyGoalsState({required this.onCreateGoal});

  final VoidCallback onCreateGoal;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.bullseye,
              size: 54,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Create your first goal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Track emergency funds, trips, or big purchases with a target and deadline.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreateGoal,
              icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
              label: const Text('Create Goal'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsGoalFormSheet extends StatefulWidget {
  const _SavingsGoalFormSheet({this.goal});

  final SavingsGoal? goal;

  @override
  State<_SavingsGoalFormSheet> createState() => _SavingsGoalFormSheetState();
}

class _SavingsGoalFormSheetState extends State<_SavingsGoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _savedController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  late DateTime _deadline;
  bool _isSaving = false;

  bool get _isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _nameController.text = goal?.name ?? '';
    _targetController.text = goal?.targetAmount.toStringAsFixed(2) ?? '';
    _savedController.text = goal?.savedAmount.toStringAsFixed(2) ?? '0.00';
    _deadline = goal?.deadline ??
        DateTime(DateTime.now().year, DateTime.now().month + 6);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _deadline = pickedDate;
    });
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final existingGoal = widget.goal;
    final goal = SavingsGoal(
      id: existingGoal?.id,
      name: _nameController.text.trim(),
      targetAmount: double.parse(_targetController.text.trim()),
      savedAmount: double.parse(_savedController.text.trim()),
      deadline: _deadline,
      createdAt: existingGoal?.createdAt ?? DateTime.now(),
    );

    try {
      if (_isEditing) {
        await _databaseHelper.updateSavingsGoal(goal);
      } else {
        await _databaseHelper.insertSavingsGoal(goal);
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
            _isEditing
                ? 'Unable to update savings goal.'
                : 'Unable to create savings goal.',
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
                _GoalFormHero(isEditing: _isEditing),
                const SizedBox(height: 18),
                _GoalFormSection(
                  title: 'Goal Details',
                  subtitle: 'Name the target and define the amount.',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Goal name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Enter a goal name.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _targetController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Target amount',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                        validator: (value) {
                          final amount = double.tryParse(value?.trim() ?? '');
                          if (amount == null || amount <= 0) {
                            return 'Enter a valid target amount.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _savedController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Saved so far',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                        validator: (value) {
                          final amount = double.tryParse(value?.trim() ?? '');
                          if (amount == null || amount < 0) {
                            return 'Enter a valid saved amount.';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _GoalFormSection(
                  title: 'Deadline',
                  subtitle: 'Used to calculate your monthly saving pace.',
                  child: _DateField(
                    label: 'Target date',
                    value: _formatDate(_deadline),
                    onTap: _pickDeadline,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveGoal,
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
                          : Text(_isEditing ? 'Save Goal' : 'Create Goal'),
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

class _GoalFormHero extends StatelessWidget {
  const _GoalFormHero({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D5A80), Color(0xFF98C1D9)],
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
            child: Center(
              child: FaIcon(
                isEditing
                    ? FontAwesomeIcons.penToSquare
                    : FontAwesomeIcons.bullseye,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Tune this goal' : 'Create a savings goal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditing
                      ? 'Update progress, target, or deadline.'
                      : 'Set a target and we will show the monthly pace.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalFormSection extends StatelessWidget {
  const _GoalFormSection({
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
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64707A),
                ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
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
