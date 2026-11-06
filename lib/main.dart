import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:everfold/src/rust/api/simple.dart';
import 'package:everfold/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _useCupertino = false;

  void _toggleStyle() {
    setState(() => _useCupertino = !_useCupertino);
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Action: Call Rust `greet("Tom")`\nResult: `${greet(name: "Tom")}`',
              ),
              const SizedBox(height: 24),
              if (_useCupertino)
                CupertinoButton.filled(
                  onPressed: _toggleStyle,
                  child: const Text('切换到 Material'),
                )
              else
                FilledButton(
                  onPressed: _toggleStyle,
                  child: const Text('切换到 Cupertino'),
                ),
            ],
          ),
        ),
      ),
    );

    if (_useCupertino) {
      return CupertinoApp(
        home: CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Everfold · Cupertino'),
          ),
          child: content,
        ),
      );
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Everfold · Material')),
        body: content,
      ),
    );
  }
}
