import 'package:flutter/material.dart';

import '../../../models/task.dart';

class StatusFilterChips extends StatelessWidget {
  const StatusFilterChips({super.key, required this.selected, required this.onChanged});

  final TaskStatus? selected;
  final ValueChanged<TaskStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final entries = <MapEntry<String, TaskStatus?>>[
      const MapEntry('Tous', null),
      const MapEntry('À faire', TaskStatus.todo),
      const MapEntry('En cours', TaskStatus.inProgress),
      const MapEntry('Terminé', TaskStatus.done),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final entry = entries[index];
          final isSelected = entry.value == selected;
          return ChoiceChip(
            key: ValueKey('filter_chip_${entry.key}'),
            label: Text(entry.key),
            selected: isSelected,
            onSelected: (_) => onChanged(entry.value),
            labelStyle: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }
}
