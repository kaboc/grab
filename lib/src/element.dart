import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'types.dart';

extension ListenableX on Listenable {
  R valueOrListenable<R>() {
    final listenable = this;
    return (listenable is ValueListenable ? listenable.value : listenable) as R;
  }
}

mixin GrabElement on ComponentElement {
  final Map<Listenable, VoidCallback> _listeners = {};
  final Map<Listenable, List<bool Function()>> _comparators = {};

  // Only for debugging
  var _debugCounter = 0;

  @override
  void unmount() {
    _reset();
    super.unmount();
  }

  @override
  void performRebuild() {
    // Properties need to be cleared before every rebuild.
    // Note that resetting at the timing of markNeedsBuild() in
    // _listener() instead of here is not enough because _listener()
    // is not triggered by causes other than update of listenable value.
    _reset();

    // _reset() must precede a rebuild. Don't change the order.
    super.performRebuild();
  }

  void _reset() {
    _removeAllListeners();
    _comparators.clear();
    _debugCounter = 0;
  }

  void _removeAllListeners() {
    _listeners
      ..forEach((listenable, listener) => listenable.removeListener(listener))
      ..clear();
  }

  bool _compare<R, S>(
    Listenable listenable,
    GrabSelector<R, S> selector,
    Object? prev,
  ) {
    final curr = selector(listenable.valueOrListenable());

    // If the selected value is the Listenable itself, it means
    // the user has chosen to make the widget get rebuilt whenever
    // the listenable notifies, so true is returned in that case.
    return curr == listenable || curr != prev;
  }

  void _listener(Listenable listenable) {
    final comparators = _comparators[listenable]!;

    for (var i = 0; i < comparators.length; i++) {
      final shouldRebuild = comparators[i]();
      if (shouldRebuild) {
        markNeedsBuild();
        break;
      }
    }
  }

  void _countForDebug() {
    // ignore: prefer_asserts_with_message
    assert(
      () {
        _debugCounter++;
        return true;
      }(),
    );
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
    _comparators[listenable] ??= [];
    _comparators[listenable]!
        .add(() => _compare(listenable, selector, selected));

    _countForDebug();

    return selected;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    final listeners = _listeners.keys.toList();
    properties
      ..add(IterableProperty<Listenable>('grabListenables', listeners))
      ..add(IntProperty('grabCount', _debugCounter));
  }
}
