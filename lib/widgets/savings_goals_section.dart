import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/savings_goal.dart';

class SavingsGoalsSection extends StatelessWidget {
  const SavingsGoalsSection({
    super.key,
    required this.goals,
    required this.onManageGoals,
  });

  final List<SavingsGoal> goals;
  final VoidCallback onManageGoals;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return _GoalReveal(child: _EmptyGoalsCard(onCreateGoal: onManageGoals));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Savings Goals',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            OutlinedButton.icon(
              onPressed: onManageGoals,
              icon: const FaIcon(FontAwesomeIcons.bullseye, size: 15),
              label: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...goals.asMap().entries.map((entry) {
          return _GoalReveal(
            delay: Duration(milliseconds: entry.key * 55),
            child: _GoalCard(goal: entry.value),
          );
        }),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress.clamp(0.0, 1.0).toDouble();
    final colorScheme = Theme.of(context).colorScheme;
    final remaining = max(goal.remainingAmount, 0);
    final daysLeft = DateTime(
      goal.deadline.year,
      goal.deadline.month,
      goal.deadline.day,
    ).difference(DateTime.now()).inDays;
    final monthlyPace = _monthlyPace(remaining.toDouble(), goal.deadline);
    final isComplete = goal.savedAmount >= goal.targetAmount;
    final isOverdue = !isComplete && daysLeft < 0;
    final accent = isComplete
        ? const Color(0xFF2A9D8F)
        : isOverdue
        ? const Color(0xFFD62828)
        : const Color(0xFF3D5A80);
    final status = isComplete
        ? 'Goal reached'
        : isOverdue
        ? 'Past deadline'
        : '${max(daysLeft, 0)} days left';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: FaIcon(
                    FontAwesomeIcons.bullseye,
                    color: accent,
                    size: 20,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Deadline ${_formatDate(goal.deadline)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _GoalStatusPill(label: status, color: accent),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '\$${goal.savedAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'of \$${goal.targetAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: progress,
              backgroundColor: accent.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isComplete
                ? 'You have fully funded this goal.'
                : 'Remaining: \$${remaining.toStringAsFixed(2)}'
                      ' | Monthly pace: \$${monthlyPace.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  double _monthlyPace(double remaining, DateTime deadline) {
    final now = DateTime.now();
    final monthsLeft = max(
      1,
      (deadline.year - now.year) * 12 + deadline.month - now.month + 1,
    );

    return remaining / monthsLeft;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _GoalStatusPill extends StatelessWidget {
  const _GoalStatusPill({required this.label, required this.color});

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
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyGoalsCard extends StatelessWidget {
  const _EmptyGoalsCard({required this.onCreateGoal});

  final VoidCallback onCreateGoal;

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
              color: const Color(0xFF3D5A80).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.bullseye,
                color: Color(0xFF3D5A80),
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No savings goals yet',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a goal for trips, emergency funds, or big purchases and track monthly pace.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreateGoal,
            icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
            label: const Text('Create Goal'),
          ),
        ],
      ),
    );
  }
}

class _GoalReveal extends StatelessWidget {
  const _GoalReveal({required this.child, this.delay = Duration.zero});

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
