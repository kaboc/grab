// ignore_for_file: public_member_api_docs

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

extension on Expando<Map<Listenable, RebuildHandler>> {
  void reset(_WrBuildContext wrContext) {
    final context = wrContext.target;
    if (context != null) {
      this[context]
        ?..forEach((_, v) => v.dispose())
        ..clear();
    }
  }
}

extension on Expando<bool> {
  void reset(_WrBuildContext wrContext) {
    final context = wrContext.target;
    if (context != null) {
      this[context] = null;
    }
  }
}

class GrabController {
  final Map<int, _WrBuildContext> _wrContexts = {};
  final Expando<Map<Listenable, RebuildHandler>> _handlers = Expando();

  /// Grab method call flag per BuildContext.
  ///
  /// This is used to decide whether it is the first call to a grab method in
  /// the current build of the widget associated with a certain BuildContext.
  /// The decision is necessary so that the previous handlers are reset at
  /// the beginning of the build.
  final Expando<bool> _grabCalls = Expando();

  /// Finalizer that removes a [BuildContext] from [_wrContexts] when
  /// it is no longer referenced and GCed.
  ///
  /// The callback may be called much later than the BuildContext loses all
  /// references, or even not be called, but it is not so big an issue.
  /// The callback is just for removing a `BuildContext` that have already
  /// become unnecessary and thus reducing the number of times [_wrContexts]
  /// is iterated to reset all the flags held in it.
  ///
  /// [_handlers] and [_grabCalls] do not have to be manually finalized
  /// because they are [Expando]s that use `BuildContext`s as their keys,
  /// meaning entries with old `BuildContext`s are removed automatically,
  /// and also because the listeners stored in the `_handlers` do not
  /// cause rebuilds after relevant `BuildContext`s are unmounted.`
  late final Finalizer<int> _finalizer = Finalizer(_wrContexts.remove);

  bool _isGrabCallsUpdated = false;

  void dispose() {
    final wrContexts = _wrContexts.values.toList().reversed;
    for (final wrContext in wrContexts) {
      _handlers.reset(wrContext);
      _grabCalls.reset(wrContext);

      final context = wrContext.target;
      if (context != null) {
        _finalizer.detach(context);
      }
    }
    _isGrabCallsUpdated = false;
  }

  void resetGrabCallsIfNecessary() {
    if (_isGrabCallsUpdated) {
      _isGrabCallsUpdated = false;
      _wrContexts.values.forEach(_grabCalls.reset);
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

  void _listener(Listenable listenable, _WrBuildContext wrContext) {
    final element = wrContext.target as Element?;
    if (element == null || element.dirty) {
      return;
    }

    final rebuildDeciders =
        _handlers[element]?[listenable]?.rebuildDeciders ?? [];

    for (final shouldRebuild in rebuildDeciders) {
      if (shouldRebuild() && element.mounted) {
        element.markNeedsBuild();
        break;
      }
    }
  }

  S listen<R, S>({
    required BuildContext context,
    required Listenable listenable,
    required GrabSelector<R, S> selector,
  }) {
    final contextHash = context.hashCode;
    _finalizer.attach(context, contextHash, detach: context);

    final wrContext = _wrContexts[contextHash] ??
        (_wrContexts[contextHash] = WeakReference(context));

    // Clears the previous handlers for the provided BuildContext
    // only when this is the first call in the current build of
    // the widget associated with the BuildContext.
    if (_grabCalls[context] == null) {
      _grabCalls[context] = true;
      _isGrabCallsUpdated = true;

      _handlers.reset(wrContext);
      _handlers[context] ??= {};
    }

    _handlers[context]?.putIfAbsent(listenable, () {
      void listener() => _listener(listenable, wrContext);
      listenable.addListener(listener);
      return RebuildHandler(
        listenerRemover: () => listenable.removeListener(listener),
        rebuildDeciders: [],
      );
    });

    final value = selector(listenable.listenableOrValue());

    _handlers[context]?[listenable]
        ?.rebuildDeciders
        .add(() => _shouldRebuild(listenable, selector, value));

    return value;
  }
}
