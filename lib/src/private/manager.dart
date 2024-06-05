import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';

import '../typedefs.dart';
import 'finalizer.dart';
import 'rebuild_decider.dart';

/// Whether there has been at least one call to a grab method in
/// the current build of the widget associated with a BuildContext.
final Map<int, bool> _grabCallFlags = {};

@visibleForTesting
Map<int, bool> get grabCallFlags => Map.of(_grabCallFlags);

class GrabManager {
  final CustomFinalizer _finalizer = CustomFinalizer();

  final Map<int, Map<int, void Function()>> _listenerCancellers = {};
  final Map<int, Map<int, List<RebuildDecider<Object?, Object?>>>>
      _rebuildDeciders = {};

  /// Whether a hook is necessary to reset all the flags in `_grabCallFlags`
  /// at the beginning of the next build.
  bool _needsResetFlagsBeforeBuild = false;

  @visibleForTesting
  static void Function(({int contextHash, bool firstCall}))? onGrabCallEnd;

  @visibleForTesting
  Map<int, int> get listenerCounts {
    // The number of cancellers is the number of existing listeners.
    return {
      for (final hashCode in _listenerCancellers.keys)
        hashCode: _listenerCancellers[hashCode]!.length,
    };
  }

  void dispose() {
    _needsResetFlagsBeforeBuild = false;
    _grabCallFlags.clear();
    _finalizer.dispose();

    _listenerCancellers.clear();
    _rebuildDeciders.clear();
  }

  void onBeforeBuild() {
    if (_needsResetFlagsBeforeBuild) {
      _needsResetFlagsBeforeBuild = false;
      _grabCallFlags.clear();
    }
  }

  void _setFinalizers({
    required BuildContext context,
    required Listenable listenable,
  }) {
    _finalizer
      ..attachIfNotYet(
        context,
        onFinalized: (contextHash) {
          if (_listenerCancellers[contextHash]?.values case final cancellers?) {
            for (final canceller in cancellers) {
              canceller();
            }
          }
          _listenerCancellers.remove(contextHash);
          _rebuildDeciders.remove(contextHash);
        },
      )
      ..attachIfNotYet(
        listenable,
        onFinalized: (listenableHash) {
          for (final contextHash in _listenerCancellers.keys) {
            _listenerCancellers[contextHash]?[listenableHash]?.call();
            _listenerCancellers[contextHash]?.remove(listenableHash);
            _rebuildDeciders[contextHash]?.remove(listenableHash);
          }
        },
      );
  }

  S listen<R, S>({
    required BuildContext context,
    required Listenable listenable,
    required GrabSelector<R, S> selector,
  }) {
    _setFinalizers(context: context, listenable: listenable);

    final contextHash = context.hashCode;
    final listenableHash = listenable.hashCode;

    final isFirstCallInCurrentBuild = _grabCallFlags[contextHash] == null;
    if (isFirstCallInCurrentBuild) {
      _needsResetFlagsBeforeBuild = true;
      _grabCallFlags[contextHash] = true;
      _rebuildDeciders[contextHash]?.clear();
    }

    final wrContext = WeakReference(context);
    final wrListenable = WeakReference(listenable);
    final selectedValue = selector(listenable.listenableOrValue());

    _rebuildDeciders[contextHash] ??= {};
    _rebuildDeciders[contextHash]![listenableHash] ??= [];
    _rebuildDeciders[contextHash]![listenableHash]!.add(
      RebuildDecider<R, S>(
        wrListenable: wrListenable,
        selector: selector,
        prevSelectedValue: selectedValue,
      ),
    );

    final cancellers = _listenerCancellers[contextHash] ??= {};

    // Having no canceller for a combination of particular BuildContext
    // and Listenable means there is no listener for that combination yet.
    if (cancellers[listenableHash] == null) {
      void listener() {
        _triggerRebuildIfNecessary(
          wrContext: wrContext,
          wrListenable: wrListenable,
        );
      }

      listenable.addListener(listener);
      cancellers[listenableHash] = () {
        wrListenable.target?.removeListener(listener);
      };
    }

    if (kDebugMode) {
      onGrabCallEnd?.call(
        (contextHash: contextHash, firstCall: isFirstCallInCurrentBuild),
      );
    }

    return selectedValue;
  }

  void _triggerRebuildIfNecessary({
    required WeakReference<BuildContext> wrContext,
    required WeakReference<Listenable> wrListenable,
  }) {
    final elm = wrContext.target as Element?;
    final listenable = wrListenable.target;
    if (elm == null || elm.dirty || !elm.mounted || listenable == null) {
      return;
    }

    final deciders = _rebuildDeciders[elm.hashCode]?[listenable.hashCode];
    if (deciders == null) {
      return;
    }

    for (final decider in deciders) {
      if (decider.shouldRebuild()) {
        elm.markNeedsBuild();
        break;
      }
    }
  }
}
