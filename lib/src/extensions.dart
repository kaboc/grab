import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'errors.dart';
import 'grab.dart';

// Note:
//
// Changing `GrabListenableExtension on Listenable` to
// `GrabListenableExtension<R extends Listenable> on R` will cause
// calls on ValueListenable to invoke the GrabListenableExtension
// extension instead of GrabValueListenableExtension.

/// Extension on [Listenable] to provide methods for Grab.
extension GrabListenableExtension on Listenable {
  /// Returns the [Listenable] itself that this method was called on,
  /// and starts listening for changes in the `Listenable` to rebuild
  /// the widget associated with the provided [BuildContext] when
  /// there is a change.
  ///
  /// A [Grab] is necessary as an ancestor of the widget this method
  /// is used for. [GrabMissingError] is thrown otherwise.
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
  /// class ItemNotifier extends ChangeNotifier {
  ///   ItemNotifier({required this.name, required this.quantity});
  ///
  ///   final String name;
  ///   final int quantity;
  /// }
  /// ```
  ///
  /// ```dart
  /// final notifier = ItemNotifier(name: 'Milk', quantity: 3);
  ///
  /// ...
  ///
  /// class InventoryItem extends StatelessWidget {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final n = notifier.grab<ItemNotifier>(context);
  ///     return Text(n.name);
  ///   }
  /// }
  /// ```
  ///
  /// In the above example, `grab()` returns the ItemNotifier itself.
  /// Therefore it is not much different from the code below:
  ///
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   notifier.grab<ItemNotifier>(context);
  ///   return Text(notifier.name);
  /// }
  /// ```
  ///
  /// Note that specifying a wrong Listenable type causes an error
  /// only at runtime.
  R grab<R extends Listenable>(BuildContext context) {
    return grabAt<R, R>(context, (listenable) => listenable);
  }

  /// Returns an object chosen with the [selector], and starts listening
  /// for changes in the [Listenable] to rebuild the widget associated
  /// with the provided [BuildContext] when there is a change in the
  /// selected object.
  ///
  /// The callback of the `selector` receives the `Listenable` itself
  /// that this method was called on.
  ///
  /// A [Grab] is necessary as an ancestor of the widget this method
  /// is used for. [GrabMissingError] is thrown otherwise.
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
  /// class ItemNotifier extends ChangeNotifier {
  ///   ItemNotifier({required this.name, required this.quantity});
  ///
  ///   final String name;
  ///   final int quantity;
  /// }
  /// ```
  ///
  /// ```dart
  /// final notifier = ItemNotifier(name: 'Milk', quantity: 3);
  ///
  /// ...
  ///
  /// class InventoryItem extends StatelessWidget {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final name = notifier.grabAt(context, (ItemNotifier n) => n.name);
  ///     return Text(name);
  ///   }
  /// }
  /// ```
  ///
  /// Instead of annotating the parameter of the selector with the
  /// concrete type, it is also possible to specify the types of the
  /// Listenable and the object returned by the selector as below,
  /// although it is a little more verbose.
  ///
  /// ```dart
  /// notifier.grabAt<ItemNotifier, String>(context, (n) => n.name);
  /// ```
  ///
  /// Note that the object to select can be anything as long as it is
  /// possible to evaluate its equality with the previous object using
  /// the `==` operator.
  ///
  /// ```dart
  /// final hasEnough = notifier.grabAt(
  ///   context,
  ///   (ItemNotifier n) => item.quantity > 5,
  /// );
  /// ```
  ///
  /// Supposing that the quantity was 3 in the previous build and has
  /// changed to 2 now, the widget is not rebuilt because the value
  /// returned by the selector has remained false.
  S grabAt<R extends Listenable, S>(
    BuildContext context,
    GrabSelector<R, S> selector,
  ) {
    final scopeState = Grab.stateOf(context);
    if (scopeState != null) {
      return scopeState.listen(
        context: context,
        listenable: this,
        selector: selector,
      );
    }
    throw GrabMissingError();
  }
}

/// Extension on [ValueListenable] to provide methods for Grab.
extension GrabValueListenableExtension<R> on ValueListenable<R> {
  /// Returns the `value` of the [ValueListenable] that this method was
  /// called on, and starts listening for changes in the `ValueListenable`
  /// to rebuild the widget associated with the provided [BuildContext]
  /// when there is a change in the `value` of the `ValueListenable`.
  ///
  /// A [Grab] is necessary as an ancestor of the widget this method
  /// is used for. [GrabMissingError] is thrown otherwise.
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
  /// class Item {
  ///   Item({required this.name, required this.quantity});
  ///
  ///   final String name;
  ///   final int quantity;
  /// }
  /// ```
  ///
  /// ```dart
  /// final notifier = ValueNotifier(
  ///   Item(name: 'Milk', quantity: 3),
  /// );
  ///
  /// ...
  ///
  /// class InventoryItem extends StatelessWidget {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final item = notifier.grab(context);
  ///     return Text(item.name);
  ///   }
  /// }
  /// ```
  R grab(BuildContext context) {
    return grabAt(context, (value) => value);
  }

  /// Returns an object chosen with the [selector], and starts listening
  /// for changes in the [ValueListenable] to rebuild the widget associated
  /// with the provided [BuildContext] when there is a change in the
  /// selected object.
  ///
  /// The callback of the `selector` receives the `value` of the
  /// `ValueListenable` that this method was called on.
  ///
  /// A [Grab] is necessary as an ancestor of the widget this method
  /// is used for. [GrabMissingError] is thrown otherwise.
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
  /// class Item extends ChangeNotifier {
  ///   Item({required this.name, required this.quantity});
  ///
  ///   final String name;
  ///   final int quantity;
  /// }
  /// ```
  ///
  /// ```dart
  /// final notifier = ValueNotifier(
  ///   Item(name: 'Milk', quantity: 3),
  /// };
  ///
  /// ...
  ///
  /// class InventoryItem extends StatelessWidget {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final name = notifier.grabAt(context, (item) => item.name);
  ///     return Text(name);
  ///   }
  /// }
  /// ```
  ///
  /// Note that the object to select can be anything as long as it is
  /// possible to evaluate its equality with the previous object using
  /// the `==` operator.
  ///
  /// ```dart
  /// final hasEnough = notifier.grabAt(context, (item) => item.quantity > 5);
  /// ```
  ///
  /// Supposing that the quantity was 3 in the previous build and has
  /// changed to 2 now, the widget is not rebuilt because the value
  /// returned by the selector has remained false.
  S grabAt<S>(BuildContext context, GrabSelector<R, S> selector) {
    final scopeState = Grab.stateOf(context);
    if (scopeState != null) {
      return scopeState.listen(
        context: context,
        listenable: this,
        selector: selector,
      );
    }
    throw GrabMissingError();
  }
}
