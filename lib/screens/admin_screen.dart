import 'package:flutter/material.dart';
import '../services/serial_service.dart';
import '../services/session_service.dart';
import 'input_screen.dart';

class AdminScreen extends StatefulWidget {

  final SerialService serialService; // servicio de comunicación serial, se pasa desde la pantalla principal para que pueda usarlo
  final SessionService sessionService; // servicio de manejo de sesión

  const AdminScreen({super.key, required this.serialService, required this.sessionService,
});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {

  final TextEditingController passwordCtrl = TextEditingController(); // conrolador para la contraseña que se ingresa en el TextField, se usa para obtener el valor ingresado y para limpiar el campo después de ingresar la contraseña correcta
  bool showPassword = false; // variable para controlar si la contraseña se muestra o se oculta en el TextField, se cambia al hacer click en el ojo

  // ---------- Verificación contraseña ----------
  void checkPassword() {
    // Usa el servicio para que verifique la contraseña ingresada
    widget.sessionService.login(passwordCtrl.text);

    // si la contraseña es correcta, se autentica la sesión y se muestra el panel de administración, si no, se muestra un mensaje de error
    if (widget.sessionService.authenticated) {
      // limpia el campo de TextField después de ingresar la contraseña
      setState(() {
        passwordCtrl.clear();
      });
    } else { // Si la contraseña es incorrecta, muestra un mensaje de error en un SnackBar
      ScaffoldMessenger.of(context, ).showSnackBar(const SnackBar(content: Text("Contraseña incorrecta")));
    }
  }

  // ---------- Cerrar sesión ----------
  void logout() {
    widget.sessionService.logout(); // llama al método de cerrar sesión del servicio
    setState(() {}); // actualiza la UI para mostrar el formulario de login nuevamente
  }

  // ---------- Confirmar reinicio total de sesiones ----------
  // Es la ventana de confirmación que se muestra al hacer click en el botón de reiniciar total de sesiones, para evitar que se reinicie por error
  Future<void> confirmReset() async {

    // si el usuario confirma que quiere reiniciar, se envía el comando '6' al arduino
    final result = await showDialog<bool>( // si se presiona "Reiniciar", devuelve un true
      context: context, // contexto actual para mostrar el diálogo
      
      builder: (_) => AlertDialog(
        title: const Text('Reiniciar total sesiones'), // título del diálogo
        content: const Text('¿Está seguro que desea reiniciar el total de sesiones?'),
        actions: [
          // -------- Botón de cancelar --------
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context, false), // si lo presiona, cierra el dialogo y devuelve un false
          ),
          
          // -------- Botón de reiniciar --------
          TextButton(
            child: const Text("Reiniciar"),
            onPressed: () => Navigator.pop(context, true), // si lo presiona, cierra el dialogo y devuelve un true
          ),
        ],
      ),
    );

    // Si se confirmó el reinicio
    if (result == true) {
      widget.serialService.send('6'); // envía el '6' al arduino para reiniciar

      // Hace un retraso para asegurarse de que el comando se envió antes de mostrar el mensaje, ya que el envío es asíncrono
      Future.delayed(
        const Duration(milliseconds: 200),
        () => widget.serialService.send('1234'), // envía el '1234' al arduino para confirmar la acción
      );

      // si salió bien, muestra el mensaje
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reinicio solicitado')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtiene el estado de autenticación de la sesión para mostrar el formulario de login o el panel de administración según corresponda
    final authenticated = widget.sessionService.authenticated;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.medical_services, size: 32, color: Colors.white),
            SizedBox(width: 10),
            Text(
              "CTB-UPM",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E88E5),
        actions: authenticated
            ? [
                // Si la sesión está autenticada, muestra el botón de cerrar sesión en la barra de navegación
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: logout,
                ),
              ]
            : null,
      ),

      backgroundColor: const Color(0xFFE3F2FD),

      body: Center(
        // Si no está autenticado, muestra el formulario de login, si está autenticado, muestra el panel de administración
        child: !authenticated ? _buildLoginCard() : _buildAdminPanel(),
      ),
    );
  }

  // ---------- Card de login ----------
  Widget _buildLoginCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono y título del acceso de administrador
            const Icon(Icons.admin_panel_settings, size: 60, color: Color(0xFF1E88E5)),

            const SizedBox(height: 10),

            const Text("Acceso Administrador", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            // ---------- TextField para ingresar la contraseña ----------
            TextField(
              controller: passwordCtrl,
              obscureText: !showPassword,
              keyboardType: TextInputType.number, // tipo de teclado
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelText: 'Contraseña',
                filled: true,
                fillColor: Colors.grey.shade100,
                
                // Icono para mostrar u ocultar la contraseña, cambia según el estado de showPassword
                suffixIcon: IconButton(
                  icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword; // cambia el estado para mostrar u ocultar la contraseña al hacer click en el icono del ojo
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ---------- Botón para verificar la contraseña ----------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: checkPassword, // llama a la función de verificar contraseña al hacer click
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  "Entrar",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Panel de administración ----------
  Widget _buildAdminPanel() {
    return Padding(
      padding: const EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título de la página
          const Text(
            "Panel de Administración",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E88E5),
            ),
          ),

          const SizedBox(height: 20),

          // ---------- Botones ----------
          Expanded( // expande para ocupar el espacio disponible
            child: GridView( // vista de cuadricula para los botones
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount( // estructura de la cuadrícula
                crossAxisCount: 2, // columnas
                crossAxisSpacing: 15, // espacio entre columnas
                mainAxisSpacing: 15, // espacio entre filas
                childAspectRatio: 4, // tamaño
              ),

              children: [
                // ---------- Botón Cargar sesiones ----------
                _dashboardButton(
                  icon: Icons.add_task,
                  label: "Cargar sesiones",
                  color: const Color(0xFF43A047),
                  onTap: () => _openInput(1, "Número de sesiones"), // abre la pantalla de input para cargar sesiones, con el comando '1' para indicarle al arduino qué acción realizar
                ),

                // ---------- Botón Cambiar número de serie ----------
                _dashboardButton(
                  icon: Icons.edit,
                  label: "Cambiar número de serie",
                  color: const Color(0xFF1E88E5),
                  onTap: () => _openInput(4, "Nuevo número de serie"), // abre la pantalla de input para cambiar el número de serie, con el comando '4' para que el arduino sepa qué acción realizar
                ),

                // ---------- Botón Reiniciar total sesiones ----------
                _dashboardButton(
                  icon: Icons.restart_alt,
                  label: "Reiniciar total sesiones",
                  color: Colors.red,
                  onTap: confirmReset, // llama a la función de confirmación de reinicio al hacer click
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Widget para los botones del panel de administración ----------
  Widget _dashboardButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell( // InkWell es un widget que detecta gestos de toque, se usa para hacer los botones interactivos
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),

      // Ink es un widget que se usa para decorar el botón, se coloca dentro de InkWell para que la decoración se aplique al área del botón y no solo al contenido
      child: Ink(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 4)),
          ],
        ),

        // Contenido del botón, con un icono y un texto, centrados
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Función para abrir la pantalla de input ----------
  // Recibe el comando y la etiqueta para mostrar en la pantalla de input, y navega a esa pantalla pasando el servicio de comunicación serial para que pueda enviar el comando al arduino con el valor ingresado por el usuario
  void _openInput(int command, String label) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InputScreen( // navega a la pantalla de input
          serialService: widget.serialService, // pasa el servicio de comunicación serial para que la pantalla de input pueda enviar el comando al arduino
          command: command, // le pasa es comando
          label: label, // y la etiqueta
        ),
      ),
    );
  }
}
