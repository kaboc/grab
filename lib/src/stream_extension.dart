import 'package:flutter/foundation.dart' show Listenable, ValueListenable;
import 'package:flutter/widgets.dart' show BuildContext, StreamBuilder;

import 'errors.dart';
import 'grab.dart';
import 'private/stream_value_notifier.dart';

/// ```dart
/// _notifiers[contextHash][streamHash] = StreamValueNotifier(...);
/// ```
final Map<int, Map<int, StreamValueNotifier<Object?>>> _notifiers = {};

final Finalizer<int> _finalizer = Finalizer((contextHash) {
  final notifiers = _notifiers[contextHash];
  if (notifiers != null) {
    notifiers
      ..forEach((_, v) => v.dispose())
      ..clear();
    _notifiers.remove(contextHash);
  }
});

/// Extension on [Stream] to provide methods for Grab.
extension GrabStreamExtension<R> on Stream<R> {
  /// Adds a subscription to the [Stream] this method is called on, and
  /// returns `null` initially. After the first call, every time data
  /// comes through the `Stream`, the widget associated with the provided
  /// [BuildContext] is rebuilt, causing another call to this method to
  /// make it return the received data.
  ///
  /// A [Grab] is necessary as an ancestor of the widget this method
  /// is used for. [GrabMissingError] is thrown otherwise.
  ///
  /// This method may be used as an alternative to [StreamBuilder],
  /// but limited to very simple use cases (e.g. just showing the data
  /// and refreshing with new one as it comes) because it only handles
  /// data while `StreamBuilder` can handle different states such as
  /// `error` and `done`.
  ///
  /// ```dart
  /// void main() {
  ///   runApp(
  ///     const Grab(child: ...),
  ///   );
  /// }
  /// ```
  ///
  /// ```dart
  /// final chatStream = chatStreamController.stream;
  /// ```
  ///
  /// ```dart
  /// class Counter extends StatelessWidget {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     // null is returned on the first call in each widget.
  ///     final chat = chatStream.grab(context);
  ///     return Text(chat.message ?? 'Initial value');
  ///   }
  /// }
  /// ```
  ///
  /// {@template grab.grabStreamExtension.notes}
  /// **Notes:**
  ///
  /// - This method does not hold the data emitted before a subscription.
  ///   Calls prior to the first event after a new subscription always
  ///   return `null` even if the `Stream` data itself is non-nullable.
  /// - The received data is kept only while the provided `BuildContext`
  ///   is reachable. A call with a new `BuildContext` on the same `Stream`
  ///   starts a new subscription, and thus returns `null`.
  /// - The `Stream` should be a broadcast stream due to the above specs.
  /// - A subscription is not cancelled on error. The previous data is
  ///   available until the next data.
  /// - Subscriptions are not cancelled when the relevant `BuildContext`s
  ///   are unreferenced but when they are GCed. It shouldn't usually be
  ///   problematic. Those subscriptions are already not associated with
  ///   `BuildContext`s, so unnecessary rebuilds are not caused.
  ///
  /// For different use cases where error handling is necessary, or if
  /// you prefer to control the timing of cancelling the subscriptions
  /// on your own, create a [Listenable] or [ValueListenable] that wraps
  /// a `Stream`, and then use Grab extension methods on it.
  /// {@endtemplate}
  R? grab(BuildContext context) {
    return grabAt<R?>(context, (value) => value);
  }

  /// Adds a subscription to the [Stream] this method is called on, and
  /// returns `null` initially. After the first call, every time the
  /// object chosen with the [selector] changes, the widget associated
  /// with the provided [BuildContext] is rebuilt, causing another call
  /// to this method to make it return the selected object.
  ///
  /// The callback of the `selector` receives the data received from
  /// the `Stream`.
  ///
  /// A [Grab] is necessary as an ancestor of the widget this method
  /// is used for. [GrabMissingError] is thrown otherwise.
  ///
  /// This method may be used as an alternative to [StreamBuilder] in
  /// very simple use cases (e.g. just showing the data and refreshing
  /// it as new one comes).
  ///
  /// ```dart
  /// void main() {
  ///   runApp(
  ///     const Grab(child: ...),
  ///   );
  /// }
  /// ```
  ///
  /// ```dart
  /// final chatStream = chatStreamController.stream;
  /// ```
  ///
  /// ```dart
  /// class Counter extends StatelessWidget {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     // null is returned on the first call in each widget.
  ///     final message = chatStream.grabAt(context, (chat) => chat.message);
  ///     return Text(message ?? 'Initial value');
  ///   }
  /// }
  /// ```
  ///
  /// The object to select can be anything as long as it is possible to
  /// evaluate its equality with the previous object using the `==` operator.
  ///
  /// {@macro grab.grabStreamExtension.notes}
  S grabAt<S>(BuildContext context, GrabSelector<R?, S> selector) {
    final grabState = Grab.stateOf(context);
    if (grabState == null) {
      throw GrabMissingError();
    }

    final contextHash = context.hashCode;
    _finalizer.attach(context, contextHash, detach: context);

    final streamHash = hashCode;
    _notifiers[contextHash] ??= {};
    _notifiers[contextHash]![streamHash] ??= StreamValueNotifier(this);

    return grabState.listen<R?, S>(
      context: context,
      listenable: _notifiers[contextHash]![streamHash]!,
      selector: selector,
    );
  }
}
