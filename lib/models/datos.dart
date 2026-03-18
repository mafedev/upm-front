class Datos {
  int sesiones = 0;
  int total = 0;
  String serial = "";

  String get sesionesStr => sesiones.toString();
  String get totalStr => total.toString();

  Datos.empty();

  void updateFromString(String line) {
    print("📥 RECIBIDO: $line"); // 🔴 DEBUG CLAVE

    if (line.startsWith("RESP:SESIONES:")) {
      sesiones = int.tryParse(line.split(":").last) ?? sesiones;
    }

    else if (line.startsWith("RESP:TOTAL:")) {
      total = int.tryParse(line.split(":").last) ?? total;
    }

    else if (line.startsWith("RESP:SERIAL:")) {
      serial = line.split(":").sublist(2).join(":");
    }
  }
}