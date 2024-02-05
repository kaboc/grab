import 'dart:developer' show reachabilityBarrier;

import 'package:flutter_test/flutter_test.dart';

const _kFullGcCycles = 2;

// Simplified version of https://github.com/dart-lang/leak_tracker/blob/db1e95b4c34fd572e2f3c7e8eb1ca099fab681e8/pkgs/leak_tracker/lib/src/leak_tracking/helpers.dart#L25-L48.
//
// This does not seem to work in widget tests.
Future<void> forceGC() async {
  final barrier = reachabilityBarrier + _kFullGcCycles;
  final storage = <List<int>>[];

  void allocateMemory() {
    storage.add(List.generate(30000, (n) => n));
    if (storage.length > 100) {
      storage.removeAt(0);
    }
  }

  while (reachabilityBarrier < barrier) {
    await Future<void>.delayed(Duration.zero);
    allocateMemory();
  }
}
