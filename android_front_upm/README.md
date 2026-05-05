# App versión móvil

Aplicación móvil Android desarrollada en Flutter para usuarios finales. Permite la gestión y transferencia de sesiones entre la app y un dispositivo Arduino, así como la lectura de datos del mismo. **No incluye funciones administrativas.**

## Características principales
- Conexión automática y comunicación serie con Arduino vía USB
- Transferencia de sesiones almacenadas en el backend al Arduino
- Lectura de datos y estado del dispositivo en tiempo real

## Estructura del proyecto
- `lib/main.dart`: Punto de entrada de la app
- `lib/screens/`: Pantallas principales (inicio, transferencia, etc.)
- `lib/services/`:
  - `serial_service.dart`: Maneja la conexión y comunicación USB con Arduino
  - `session_service.dart`: Gestiona la comunicación HTTP con el backend para obtener y transferir sesiones
- `lib/theme/`: Definición de estilos y colores reutilizables
- `lib/widgets/`: Componentes visuales reutilizables
- `.env`: Variables de entorno (NO contiene datos reales)

## Dependencias principales
- **flutter_dotenv**: Carga variables de entorno desde archivos `.env`.
- **http**: Realiza peticiones HTTP al backend.
- **usb_serial**: Permite la comunicación USB con dispositivos Arduino.

## Instalación y ejecución
1. Copia el archivo `.env` y reemplaza los valores de ejemplo por los reales:
	- `BASE_URL`: URL del backend

2. Descarga la app en tu dispositivo Android o ejecútala desde un emulador:
    ```sh
    flutter run -d android
    ```

3. Luego de descargarla, conecta el arduino al móvil y acepta los permisos de conexión USB para que la app pueda comunicarse con el dispositivo
