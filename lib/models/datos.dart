class Datos {
  int? sesiones;
  int? total;
  String serial;

  Datos({this.sesiones, this.total, this.serial = '-'});

  factory Datos.empty() => Datos(sesiones: null, total: null, serial: '-');

  /// Actualiza los datos a partir de una línea recibida del Arduino
  void updateFromString(String line) {
    line = line.trim();

    if (line.startsWith('Sesiones restantes:')) {
      sesiones = int.tryParse(line.split(':').last.trim());
    } else if (line.startsWith('Total sesiones realizadas:')) {
      total = int.tryParse(line.split(':').last.trim());
    } else if (line.startsWith('Numero serie:')) {
      serial = line.split(':').last.trim();
      if (serial.isEmpty) serial = '-';
    }
  }

  /// Representación en String para la UI
  String get sesionesStr => sesiones?.toString() ?? '-';
  String get totalStr => total?.toString() ?? '-';
}