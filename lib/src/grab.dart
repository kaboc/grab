import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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

extension on Expando<Map<Listenable, _Handler>> {
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

class _Handler {
  const _Handler({
    required this.listenerRemover,
    required this.rebuildDeciders,
  });

  final VoidCallback listenerRemover;
  final List<ValueGetter<bool>> rebuildDeciders;

  void dispose() {
    listenerRemover();
    rebuildDeciders.clear();
  }
}

/// A widget that enables the grab extension methods to work.
///
/// {@template grab.widget}
/// This widget must be accessible by keeping visiting ancestors in the
/// same widget tree from all widgets where the grab methods are used.
/// It is recommended that the root widget is wrapped as follows:
///
/// ```dart
/// void main() {
///   runApp(
///     const Grab(child: MyApp()),
///   );
/// }
/// ```
/// {@endtemplate}
final class Grab extends StatefulWidget {
  /// Creates a Grab that enables the grab extension methods to work.
  ///
  /// {@macro grab.widget}
  const Grab({super.key, required this.child});

  /// The widget below this widget in the tree.
  final Widget child;

  static _GrabState? _state;

  @override
  State<Grab> createState() => _GrabState();

  // ignore: library_private_types_in_public_api, public_member_api_docs
  static _GrabState? stateOf(BuildContext context) {
    return _state ??
        (_state = context.findRootAncestorStateOfType<_GrabState>());
  }
}

class _GrabState extends State<Grab> {
  final Map<int, _WrBuildContext> _wrContexts = {};
  final Expando<Map<Listenable, _Handler>> _handlers = Expando();

  /// Grab method call flag per BuildContext.
  ///
  /// This is used to decide whether it is the first call to the grab method
  /// in a build of the widget associated with a certain BuildContext.
  /// The decision is necessary so that the previous handlers are reset at
  /// the beginning of the build.
  final Expando<bool> _grabCalls = Expando();

  /// Finalizer that removes all entries from [_wrContexts] related to
  /// a [BuildContext] when the BuildContext is no longer referenced.
  ///
  /// The callback may be called much later than the BuildContext loses all
  /// references, or even not be called, but it is not so big an issue.
  /// The callback is just for removing the entries that have already become
  /// unnecessary and thus reducing the number of times [_wrContexts] is
  /// iterated to reset all the flags held in it.
  ///
  /// [_handlers] and [_grabCalls] do not have to be manually finalized
  /// because they are [Expando]s that use `BuildContext`s as their keys,
  /// meaning entries with old `BuildContext`s are removed automatically,
  /// and also because the listeners stored in the `_handlers` do not
  /// cause rebuilds after relevant `BuildContext`s are unmounted.`
  late final Finalizer<int> _finalizer = Finalizer(_wrContexts.remove);

  bool _isGrabCallsUpdated = false;

  @override
  void initState() {
    super.initState();

    final owner = (context as Element?)?.owner;
    final originalOnBuildScheduled = owner?.onBuildScheduled;

    // A hack to hook events of any widget becoming dirty, including
    // the widgets unrelated to grab.
    owner?.onBuildScheduled = () {
      originalOnBuildScheduled?.call();

      // `_isGrabCallsUpdated` is checked to avoid unnecessary iterations of
      // `_wrContexts` that would occur to reset the flags in `_grabCalls`.
      // When it is false, all flags are null and so resetting is unnecessary.
      if (_isGrabCallsUpdated) {
        _isGrabCallsUpdated = false;
        _wrContexts.values.forEach(_grabCalls.reset);
      }
    };
  }

  @override
  void dispose() {
    Grab._state = null;

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

    super.dispose();
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
    // only when this is the first grab method call in a build of
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
      return _Handler(
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

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
