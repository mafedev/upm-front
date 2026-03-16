class Datos {
  // Son ? porque al inicio no tenemos datos, y el string serial se inicializa a '-' para mostrar algo en la UI antes de recibir datos reales
  int? sesiones;
  int? total;
  String serial;

  Datos({this.sesiones, this.total, this.serial = '-'});

  factory Datos.empty() => Datos(sesiones: null, total: null, serial: '-');

  void updateFromString(String line) {
    line = line.trim(); // eliminamos espacios en blanco al inicio y al final de la línea para evitar problemas al parsear los datos

    // Si la línea recibida empieza con "Sesiones restantes:", extraemos el número de sesiones restantes
    if (line.startsWith('Sesiones restantes:')) {
      sesiones = int.tryParse(line.split(':').last.trim());

    // Si la línea recibida empieza con "Total sesiones realizadas:", extraemos el número total de sesiones realizadas
    } else if (line.startsWith('Total sesiones realizadas:')) {
      total = int.tryParse(line.split(':').last.trim());

    // Si la línea recibida empieza con "Numero serie:", extraemos el número de serie, si no hay número de serie se muestra '-' en la UI
    } else if (line.startsWith('Numero serie:')) {
      serial = line.split(':').last.trim();
      if (serial.isEmpty) serial = '-';
    }
  }

  // convierte los datos a string para mostrarlos en la UI, si no hay datos muestra '-' en lugar de null
  String get sesionesStr => sesiones?.toString() ?? '-';
  String get totalStr => total?.toString() ?? '-';
}