import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' show internal;

import 'private/manager.dart';
import 'typedefs.dart';

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
///
/// Using more than one of this widget does no harm. However, it is
/// meaningless since only the furthest one found at the start of your
/// app is used.
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

  @internal
  // ignore: library_private_types_in_public_api, public_member_api_docs
  static _GrabState? stateOf(BuildContext context) {
    return _state ??= context.findRootAncestorStateOfType<_GrabState>();
  }
}

class _GrabState extends State<Grab> {
  late final GrabManager _manager;
  bool _isDisposed = false;

  @visibleForTesting
  // ignore: diagnostic_describe_all_properties
  GrabManager get manager => _manager;

  @override
  void initState() {
    super.initState();

    _manager = GrabManager();

    final owner = (context as Element?)?.owner;
    final originalOnBuildScheduled = owner?.onBuildScheduled;

    // A hack to hook events of any widget becoming dirty, including
    // the widgets irrelevant to grab, in order to insert custom processing
    // before a new build.
    owner?.onBuildScheduled = () {
      originalOnBuildScheduled?.call();
      if (!_isDisposed) {
        _manager.onBeforeBuild();
      }
    };
  }

  @override
  void dispose() {
    _isDisposed = true;
    Grab._state = null;
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  S listen<R, S>({
    required BuildContext context,
    required Listenable listenable,
    required GrabSelector<R, S> selector,
  }) {
    return _manager.listen(
      context: context,
      listenable: listenable,
      selector: selector,
    );
  }
}
