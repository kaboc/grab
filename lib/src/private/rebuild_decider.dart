import 'package:flutter/foundation.dart' show Listenable, ValueListenable;

import '../typedefs.dart';

extension ListenableOrValue on Listenable {
  R listenableOrValue<R>() {
    final listenable = this;
    return (listenable is ValueListenable ? listenable.value : listenable) as R;
  }
}

class RebuildDecider<R, S> {
  const RebuildDecider({
    required this.wrListenable,
    required this.selector,
    required this.prevSelectedValue,
  });

  final WeakReference<Listenable> wrListenable;
  final GrabSelector<R, S> selector;
  final S? prevSelectedValue;

  bool shouldRebuild() {
    final listenable = wrListenable.target;
    if (listenable == null) {
      return false;
    }

    final newSelectedValue = selector(listenable.listenableOrValue());

    // If the selected value is the Listenable itself, it means
    // the user has chosen to make the widget get rebuilt whenever
    // the Listenable notifies, so true is returned in that case.
    return newSelectedValue == listenable ||
        newSelectedValue != prevSelectedValue;
  }
}
