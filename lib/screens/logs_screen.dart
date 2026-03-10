import 'package:flutter/material.dart';
import '../services/serial_service.dart';

class LogsScreen extends StatefulWidget {
  final SerialService serialService;
  const LogsScreen({super.key, required this.serialService});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.serialService.stream.listen((line) {
      setState(() {
        _logs.add(line);
        // autoscroll al final
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Logs Arduino')),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _logs.length,
        itemBuilder: (_, index) => ListTile(
          title: Text(_logs[index]),
        ),
      ),
    );
  }
}