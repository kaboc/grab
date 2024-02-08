import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'weak_key_map.dart';

typedef _WrBuildContext = WeakReference<BuildContext>;
typedef _WrListenable = WeakReference<Listenable>;
typedef _Handler = ({
  List<bool Function()> rebuildDeciders,
  void Function() canceller,
});

/// The signature for the `selector` callback of `grabAt()` that receives
/// an object of type [R] and returns an object of type [S].
typedef GrabSelector<R, S> = S Function(R);

/// Whether there has been at least one call to a grab method in
/// the current build of the widget associated with a BuildContext.
final Map<int, bool> _grabCallFlags = {};

@visibleForTesting
Map<int, bool> get grabCallFlags => Map.of(_grabCallFlags);

extension on Listenable {
  R listenableOrValue<R>() {
    final listenable = this;
    return (listenable is ValueListenable ? listenable.value : listenable) as R;
  }
}

class GrabManager {
  final WeakKeyMap<BuildContext, WeakKeyMap<Listenable, _Handler>> _handlers =
      WeakKeyMap();

  /// Whether a hook is necessary to reset all the flags in `_grabCallFlags`
  /// at the beginning of the next build.
  bool _needsResetFlagsBeforeBuild = false;

  @visibleForTesting
  static void Function(({int contextHash, bool firstCall}))? onGrabCallEnd;

  @visibleForTesting
  Map<int, int> get handlerCounts {
    return {
      for (final hash in _handlers.keyHashes)
        hash: _handlers[hash]!.values.length,
    };
  }

  void dispose() {
    _needsResetFlagsBeforeBuild = false;
    _handlers.reset();
    _grabCallFlags.clear();
  }

  void onBeforeBuild() {
    if (_needsResetFlagsBeforeBuild) {
      _needsResetFlagsBeforeBuild = false;
      _grabCallFlags.clear();
    }
  }

  S listen<R, S>({
    required BuildContext context,
    required Listenable listenable,
    required GrabSelector<R, S> selector,
  }) {
    final contextHash = context.hashCode;
    final listenableHash = listenable.hashCode;

    final isFirstCallInCurrentBuild = _grabCallFlags[contextHash] == null;
    final handler = _handlers[contextHash]?[listenableHash];

    if (isFirstCallInCurrentBuild) {
      _needsResetFlagsBeforeBuild = true;
      _grabCallFlags[contextHash] = true;
      handler?.rebuildDeciders.clear();
    }

    final wrContext = WeakReference(context);
    final wrListenable = WeakReference(listenable);

    if (handler == null) {
      void listener() => _listener(wrContext, wrListenable);
      listenable.addListener(listener);

      _handlers.putIfAbsent(
        context,
        WeakKeyMap<Listenable, _Handler>.new,
        finalizer: (value) {
          for (final handler in value.values) {
            handler.canceller.call();
          }
        },
      ).addOrUpdate(
        listenable,
        (
          rebuildDeciders: [],
          canceller: () => wrListenable.target?.removeListener(listener),
        ),
        finalizer: (value) => value.canceller(),
      );
    }

    final selectedValue = selector(listenable.listenableOrValue());

    _handlers[contextHash]![listenableHash]!
        .rebuildDeciders
        .add(() => _shouldRebuild(wrListenable, selector, selectedValue));

    onGrabCallEnd?.call(
      (contextHash: contextHash, firstCall: isFirstCallInCurrentBuild),
    );

    return selectedValue;
  }

  void _listener(_WrBuildContext wrContext, _WrListenable wrListenable) {
    final listenable = wrListenable.target;
    if (listenable == null) {
      return;
    }

    final element = wrContext.target as Element?;
    if (element == null || element.dirty || !element.mounted) {
      return;
    }

    final handler = _handlers[element.hashCode]?[listenable.hashCode];
    if (handler?.rebuildDeciders case final rebuildDeciders?) {
      for (final shouldRebuild in rebuildDeciders) {
        if (shouldRebuild()) {
          element.markNeedsBuild();
          break;
        }
      }
    }
  }

  bool _shouldRebuild<R, S>(
    _WrListenable wrListenable,
    GrabSelector<R, S> selector,
    S? oldSelectedValue,
  ) {
    final listenable = wrListenable.target;
    if (listenable == null) {
      return false;
    }

    final newSelectedValue = selector(listenable.listenableOrValue());

    // If the selected value is the Listenable itself, it means
    // the user has chosen to make the widget get rebuilt whenever
    // the Listenable notifies, so true is returned in that case.
    return newSelectedValue == listenable ||
        newSelectedValue != oldSelectedValue;
  }
}
