class Datos {
  int sesiones;
  int total;
  String serial;

  Datos({required this.sesiones, required this.total, required this.serial});

  factory Datos.empty() => Datos(sesiones: 0, total: 0, serial: 'Sin configurar');

  void updateFromString(String line) {
    line = line.trim();
    if (line.startsWith('Sesiones restantes:')) {
      sesiones = int.tryParse(line.split(':').last.trim()) ?? sesiones;
    } else if (line.startsWith('Total sesiones realizadas:')) {
      total = int.tryParse(line.split(':').last.trim()) ?? total;
    } else if (line.startsWith('Numero serie:')) {
      serial = line.split(':').last.trim();
      if (serial.isEmpty) serial = 'Sin configurar';
    }
  }
}