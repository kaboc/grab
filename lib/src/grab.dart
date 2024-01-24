import 'package:flutter/widgets.dart';

import 'private/controller.dart';

export 'private/controller.dart' show GrabSelector;

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
  late final GrabController _controller;

  @override
  void initState() {
    super.initState();

    _controller = GrabController();

    final owner = (context as Element?)?.owner;
    final originalOnBuildScheduled = owner?.onBuildScheduled;

    // A hack to hook events of any widget becoming dirty, including
    // the widgets unrelated to grab.
    owner?.onBuildScheduled = () {
      originalOnBuildScheduled?.call();

      // Avoids resetting flags indicating whether grab methods were called
      // when unnecessary. If it is not skipped, all BuildContexts held in
      // the controller are iterated regardless of the states of those flags.
      _controller.resetGrabCallsIfNecessary();
    };
  }

  @override
  void dispose() {
    Grab._state = null;
    _controller.dispose();
    super.dispose();
  }

  S listen<R, S>({
    required BuildContext context,
    required Listenable listenable,
    required GrabSelector<R, S> selector,
  }) {
    return _controller.listen(
      context: context,
      listenable: listenable,
      selector: selector,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
