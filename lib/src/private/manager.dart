import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'handler.dart';

typedef _WrBuildContext = WeakReference<BuildContext>;

/// The signature for the `selector` callback of `grabAt()` that receives
/// an object of type [R] and returns an object of type [S].
typedef GrabSelector<R, S> = S Function(R);

extension on Listenable {
  R listenableOrValue<R>() {
    final listenable = this;
    return (listenable is ValueListenable ? listenable.value : listenable) as R;
  }
}

extension on Map<int, Map<Listenable, RebuildHandler>> {
  void reset(int contextHash) {
    this[contextHash]
      ?..forEach((_, v) => v.dispose())
      ..clear();
    remove(contextHash);
  }
}

extension on Expando<bool> {
  void reset(_WrBuildContext wrContext) {
    if (wrContext.target case final context?) {
      this[context] = null;
    }
  }
}

class GrabManager {
  final Map<int, _WrBuildContext> _wrContexts = {};

  /// Handlers per BuildContext.
  final Map<int, Map<Listenable, RebuildHandler>> _handlers = {};

  /// Grab method call flag per BuildContext.
  ///
  /// This is used to decide whether it is the first call to a grab method in
  /// the current build of the widget associated with a certain BuildContext.
  /// The decision is necessary so that the previous handlers are reset at
  /// the beginning of the build.
  final Expando<bool> _grabCalls = Expando();

  /// Finalizer that removes an entry corresponding to a GCed BuildContext
  /// from `_wrContexts` and `_handlers` after the BuildContext becomes
  /// unreachable. Handlers are not only removed but also disposed.
  ///
  /// The callback may not be called quickly when the BuildContext loses
  /// all references, but it is not so big an issue. Even if unnecessary
  /// listeners still remain in `_handlers` before finalization, they are
  /// ignored after the relevant BuildContexts are unmounted.
  ///
  /// `_grabCallFlags` does not have to be finalized here because it has
  /// only boolean values, which does not require disposal, and also it
  /// is an `Expando` with BuildContexts held weakly as keys, meaning
  /// entries for old BuildContexts are purged automatically.
  late final Finalizer<int> _finalizer = Finalizer((contextHash) {
    _wrContexts.remove(contextHash);
    _handlers.reset(contextHash);
  });

  bool _isGrabCallsUpdated = false;

  // If a callback is assigned, it is called with a record when handlers
  // for a particular BuildContext are reset. The record has the hashCode
  // of the BuildContext and a boolean value indicating whether resetting
  // was performed.
  @visibleForTesting
  static void Function(({int contextHash, bool wasReset}))? onHandlersReset;

  @visibleForTesting
  Iterable<int> get contextHashes => _wrContexts.keys;

  @visibleForTesting
  Map<int, int?> get handlerCounts => Map.fromEntries(
        _handlers.entries.map((v) => MapEntry(v.key, v.value.length)),
      );

  void dispose() {
    for (final MapEntry(key: hash, value: wrContext) in _wrContexts.entries) {
      _handlers.reset(hash);
      _grabCalls.reset(wrContext);

      if (wrContext.target case final context?) {
        _finalizer.detach(context);
      }
    }
    _isGrabCallsUpdated = false;
  }

  /// Resets flags in `_grabCalls` before starting to build widgets.
  ///
  /// Skipped when unnecessary. If not skipped, all BuildContexts
  /// held in the GrabManager are iterated although no flags are set,
  /// which is meaningless and should be avoided.
  void onBeforeBuild() {
    if (_isGrabCallsUpdated) {
      _isGrabCallsUpdated = false;
      _wrContexts.values.forEach(_grabCalls.reset);
    }
  }

  S listen<R, S>({
    required BuildContext context,
    required Listenable listenable,
    required GrabSelector<R, S> selector,
  }) {
    final contextHash = context.hashCode;
    _finalizer.attach(context, contextHash, detach: context);

    _wrContexts[contextHash] ??= WeakReference(context);

    // Clears the previous handlers for the provided BuildContext
    // only when this is the first call in the current build of
    // the widget associated with the BuildContext.
    final shouldResetHandlers = _grabCalls[context] == null;
    if (shouldResetHandlers) {
      _grabCalls[context] = true;
      _isGrabCallsUpdated = true;

      _handlers.reset(contextHash);
      _handlers[contextHash] ??= {};
    }
    onHandlersReset?.call(
      (contextHash: contextHash, wasReset: shouldResetHandlers),
    );

    _handlers[contextHash]?.putIfAbsent(listenable, () {
      void listener() => _listener(listenable, contextHash);
      listenable.addListener(listener);
      return RebuildHandler(
        listenerRemover: () => listenable.removeListener(listener),
        rebuildDeciders: [],
      );
    });

    final value = selector(listenable.listenableOrValue());

    _handlers[contextHash]?[listenable]
        ?.rebuildDeciders
        .add(() => _shouldRebuild(listenable, selector, value));

    return value;
  }

  void _listener(Listenable listenable, int contextHash) {
    final context = _wrContexts[contextHash]?.target;
    if (context case Element(dirty: false) && final element) {
      final rebuildDeciders =
          _handlers[contextHash]?[listenable]?.rebuildDeciders ?? [];

      for (final shouldRebuild in rebuildDeciders) {
        if (shouldRebuild() && element.mounted) {
          element.markNeedsBuild();
          break;
        }
      }
    }
  }

  bool _shouldRebuild<R, S>(
    Listenable listenable,
    GrabSelector<R, S> selector,
    // The value as of the last rebuild.
    S? oldValue,
  ) {
    final newValue = selector(listenable.listenableOrValue());

    // If the selected value is the Listenable itself, it means
    // the user has chosen to make the widget get rebuilt whenever
    // the listenable notifies, so true is returned in that case.
    return newValue == listenable || newValue != oldValue;
  }
}
