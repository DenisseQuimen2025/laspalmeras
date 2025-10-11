import 'package:flutter/material.dart';
import '../models/evaluation.dart';
import '../widgets/evaluation_item.dart';
import 'login_page.dart';

enum QuickFilter { all, pending, done }

class EvaluationsPage extends StatefulWidget {
  const EvaluationsPage({super.key});

  @override
  State<EvaluationsPage> createState() => _EvaluationsPageState();
}

class _EvaluationsPageState extends State<EvaluationsPage> {
  final _searchCtrl = TextEditingController();
  QuickFilter _filter = QuickFilter.all;

  final List<Evaluation> _items = [
    Evaluation(title: 'IoT - Login Flutter', dueDate: DateTime.now().add(const Duration(days: 1))),
    Evaluation(title: 'Redes - Prueba 2', note: 'Cap. 4–6', dueDate: DateTime.now().add(const Duration(days: 3))),
    Evaluation(title: 'BD - Entrega DER', dueDate: DateTime.now().subtract(const Duration(days: 1))),
    Evaluation(title: 'POO - Taller', isDone: true),
    Evaluation(title: 'Calidad - ISO práctica', dueDate: DateTime.now().add(const Duration(days: 7))),
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Evaluation> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();

    List<Evaluation> list = _items.where((e) {
      final hitTitle = e.title.toLowerCase().contains(q);
      final hitNote = (e.note ?? '').toLowerCase().contains(q);
      return q.isEmpty || hitTitle || hitNote;
    }).toList();

    if (_filter == QuickFilter.pending) {
      list = list.where((e) => !e.isDone).toList();
    } else if (_filter == QuickFilter.done) {
      list = list.where((e) => e.isDone).toList();
    }

    // Orden por fecha asc (sin fecha al final)
    list.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    return list;
  }

  void _toggle(Evaluation e) {
    setState(() => e.isDone = !e.isDone);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.isDone ? 'Marcada como completada' : 'Marcada como pendiente')),
    );
  }

  void _removeWithUndo(int index, Evaluation e) {
    final removed = e;
    setState(() => _items.removeAt(index));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Eliminado: ${removed.title}'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () => setState(() {
            _items.insert(index, removed);
          }),
        ),
      ),
    );
  }

  Future<void> _openCreateSheet() async {
    final titleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime? pickedDate;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Nueva evaluación', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Título *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El título es obligatorio'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(pickedDate == null
                            ? 'Elegir fecha (opcional)'
                            : '${pickedDate!.day.toString().padLeft(2,'0')}/${pickedDate!.month.toString().padLeft(2,'0')}/${pickedDate!.year}'),
                        onPressed: () async {
                          final now = DateTime.now();
                          final d = await showDatePicker(
                            context: ctx,
                            firstDate: DateTime(now.year, now.month, now.day),
                            lastDate: DateTime(now.year + 5),
                            initialDate: pickedDate ?? now,
                          );
                          if (d != null) {
                            setState(() {}); // refresco del modal
                            pickedDate = d;
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (!(formKey.currentState?.validate() ?? false)) return;

                      // Validación de fecha no pasada (si eligen)
                      if (pickedDate != null) {
                        final today = DateTime.now();
                        final pick = DateTime(pickedDate!.year, pickedDate!.month, pickedDate!.day);
                        final floorToday = DateTime(today.year, today.month, today.day);
                        if (pick.isBefore(floorToday)) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('La fecha no puede ser anterior a hoy')),
                          );
                          return;
                        }
                      }

                      setState(() {
                        _items.add(Evaluation(
                          title: titleCtrl.text.trim(),
                          note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                          dueDate: pickedDate,
                        ));
                      });
                      Navigator.of(ctx).pop();
                      if (!context.mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.clearSnackBars();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Evaluación creada')),
                      );
                    },
                    child: const Text('Crear'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEditSheet(Evaluation e) async {
    final titleCtrl = TextEditingController(text: e.title);
    final noteCtrl = TextEditingController(text: e.note ?? '');
    DateTime? pickedDate = e.dueDate;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Editar evaluación', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Título *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El título es obligatorio'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(pickedDate == null
                            ? 'Elegir fecha (opcional)'
                            : '${pickedDate!.day.toString().padLeft(2,'0')}/${pickedDate!.month.toString().padLeft(2,'0')}/${pickedDate!.year}'),
                        onPressed: () async {
                          final now = DateTime.now();
                          final d = await showDatePicker(
                            context: ctx,
                            firstDate: DateTime(now.year, now.month, now.day),
                            lastDate: DateTime(now.year + 5),
                            initialDate: pickedDate ?? now,
                          );
                          if (d != null) {
                            setState(() {}); // refresco del modal
                            pickedDate = d;
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (!(formKey.currentState?.validate() ?? false)) return;

                      // Validación de fecha no pasada
                      if (pickedDate != null) {
                        final today = DateTime.now();
                        final pick = DateTime(pickedDate!.year, pickedDate!.month, pickedDate!.day);
                        final floorToday = DateTime(today.year, today.month, today.day);
                        if (pick.isBefore(floorToday)) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('La fecha no puede ser anterior a hoy')),
                          );
                          return;
                        }
                      }

                      setState(() {
                        e.title = titleCtrl.text.trim();
                        e.note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
                        e.dueDate = pickedDate;
                      });
                      Navigator.of(ctx).pop();
                      if (!context.mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.clearSnackBars();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Evaluación actualizada')),
                      );
                    },
                    child: const Text('Guardar cambios'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteAllCompleted() async {
    final completed = <MapEntry<int, Evaluation>>[];
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].isDone) {
        completed.add(MapEntry(i, _items[i]));
      }
    }

    if (completed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay evaluaciones completadas para borrar')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar completadas'),
        content: Text('¿Eliminar ${completed.length} evaluación(es) completadas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ?? false;

    if (!ok) return;
    if (!context.mounted) return;

    setState(() {
      _items.removeWhere((e) => e.isDone);
    });

    // Guard justo antes de usar el context
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Eliminadas ${completed.length} completadas'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () {
            // ⚠️ Este callback NO es async; aquí usa `mounted` (del State), NO `context.mounted`
            if (!mounted) return;
            setState(() {
              for (final entry in completed) {
                final idx = entry.key.clamp(0, _items.length);
                _items.insert(idx, entry.value);
              }
            });
          },
        ),
      ),
    );
  }

  Widget _chip(QuickFilter val, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == val,
      showCheckmark: false, // sin “ticket”
      onSelected: (_) => setState(() => _filter = val),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluaciones'),
        actions: [
          if (_filter == QuickFilter.done)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: _deleteAllCompleted,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Eliminar completadas'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Cerrar sesión'),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cerrar sesión'),
                    content: const Text('¿Seguro que deseas cerrar la sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                ) ?? false;

                if (!ok) return;
                if (!context.mounted) return;

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet,
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Buscador con botón limpiar
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar por título o nota…',
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchCtrl.clear(),
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // Filtros
            Wrap(
              spacing: 8,
              children: [
                _chip(QuickFilter.all, 'Todas'),
                _chip(QuickFilter.pending, 'Pendientes'),
                _chip(QuickFilter.done, 'Completas'),
              ],
            ),
            const SizedBox(height: 8),

            // Listado
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text('Sin resultados'))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) {
                        final e = _filtered[i];
                        final originalIndex = _items.indexOf(e);
                        return EvaluationItem(
                          data: e,
                          onToggle: () => _toggle(e),
                          onDismissed: (dir) => _removeWithUndo(originalIndex, e),
                          onEdit: () => _openEditSheet(e),
                          onDelete: () {
                            final idx = _items.indexOf(e);
                            if (idx >= 0) _removeWithUndo(idx, e);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
