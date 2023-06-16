import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'types.dart';

extension on Listenable {
  R listenableOrValue<R>() {
    final listenable = this;
    return (listenable is ValueListenable ? listenable.value : listenable) as R;
  }
}

mixin GrabElement on ComponentElement {
  final Map<Listenable, VoidCallback> _listeners = {};
  final Map<Listenable, List<ValueGetter<bool>>> _comparators = {};

  // Only for debugging
  // The value is reset on every build.
  int _grabCallCounter = 0;

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

    // This must be after _reset(). Don't change the order.
    super.performRebuild();
  }

  void _reset() {
    _removeAllListeners();
    _comparators.clear();
    _debug(() => _grabCallCounter = 0);
  }

  void _removeAllListeners() {
    _listeners
      ..forEach((listenable, listener) => listenable.removeListener(listener))
      ..clear();
  }

  bool _compare<R, S>(
    Listenable listenable,
    GrabSelector<R, S> selector,
    Object? value,
  ) {
    final newValue = selector(listenable.listenableOrValue());

    // If the selected value is the Listenable itself, it means
    // the user has chosen to make the widget get rebuilt whenever
    // the listenable notifies, so true is returned in that case.
    return newValue == listenable || newValue != value;
  }

  void _listener(Listenable listenable) {
    if (dirty) {
      return;
    }

    final comparators = _comparators[listenable]!;

    for (var i = 0; i < comparators.length; i++) {
      final shouldRebuild = comparators[i]();
      if (shouldRebuild) {
        markNeedsBuild();
        break;
      }
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

    final value = selector(listenable.listenableOrValue());
    _comparators[listenable] ??= [];
    _comparators[listenable]!.add(() => _compare(listenable, selector, value));

    _debug(() => _grabCallCounter++);

    return value;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    final listeners = _listeners.keys.toList();
    properties
      ..add(IterableProperty<Listenable>('grabListenables', listeners))
      ..add(IntProperty('grabCallCounter', _grabCallCounter));
  }
}

void _debug(void Function() func) {
  // ignore: prefer_asserts_with_message
  assert(
    () {
      func();
      return true;
    }(),
  );
}
