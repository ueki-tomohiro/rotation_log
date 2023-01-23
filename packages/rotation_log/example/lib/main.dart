import 'dart:async';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:rotation_log/rotation_log.dart';
import 'package:logger/logger.dart';

final term = RotationLogTerm.term(RotationLogTermEnum.daily);
final log = RotationLogger(term);

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await log.init();
  await runZonedGuarded(() async {
    runApp(const MyApp());
  }, log.exception);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Rotation Log'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _addLog() {
    setState(() {
      _counter++;
      log.log(_counter % 2 == 0 ? Level.info : Level.error, "message$_counter");
    });
  }

  Future _downloadLog() async {
    final logFile = await log.archiveLog();
    await OpenFile.open(logFile);
    await log.init();
  }

  @override
  Future<void> dispose() async {
    await log.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Add log:',
              ),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headline4,
              ),
            ],
          ),
        ),
        floatingActionButton: Container(
          margin: const EdgeInsets.only(left: 24),
          child: Row(
            children: [
              FloatingActionButton(
                onPressed: _downloadLog,
                tooltip: 'Download',
                child: const Icon(Icons.download),
              ),
              const SizedBox(
                width: 8,
              ),
              FloatingActionButton(
                onPressed: _addLog,
                tooltip: 'Add log',
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ));
  }
}
