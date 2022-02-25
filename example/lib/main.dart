import 'package:flutter/material.dart';

import 'package:grab/grab.dart';

final _notifier = ValueNotifier(0);

void main() => runApp(const App());

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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _Counter(),
              SizedBox(height: 16.0),
              _SlowCounter(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () => _notifier.value++,
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget with Grab {
  const _Counter();

  @override
  Widget build(BuildContext context) {
    // With context.grab(), the widget is rebuilt every time
    // the value of CounterNotifier is updated.
    final count = context.grab<int>(_notifier);

    return Text(
      '$count',
      style: const TextStyle(fontSize: 50.0),
    );
  }
}

class _SlowCounter extends StatelessWidget with Grab {
  const _SlowCounter();

  @override
  Widget build(BuildContext context) {
    // This count increases at one third the pace of the value
    // of CounterNotifier, like 0, 0, 0, 1, 1, 1, 2, 2, 2...
    // Updating the value of CounterNotifier doesn't trigger
    // rebuilds while the result of grabAt() here remains the same.
    final count = context.grabAt(_notifier, (int v) => v ~/ 3);

    return Text(
      '$count',
      style: const TextStyle(fontSize: 50.0),
    );
  }
}
