class Evento {
  final String id; // útil para Firebase más adelante
  final String nombre;
  final DateTime? fecha; // puede ser opcional
  bool reservado; // equivalente a isDone
  String? notas;

  Evento({
    required this.id,
    required this.nombre,
    required this.fecha,
    this.reservado = false,
    this.notas,
  });

  bool get esVencido {
    if (fecha == null) return false;
    final hoy = DateTime.now();
    final f = DateTime(fecha!.year, fecha!.month, fecha!.day);
    final h = DateTime(hoy.year, hoy.month, hoy.day);
    return f.isBefore(h) && !reservado;
  }
}