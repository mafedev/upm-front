class Datos {
  int sesiones = 0;
  int total = 0;
  String serial = "";

  void updateFromLine(String line) {
    if (line.startsWith("SESIONES:")) {
      sesiones = int.tryParse(line.split(":")[1]) ?? sesiones;
    }

    if (line.startsWith("TOTAL:")) {
      total = int.tryParse(line.split(":")[1]) ?? total;
    }

    if (line.startsWith("SERIAL:")) {
      serial = line.split(":")[1];
    }
  }
}