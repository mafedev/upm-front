import 'dart:io';
import 'serial_service.dart';
import 'serial_android.dart';
import 'serial_windows.dart';

SerialService createSerialService() {
  if (Platform.isWindows) {
    return WindowsSerialService();
  } else {
    return SerialAndroidService();
  }
}