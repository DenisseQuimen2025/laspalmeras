import 'package:flutter/material.dart';
import '../models/evaluation.dart';

class EvaluationItem extends StatelessWidget {
  final Evaluation data;
  final VoidCallback onToggle;
  final DismissDirectionCallback onDismissed;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EvaluationItem({
    super.key,
    required this.data,
    required this.onToggle,
    required this.onDismissed,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final styleTitle = TextStyle(
      decoration: data.isDone ? TextDecoration.lineThrough : null,
      fontWeight: FontWeight.w600,
    );

    final styleSubtitle = TextStyle(
      color: data.isOverdue ? Theme.of(context).colorScheme.error : null,
    );

    final due = data.dueDate == null
        ? 'Sin fecha'
        : '${data.dueDate!.day.toString().padLeft(2, '0')}/'
          '${data.dueDate!.month.toString().padLeft(2, '0')}/'
          '${data.dueDate!.year}';

    final status = data.isDone
        ? 'Completada'
        : data.isOverdue
            ? 'Vencida'
            : 'Pendiente';

    return Dismissible(
      key: ValueKey('${data.title}-${data.dueDate}-${data.isDone}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.red.withValues(alpha: 0.85),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: onDismissed,
      child: ListTile(
        leading: Checkbox(value: data.isDone, onChanged: (_) => onToggle()),
        title: Text(data.title, style: styleTitle),
        subtitle: Text(
          '$due • $status${data.note != null ? ' • ${data.note}' : ''}',
          style: styleSubtitle,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}
