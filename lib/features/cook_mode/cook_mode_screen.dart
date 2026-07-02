import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../design/app_colors.dart';
import '../../design/app_typography.dart';
import '../../design/components/outline_button.dart';
import '../../design/components/primary_button.dart';
import '../../design/components/timer_card.dart';
import '../../models/recipe_step.dart';
import '../../models/recipe_with_details.dart';
import '../../providers/recipe_list_provider.dart';

/// Distraction-free, one-handed step-through of a recipe's steps. Keeps
/// the screen awake for the whole session via wakelock_plus.
class CookModeScreen extends ConsumerStatefulWidget {
  const CookModeScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<CookModeScreen> createState() => _CookModeScreenState();
}

class _CookModeScreenState extends ConsumerState<CookModeScreen> {
  int _stepIndex = 0;
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  bool _timerRunning = false;
  int _timerTotalSeconds = 0;
  bool _timerInitialized = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  void _setStep(int index, List<RecipeStep> steps) {
    setState(() {
      _stepIndex = index.clamp(0, steps.length - 1);
      _ticker?.cancel();
      _timerRunning = false;
      _timerTotalSeconds = (steps[_stepIndex].durationMinutes ?? 0) * 60;
      _remaining = Duration(seconds: _timerTotalSeconds);
    });
  }

  void _toggleTimer() {
    if (_timerTotalSeconds == 0) return;
    setState(() => _timerRunning = !_timerRunning);
    if (_timerRunning) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_remaining.inSeconds <= 1) {
            _remaining = Duration.zero;
            _timerRunning = false;
            timer.cancel();
          } else {
            _remaining -= const Duration(seconds: 1);
          }
        });
      });
    } else {
      _ticker?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeListProvider);
    RecipeWithDetails? item;
    for (final recipe in state.recipes) {
      if (recipe.recipe.id == widget.recipeId) {
        item = recipe;
        break;
      }
    }

    if (item == null || item.steps.isEmpty) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(
          child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Nema koraka za ovaj recept.')),
        ),
      );
    }

    final steps = item.steps;
    final step = steps[_stepIndex.clamp(0, steps.length - 1)];
    if (!_timerInitialized) {
      _timerInitialized = true;
      _timerTotalSeconds = (step.durationMinutes ?? 0) * 60;
      _remaining = Duration(seconds: _timerTotalSeconds);
    }
    final isLast = _stepIndex == steps.length - 1;
    final minutes = _remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(icon: Icon(Icons.close, color: context.colors.ink), onPressed: () => Navigator.of(context).pop()),
                  Expanded(
                    child: Text(
                      item.recipe.title,
                      textAlign: TextAlign.center,
                      style: context.typography.sans(fontSize: 15, fontWeight: FontWeight.w600, color: context.colors.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: context.colors.oliveSoft, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.brightness_high, size: 14, color: context.colors.olive),
                        const SizedBox(width: 4),
                        Text('Ekran uključen', style: context.typography.sans(fontSize: 11, color: context.colors.olive)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('Korak ${_stepIndex + 1}', style: context.typography.sans(fontWeight: FontWeight.w700, color: context.colors.orange)),
                  const SizedBox(width: 4),
                  Text('od ${steps.length}', style: context.typography.sans(color: context.colors.muted)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < steps.length; i++)
                    Expanded(
                      child: Container(
                        height: 6,
                        margin: EdgeInsets.only(right: i == steps.length - 1 ? 0 : 4),
                        decoration: BoxDecoration(
                          color: i <= _stepIndex ? context.colors.orange : context.colors.hairline,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Text(
                    step.instruction,
                    textAlign: TextAlign.center,
                    style: context.typography.serif(fontSize: 33, height: 1.28),
                  ),
                ),
              ),
              if (_timerTotalSeconds > 0) ...[
                TimerCard(
                  timeLabel: '$minutes:$seconds',
                  isRunning: _timerRunning,
                  onToggle: _toggleTimer,
                  progress: _timerTotalSeconds == 0 ? 0 : 1 - (_remaining.inSeconds / _timerTotalSeconds),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  OutlineButton(
                    label: 'Prethodni',
                    icon: Icons.chevron_left,
                    flex: 2,
                    onPressed: _stepIndex == 0 ? null : () => _setStep(_stepIndex - 1, steps),
                  ),
                  const SizedBox(width: 12),
                  PrimaryButton(
                    label: isLast ? 'Završi' : 'Sljedeći',
                    icon: isLast ? Icons.check : Icons.chevron_right,
                    flex: 3,
                    onPressed: () {
                      if (isLast) {
                        Navigator.of(context).pop();
                      } else {
                        _setStep(_stepIndex + 1, steps);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
