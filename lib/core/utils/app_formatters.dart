/// Formatea un monto con separador de miles: $1.234
String fmtAmount(double v) {
  final n = v.round();
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '\$${buf.toString()}';
}

/// Fecha corta: "Hoy", "Ayer", "15 mar", "15 mar 2023"
String fmtDateShort(DateTime d) {
  const months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  if (day == today) return 'Hoy';
  if (day == today.subtract(const Duration(days: 1))) return 'Ayer';
  final yearSuffix = d.year != now.year ? ' ${d.year}' : '';
  return '${d.day} ${months[d.month - 1]}$yearSuffix';
}

/// Fecha larga con hora: "15 de marzo de 2025  ·  20:30"
String fmtDateLong(DateTime d) {
  const months = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '${d.day} de ${months[d.month - 1]} de ${d.year}  ·  $h:$m';
}
