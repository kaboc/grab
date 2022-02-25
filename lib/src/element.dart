import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

typedef GrabSelector<R, S> = S Function(R);

extension ListenableX on Listenable {
  R valueOrListenable<R>() {
    final listenable = this;
    return (listenable is ValueListenable ? listenable.value : listenable) as R;
  }
}

mixin GrabElement on ComponentElement {
  final Map<Listenable, VoidCallback> _listeners = {};
  final Map<Listenable, List<bool Function(int)>> _comparators = {};
  final List<Object?> _prevValues = [];

  @override
  void unmount() {
    _reset();
    super.unmount();
  }

  @override
  void performRebuild() {
    // Resetting must be ahead of a rebuild.
    _reset();
    super.performRebuild();
  }

  void _reset() {
    _removeAllListeners();
    _comparators.clear();
    _prevValues.clear();
  }

  void _removeAllListeners() {
    _listeners.forEach((listenable, listener) {
      listenable.removeListener(listener);
    });
    _listeners.clear();
  }

  bool _compare<R, S>(
    int index,
    Listenable listenable,
    GrabSelector<R, S> selector,
  ) {
    final prev = _prevValues[index];
    final curr = selector(listenable.valueOrListenable());

    _prevValues[index] = curr;

    // If the selected value is the Listenable itself, it means
    // the user has chosen to make the widget get rebuilt whenever
    // the listenable notifies, so true is returned in that case.
    return curr == listenable || curr != prev;
  }

  void _listener(Listenable listenable) {
    var shouldRebuild = false;

    final comparators = _comparators[listenable]!;

    for (var i = 0; i < comparators.length; i++) {
      // The loop has to be continued even after shouldRebuild turns
      // true to update all previous values by iterating until the end.
      shouldRebuild |= comparators[i](i);
    }

    if (shouldRebuild) {
      _reset();
      markNeedsBuild();
    }
  }

  S listen<R, S>({
    required Listenable listenable,
    required GrabSelector<R, S> selector,
  }) {
    if (!_listeners.containsKey(listenable)) {
      _listeners[listenable] = () => _listener(listenable);
      listenable.addListener(_listeners[listenable]!);
    }

    final selected = selector(listenable.valueOrListenable());
    _prevValues.add(selected);

    _comparators[listenable] ??= [];
    _comparators[listenable]!.add((i) => _compare(i, listenable, selector));

    return selected;
  }
}
