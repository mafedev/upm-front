import 'package:flutter/material.dart';
import '../services/serial_service.dart';
import 'input_screen.dart';

class AdminScreen extends StatefulWidget {
  final SerialService serialService; // servicio de comunicación serial, se pasa desde la pantalla principal para que pueda usarlo

  const AdminScreen({super.key, required this.serialService});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool authenticated = false; // se encarga de controlar si el usuario ha ingresado la contraseña correcta para mostrar las opciones de administración
  bool showPassword = false; // es la que controla si la contraseña se muestra o no en el TextField, por defecto no se muestra

  final TextEditingController passwordCtrl = TextEditingController(); // conrolador para la contraseña que se ingresa en el TextField, se usa para obtener el valor ingresado y para limpiar el campo después de ingresar la contraseña correcta

  // ---------- Verificación contraseña ----------
  void checkPassword() {
    // Si la contraseña ingresada corresponde con la contraseña correcta
    if (passwordCtrl.text.trim() == "1234") {
      // Cambia el estado de la variable a true, y limpia el campo de texto de la contraseña
      setState(() {
        authenticated = true;
        passwordCtrl.clear();
      });
    } else { // Si la contraseña es incorrecta, muestra un mensaje de error en un SnackBar
      ScaffoldMessenger.of(context,).showSnackBar(const SnackBar(content: Text("Contraseña incorrecta")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si el usuario no ha ingresado la contraseña correcta, muestra el formulario de ingreso de contraseña
    if (!authenticated) {
      return Center(
        child: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Acceso administrador",
                style: TextStyle(fontSize: 20),
              ),

              const SizedBox(height: 20),

              // ---------- TextField para ingresar la contraseña ----------
              TextField(
                controller: passwordCtrl,
                obscureText: !showPassword,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ---------- Botón para verificar la contraseña ----------
              ElevatedButton(
                onPressed: checkPassword,
                child: const Text("Entrar"),
              ),
            ],
          ),
        ),
      );
    }

    // Si la contraseña es correcta, muestra las opciones de administración
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ---------- Botón Cargar sesiones ----------
          ElevatedButton(
            onPressed: () => _openInput(1, "Número de sesiones"),
            child: const Text("Cargar sesiones"),
          ),

          // ---------- Botón Cambiar número de serie ----------
          ElevatedButton(
            onPressed: () => _openInput(4, "Nuevo número de serie"),
            child: const Text("Cambiar número de serie"),
          ),

          // ---------- Botón Reiniciar total sesiones ----------
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => widget.serialService.send("6"),
            child: const Text("Reiniciar total sesiones"),
          ),

          // ---------- Botón Cerrar sesión ----------
          TextButton(
            onPressed: () {
              setState(() {
                authenticated = false; // al presioanrlo pone authenticated en false para volver a mostrar el formulario de ingreso de contraseña, lo que simula el cierre de sesión
              });
            },
            child: const Text("Cerrar sesión"),
          ),
        ],
      ),
    );
  }

  // Función para abrir la pantalla de ingreso de datos
  // Se llama al presionar los botones de "Cargar sesiones" o "Cambiar número de serie", y se le pasan el comando correspondiente (1 para cargar sesiones, 4 para cambiar número de serie) y la etiqueta que se mostrará en la pantalla de ingreso de datos
  void _openInput(int command, String label) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InputScreen(
          serialService: widget.serialService,
          command: command,
          label: label,
        ),
      ),
    );
  }
}
