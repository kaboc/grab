import 'dart:async';

import 'package:flutter/foundation.dart';

class StreamValueNotifier<T> extends ValueNotifier<T?> {
  StreamValueNotifier(Stream<T> stream) : super(null) {
    _subscription = stream.listen((data) => value = data);
  }

  late final StreamSubscription<T> _subscription;

  @override
  void dispose() {
    // ignore: discarded_futures
    _subscription.cancel();
    super.dispose();
  }
}
