/// Texto amigable de cuánto falta para una fecha ("Termina mañana", "Termina
/// en 3 días") en vez de mostrar la fecha pelona — se usa en las tarjetas
/// de límites para que se sienta más cercano/humano.
String friendlyRemaining(DateTime target) {
  final now = DateTime.now();
  final difference = target.difference(now);

  if (difference.isNegative) return 'Venció';
  if (difference.inDays >= 2) return 'Termina en ${difference.inDays} días';
  if (difference.inHours >= 24) return 'Termina mañana';
  if (difference.inHours >= 1) {
    return 'Termina en ${difference.inHours} '
        '${difference.inHours == 1 ? "hora" : "horas"}';
  }
  return 'Termina en menos de una hora';
}
