class Evaluation {
  String title;
  String? note;
  DateTime? dueDate;
  bool isDone;

  Evaluation({
    required this.title,
    this.note,
    this.dueDate,
    this.isDone = false,
  });

  bool get isOverdue {
    if (isDone) return false;
    if (dueDate == null) return false;
    final now = DateTime.now();
    // solo vencida si la fecha es pasada (día anterior)
    return dueDate!.isBefore(DateTime(now.year, now.month, now.day));
  }
}
