import 'package:flutter/material.dart';
import 'package:grab/grab.dart';

final _notifier = ValueNotifier(0);

void main() {
  runApp(
    const Grab(child: App()),
  );
}

class App extends StatefulWidget {
  const App();

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Counter(),
              SizedBox(height: 16.0),
              _SlowCounter(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _notifier.value++,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter();

  @override
  Widget build(BuildContext context) {
    // grab() rebuilds the widget every time
    // the value of the notifier is updated.
    final count = _notifier.grab(context);

    return Text(
      '$count',
      style: const TextStyle(fontSize: 50.0),
    );
  }
}

class _SlowCounter extends StatelessWidget {
  const _SlowCounter();

  @override
  Widget build(BuildContext context) {
    // This count increases at one third the pace of the value
    // of the notifier, like 0, 0, 0, 1, 1, 1, 2, 2, 2...
    // Updating the value of the notifier doesn't trigger rebuilds
    // while the result of grabAt() here remains the same.
    final count = _notifier.grabAt(context, (v) => v ~/ 3);

    return Text(
      '$count',
      style: const TextStyle(fontSize: 50.0),
    );
  }
}
