class Datos {
  // Son ? porque al inicio no tenemos datos, y el string serial se inicializa a '-' para mostrar algo en la UI antes de recibir datos reales
  int? sesiones;
  int? total;
  String serial;

  Datos({this.sesiones, this.total, this.serial = '-'});

  factory Datos.empty() => Datos(sesiones: null, total: null, serial: '-');

  void updateFromString(String line) {
    line = line.trim();

    // Aceptamos varios formatos que puede enviar el Arduino:
    // - Formato compacto: "SESIONES:5,TOTAL:10,SERIAL:1234"
    // - Líneas sueltas: "SESIONES:5" o "TOTAL:10" o "SERIAL:1234"
    // - Texto antiguo en español: "Sesiones restantes: 5"

    if (line.isEmpty) return;

    final up = line.toUpperCase();

    // Formato compacto con separador ','
    if (line.contains(',') && (up.contains('SESIONES') || up.contains('TOTAL') || up.contains('SERIAL'))) {
      final parts = line.split(',');
      for (final p in parts) {
        final kv = p.split(':');
        if (kv.length < 2) continue;
        final key = kv[0].trim().toUpperCase();
        final value = kv.sublist(1).join(':').trim();
        if (key == 'SESIONES') sesiones = int.tryParse(value);
        if (key == 'TOTAL') total = int.tryParse(value);
        if (key == 'SERIAL') serial = value.isEmpty ? '-' : value;
      }
      return;
    }

    // Formato por línea KEY:VALUE
    if (up.startsWith('SESIONES:')) {
      sesiones = int.tryParse(line.split(':').last.trim());
      return;
    }

    if (up.startsWith('TOTAL:')) {
      total = int.tryParse(line.split(':').last.trim());
      return;
    }

    if (up.startsWith('SERIAL:')) {
      serial = line.split(':').last.trim();
      if (serial.isEmpty) serial = '-';
      return;
    }

    // Compatibilidad con el formato en español antiguo
    if (line.startsWith('Sesiones restantes:')) {
      sesiones = int.tryParse(line.split(':').last.trim());
    } else if (line.startsWith('Total sesiones realizadas:')) {
      total = int.tryParse(line.split(':').last.trim());
    } else if (line.startsWith('Numero serie:')) {
      serial = line.split(':').last.trim();
      if (serial.isEmpty) serial = '-';
    }
  }

  // convierte los datos a string para mostrarlos en la UI, si no hay datos muestra '-' en lugar de null
  String get sesionesStr => sesiones?.toString() ?? '-';
  String get totalStr => total?.toString() ?? '-';
}