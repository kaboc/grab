import 'dart:async' show Timer;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';

import '../typedefs.dart';
import 'finalizer.dart';
import 'rebuild_decider.dart';

const kRebuildDecidersCleanUpDelay = Duration(seconds: 2);

class GrabManager {
  final CustomFinalizer _finalizer = CustomFinalizer();

  final Map<int, Map<int, void Function()>> _listenerCancellers = {};
  final Map<int, WeakReference<BuildContext>> _wrContexts = {};
  final Map<int, Map<int, List<RebuildDecider<Object?, Object?>>>>
      _rebuildDeciders = {};

  /// Whether there has been at least one call to a grab method in
  /// the current build of the widget associated with a BuildContext.
  final Map<int, bool> _grabCallFlags = {};

  /// Whether a hook is necessary to reset all the flags in `_grabCallFlags`
  /// at the beginning of the next build.
  bool _needsResetFlagsBeforeBuild = false;

  Timer? _rebuildDecidersCleanupTimer;

  @visibleForTesting
  Map<int, bool> get grabCallFlags => Map.of(_grabCallFlags);

  @visibleForTesting
  void Function(({int contextHash, bool firstCall}))? onGrabCallEnd;

  @visibleForTesting
  List<int> get existingContextHash => _wrContexts.keys.toList();

  @visibleForTesting
  bool get isAwaitingCleanUp => _rebuildDecidersCleanupTimer?.isActive ?? false;

  @visibleForTesting
  Map<int, int> get listenerCounts {
    // The number of cancellers is the number of existing listeners.
    return {
      for (final hashCode in _listenerCancellers.keys)
        hashCode: _listenerCancellers[hashCode]!.length,
    };
  }

  void dispose() {
    _rebuildDecidersCleanupTimer?.cancel();
    _rebuildDecidersCleanupTimer = null;

    _needsResetFlagsBeforeBuild = false;
    _grabCallFlags.clear();
    _finalizer.dispose();

    _listenerCancellers.clear();
    _wrContexts.clear();
    _rebuildDeciders.clear();
  }

  void onBeforeBuild({Duration cleanUpDelay = kRebuildDecidersCleanUpDelay}) {
    if (_needsResetFlagsBeforeBuild) {
      _needsResetFlagsBeforeBuild = false;
      _grabCallFlags.clear();
    }

    // Debounces clean-up to avoid causing poor performance while the app
    // is busy building widgets repeatedly without a break.
    // Even if not doing it, a short wait here is important because
    // otherwise clean-up is performed on every build, which is too much.
    _rebuildDecidersCleanupTimer?.cancel();
    _rebuildDecidersCleanupTimer =
        Timer(cleanUpDelay, _removeUnnecessaryRebuildDeciders);
  }

  Future<void> _removeUnnecessaryRebuildDeciders() async {
    // Storing GrabSelectors is necessary, but it prevents BuildContext from
    // being removed. (i.e. BuildContext becomes unmounted but keeps existing,
    // because of which the finalizer for the BuildContext is not called.)
    // So selectors for unmounted BuildContexts need to be manually removed.
    //
    // Note:
    // Holding a weak reference instead of a selector itself does not resolve
    // the above issue. It causes the selector to become unreferenced at the
    // end of `listen()`, making it already unavailable when needed later.
    for (var i = _wrContexts.entries.length - 1; i >= 0; i--) {
      final contextHash = _wrContexts.keys.elementAt(i);
      if (_wrContexts[contextHash]?.target case final context?) {
        if (!context.mounted) {
          _wrContexts.remove(contextHash);
          _rebuildDeciders.remove(contextHash);
        }
      }

      // Prevents blocking that may be visible when there are
      // a huge number of elements in the list being looped through.
      await Future<void>.delayed(Duration.zero);
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
          _wrContexts.remove(contextHash);
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

    _wrContexts[contextHash] ??= wrContext;
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
