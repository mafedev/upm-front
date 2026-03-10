import 'package:flutter/material.dart';
import '../services/serial_service.dart';
import '../models/datos.dart';
import 'input_screen.dart';
import 'logs_screen.dart';

class HomeScreen extends StatefulWidget {
  final SerialService serialService;
  const HomeScreen({super.key, required this.serialService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Datos datos = Datos.empty();
  int _currentIndex = 0;
  bool _authenticated = false;
  bool _showPassword = false;

  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.serialService.stream.listen((line) {
      setState(() {
        datos.updateFromString(line);
      });
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CTB-UPM'),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      LogsScreen(serialService: widget.serialService),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [_homeTab(), _adminTab()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ],
      ),
    );
  }

  Widget _homeTab() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _card(
            'Sesiones restantes',
            datos.sesiones.toString(),
            Icons.timer,
            Colors.indigo,
          ),
          _card(
            'Total sesiones',
            datos.total.toString(),
            Icons.list_alt,
            Colors.teal,
          ),
          _card('Número de serie', datos.serial, Icons.numbers, Colors.orange),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => widget.serialService.send('2'),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Leer sesiones', style: TextStyle(fontSize: 16)),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => widget.serialService.send('3'),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Leer número de serie',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => widget.serialService.send('5'),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Leer sesiones totales',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminTab() {
    if (!_authenticated) {
      return Center(
        child: Container(
          width: 350,
          padding: EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings, size: 60, color: Colors.indigo),
              SizedBox(height: 10),
              Text(
                "Acceso Administrador",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: !_showPassword,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: _checkPassword,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Entrar', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () => _openInput(1, 'Número de sesiones'),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Cargar sesiones', style: TextStyle(fontSize: 16)),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _openInput(4, 'Nuevo número de serie'),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Cambiar número de serie',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _confirmResetTotal,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Reiniciar total sesiones',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          SizedBox(height: 20),
          TextButton(
            onPressed: () => setState(() => _authenticated = false),
            child: Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  void _checkPassword() {
    if (_passwordController.text.trim() == '1234') {
      setState(() {
        _authenticated = true;
        _passwordController.clear();
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Contraseña incorrecta')));
    }
  }

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

  void _confirmResetTotal() async {
    final TextEditingController codeCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Confirmar reinicio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ingrese la contraseña para reiniciar el total'),
            SizedBox(height: 8),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirmar'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (codeCtrl.text.trim() == '1234') {
        // Enviar comando 6 y luego el código de confirmación para Arduino
        widget.serialService.send('6');
        Future.delayed(Duration(milliseconds: 200), () {
          widget.serialService.sendWithTerminator('1234', terminator: '\r\n');
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Reinicio solicitado')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Código incorrecto')));
      }
    }
  }

Widget _card(String title, String value, IconData icon, Color color) {
  return Card(
    margin: EdgeInsets.symmetric(vertical: 10),
    child: Padding(
      padding: EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 30, color: color),
          ),

          SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
