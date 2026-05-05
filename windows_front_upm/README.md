# App versión escritorio

Aplicación de escritorio (Windows) desarrollada en Flutter, orientada a la administración de dispositivos y sesiones. Incluye un panel de administración para gestionar dispositivos, recargar sesiones y consultar el historial de acciones.

## Características principales
- Panel de administración para crear, eliminar y gestionar dispositivos.
- Recarga de sesiones y visualización del historial de acciones por dispositivo.
- Interfaz adaptada a escritorio con gestión de ventana personalizada.

## Estructura del proyecto
- `lib/main.dart`: Punto de entrada de la app
- `lib/screens/`: Pantallas principales
- `lib/services/`:
  - `admin_service.dart`: Gestiona la comunicación HTTP con el backend y la autenticación mediante token
- `lib/models/`: Modelos de datos utilizados en la app
- `lib/widgets/`: Componentes visuales reutilizables
- `.env`: Variables de entorno (NO contiene datos reales)

## Dependencias principales
- **flutter_dotenv**: Carga variables de entorno desde archivos `.env`.
- **http**: Realiza peticiones HTTP al backend.
- **window_manager**: Permite controlar el tamaño, posición y visibilidad de la ventana en Windows.
- **shared_preferences**: Almacena preferencias y datos simples de usuario localmente.

## Autenticación

> [!IMPORTANT]
> La app utiliza un API Token para autenticarse con el backend.
> Este debe definirse en el archivo .env y debe coincidir con el token configurado en el backend

## Instalación y ejecución
1. Copia el archivo `.env` y reemplaza los valores de ejemplo por los reales:
	- `BASE_URL`: URL del backend
	- `API_TOKEN`: API key del backend
2. Instala dependencias:
	```sh
	flutter pub get
	```
3. Ejecuta la app en Windows:
	```sh
	flutter run -d windows
	```
