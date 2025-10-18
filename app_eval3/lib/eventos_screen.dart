import 'package:flutter/material.dart';
import 'models/evento.dart';
import 'services/firebase_service.dart';

enum Filtro { todas, pendientes, completas }

class EventosScreen extends StatefulWidget {
  const EventosScreen({super.key});

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  final TextEditingController _buscarCtrl = TextEditingController();
  Filtro _filtro = Filtro.todas;

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  // ========= CIERRE DE SESIÓN (Auth) =========
  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      await FirebaseService.instance.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  // Aplica búsqueda + filtros + sort
  List<Evento> _aplicarFiltros(List<Evento> base) {
    final q = _buscarCtrl.text.trim().toLowerCase();

    base = base.where((e) {
      final enNombre = e.nombre.toLowerCase().contains(q);
      final enNotas = (e.notas ?? '').toLowerCase().contains(q);
      return q.isEmpty || enNombre || enNotas;
    }).toList();

    base = switch (_filtro) {
      Filtro.todas => base,
      Filtro.pendientes => base.where((e) => !e.reservado).toList(),
      Filtro.completas => base.where((e) => e.reservado).toList(),
    };

    base.sort((a, b) {
      final fa = a.fecha?.millisecondsSinceEpoch ?? 0;
      final fb = b.fecha?.millisecondsSinceEpoch ?? 0;
      return fa.compareTo(fb);
    });
    return base;
  }

  Future<void> _crearEventoModal() async {
    final nuevo = await showModalBottomSheet<Evento>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => const _CrearEventoSheet(),
    );
    if (!mounted) return;
    if (nuevo != null) {
      await FirebaseService.instance.addEvento(nuevo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento creado')),
      );
    }
  }

  Future<void> _toggleReservado(Evento e) async {
    await FirebaseService.instance.toggleReservado(e);
  }

  Future<void> _eliminarConUndo(Evento e) async {
    await FirebaseService.instance.deleteEvento(e);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Eliminado "${e.nombre}"'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () async {
            // Re-crear el mismo ítem (id nuevo en Firestore)
            await FirebaseService.instance.addEvento(
              Evento(
                id: '',
                nombre: e.nombre,
                fecha: e.fecha,
                reservado: e.reservado,
                notas: e.notas,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos / Reservas'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _buscarCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar por nombre o notas...',
                border: const OutlineInputBorder(),
                suffixIcon: _buscarCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _buscarCtrl.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _filtro == Filtro.todas,
                  onSelected: (_) => setState(() => _filtro = Filtro.todas),
                ),
                ChoiceChip(
                  label: const Text('Pendientes'),
                  selected: _filtro == Filtro.pendientes,
                  onSelected: (_) => setState(() => _filtro = Filtro.pendientes),
                ),
                ChoiceChip(
                  label: const Text('Completas'),
                  selected: _filtro == Filtro.completas,
                  onSelected: (_) => setState(() => _filtro = Filtro.completas),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: StreamBuilder<List<Evento>>(
              stream: FirebaseService.instance.streamEventos(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final lista = _aplicarFiltros(snap.data ?? const []);
                if (lista.isEmpty) {
                  return const Center(child: Text('Sin eventos'));
                }
                return ListView.builder(
                  itemCount: lista.length,
                  itemBuilder: (context, i) {
                    final e = lista[i];
                    final fechaText = e.fecha == null
                        ? 'Sin fecha'
                        : '${e.fecha!.day.toString().padLeft(2, '0')}/${e.fecha!.month.toString().padLeft(2, '0')}/${e.fecha!.year}';

                    return Dismissible(
                      key: ValueKey(e.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Eliminar evento'),
                            content: Text('¿Eliminar "${e.nombre}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );
                        return ok == true;
                      },
                      onDismissed: (_) => _eliminarConUndo(e),
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          onLongPress: () => _eliminarConUndo(e), // extra: long-press elimina
                          leading: Checkbox(
                            value: e.reservado,
                            onChanged: (_) => _toggleReservado(e),
                          ),
                          title: Text(
                            e.nombre,
                            style: TextStyle(
                              decoration: e.reservado ? TextDecoration.lineThrough : TextDecoration.none,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${e.notas == null || e.notas!.isEmpty ? '' : '${e.notas} · '}Fecha: $fechaText',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (e.esVencido)
                                const _EstadoPill(color: Colors.orange, text: 'Vencido')
                              else if (e.reservado)
                                const _EstadoPill(color: Colors.green, text: 'Reservado')
                              else
                                const _EstadoPill(color: Colors.blueGrey, text: 'Pendiente'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearEventoModal,
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
    );
  }
}

class _EstadoPill extends StatelessWidget {
  final Color color;
  final String text;
  const _EstadoPill({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), // reemplazo de withOpacity
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)), // reemplazo de withOpacity
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _CrearEventoSheet extends StatefulWidget {
  const _CrearEventoSheet();

  @override
  State<_CrearEventoSheet> createState() => _CrearEventoSheetState();
}

class _CrearEventoSheetState extends State<_CrearEventoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  DateTime? _fecha;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFecha() async {
    final hoy = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day), // no puede ser anterior a hoy
      lastDate: DateTime(hoy.year + 5),
      initialDate: _fecha ?? hoy,
    );
    if (selected != null) setState(() => _fecha = selected);
  }

  void _crear() {
    if (_formKey.currentState!.validate()) {
      final nuevo = Evento(
        id: '', // Firestore asignará ID
        nombre: _tituloCtrl.text.trim(),
        fecha: _fecha,
        reservado: false,
        notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      );
      Navigator.pop(context, nuevo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nueva reserva / evento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(labelText: 'Título (obligatorio)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'El título es obligatorio' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notasCtrl,
                decoration: const InputDecoration(labelText: 'Notas (opcional)'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(_fecha == null
                        ? 'Sin fecha seleccionada'
                        : 'Fecha: ${_fecha!.day.toString().padLeft(2, '0')}/${_fecha!.month.toString().padLeft(2, '0')}/${_fecha!.year}'),
                  ),
                  TextButton.icon(
                    onPressed: _pickFecha,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Elegir fecha'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _crear,
                      child: const Text('Crear'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

