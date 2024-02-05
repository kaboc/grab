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
  /// Key-value pairs of the hash code of a BuildContext and a weak reference
  /// to the BuildContext.
  final Map<int, _WrBuildContext> _wrContexts = {};

  /// Handlers per BuildContext.
  final Map<int, Map<Listenable, RebuildHandler>> _handlers = {};

  /// Flag per BuildContext.
  ///
  /// The flag indicates whether there has been at least one call to
  /// a grab method in the current build of the widget associated with
  /// the BuildContext.
  /// If the flag is off, it means it is the first call, and thus the
  /// previous handlers need to be reset.
  final Expando<bool> _grabCallFlags = Expando();

  /// Whether a hook is necessary to reset all the flags in `_grabCallFlags`
  /// before the next build.
  bool _needsHookBeforeBuild = false;

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

  @visibleForTesting
  static void Function(({int contextHash, bool firstCall}))? onGrabCallEnd;

  @visibleForTesting
  Iterable<int> get contextHashes => _wrContexts.keys;

  @visibleForTesting
  Map<int, int?> get handlerCounts => Map.fromEntries(
        _handlers.entries.map((v) => MapEntry(v.key, v.value.length)),
      );

  void dispose() {
    for (final MapEntry(key: hash, value: wrContext) in _wrContexts.entries) {
      _handlers.reset(hash);
      _grabCallFlags.reset(wrContext);

      if (wrContext.target case final context?) {
        _finalizer.detach(context);
      }
    }
    _wrContexts.clear();
    _needsHookBeforeBuild = false;
  }

  /// Resets flags in `_grabCallFlags` before starting to build widgets.
  ///
  /// Skipped when unnecessary. If not skipped, all BuildContexts
  /// held in the GrabManager are iterated although no flags are set,
  /// which is meaningless and should be avoided.
  void onBeforeBuild() {
    if (_needsHookBeforeBuild) {
      _needsHookBeforeBuild = false;
      _wrContexts.values.forEach(_grabCallFlags.reset);
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
    final isFirstCallInCurrentBuild = _grabCallFlags[context] == null;

    if (isFirstCallInCurrentBuild) {
      _grabCallFlags[context] = true;
      _needsHookBeforeBuild = true;

      _handlers.reset(contextHash);
      _handlers[contextHash] ??= {};
    }

    _handlers[contextHash]?.putIfAbsent(listenable, () {
      void listener() => _listener(listenable, contextHash);
      listenable.addListener(listener);
      return RebuildHandler(
        listenerRemover: () => listenable.removeListener(listener),
        rebuildDeciders: [],
      );
    });

    final selectedValue = selector(listenable.listenableOrValue());

    _handlers[contextHash]?[listenable]
        ?.rebuildDeciders
        .add(() => _shouldRebuild(listenable, selector, selectedValue));

    onGrabCallEnd?.call(
      (contextHash: contextHash, firstCall: isFirstCallInCurrentBuild),
    );

    return selectedValue;
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
    S? oldSelectedValue,
  ) {
    final newSelectedValue = selector(listenable.listenableOrValue());

    // If the selected value is the Listenable itself, it means
    // the user has chosen to make the widget get rebuilt whenever
    // the Listenable notifies, so true is returned in that case.
    return newSelectedValue == listenable ||
        newSelectedValue != oldSelectedValue;
  }
}
