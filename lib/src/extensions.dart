import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'element.dart';
import 'errors.dart';
import 'mixins.dart';
import 'types.dart';

// Note:
//
// Changing `GrabListenableExtension on Listenable` to
// `GrabListenableExtension<R extends Listenable> on R` will cause
// calls on ValueListenable to invoke the GrabListenableExtension
// extension instead of GrabValueListenableExtension.

/// Extensions on [Listenable] to provide methods for Grab.
///
/// The widget where the extension methods are used must have an
/// appropriate mixin. See [StatelessGrabMixin] and [StatefulGrabMixin]
/// for details.
extension GrabListenableExtension on Listenable {
  /// Returns an object of type [R], which is the [Listenable] itself
  /// that this method was called on.
  ///
  /// Not only does it return an object, but it also listens for changes
  /// in the Listenable. Every time there is a change, it rebuilds the
  /// widget whose [BuildContext] is passed in as an argument.
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
  /// class InventoryItem extends StatelessWidget with Grab {
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

  /// Returns an object of type [S] chosen with the [selector].
  ///
  /// Not only does it return an object, but it also listens for changes
  /// in the [Listenable] that the method is called on. Every time there
  /// is a change, it rebuilds the widget whose [BuildContext] is passed
  /// in as an argument.
  ///
  /// The callback of the [selector] is given an object of type [R] that
  /// is a subtype of Listenable.
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
  /// class InventoryItem extends StatelessWidget with Grab {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final name = notifier.grabAt(context, (ItemNotifier n) => n.name);
  ///     return Text(name);
  ///   }
  /// }
  /// ```
  ///
  /// Instead of annotating the parameter of the selector with the
  /// concrete type of [R], the types of the Listenable and the value
  /// returned by the selector can be specified as below, although
  /// it is a little more verbose.
  ///
  /// ```dart
  /// notifier.grabAt<ItemNotifier, String>(context, (n) => n.name);
  /// ```
  ///
  /// Note that the value to select can be anything as long as it is
  /// possible to evaluate its equality with the previous value using
  /// the `==` operator.
  ///
  /// ```dart
  /// final hasEnough = notifier.grabAt(
  ///   context,
  ///   (ItemNotifier n) => item.quantity > 5,
  /// );
  /// ```
  ///
  /// Supposing that the quantity was 3 in the previous build and
  /// has changed to 2 now, the widget is not rebuilt because the
  /// value returned by the selector has remained false.
  S grabAt<R extends Listenable, S>(
    BuildContext context,
    GrabSelector<R, S> selector,
  ) {
    if (context is GrabElement) {
      return context.listen(listenable: this, selector: selector);
    }
    throw GrabMixinError();
  }
}

/// Extensions on [ValueListenable] with its value of type [R] to
/// provide methods for Grab.
///
/// The widget where the extension methods are used must have an
/// appropriate mixin. See [StatelessGrabMixin] and [StatefulGrabMixin]
/// for details.
extension GrabValueListenableExtension<R> on ValueListenable<R> {
  /// Returns an object of type [R], which is the value of
  /// [ValueListenable] that this method was called on.
  ///
  /// Not only does it return the value, but it also listens for changes
  /// in the ValueListenable. Every time there is a change, it rebuilds
  /// the widget whose [BuildContext] is passed in as an argument.
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
  /// class InventoryItem extends StatelessWidget with Grab {
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

  /// Returns an object of type [S] chosen with the [selector].
  ///
  /// Not only does it return an object, but it also listens for changes
  /// in the [ValueListenable] that the method is called on. Every time
  /// there is a change, it rebuilds the widget whose [BuildContext] is
  /// passed in as an argument.
  ///
  /// The callback of the [selector] is given an object of type [R] that
  /// is the value of the ValueListenable.
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
  /// class InventoryItem extends StatelessWidget with Grab {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final name = notifier.grabAt(context, (item) => item.name);
  ///     return Text(name);
  ///   }
  /// }
  /// ```
  ///
  /// Note that the value to select can be anything as long as it is
  /// possible to evaluate its equality with the previous value using
  /// the `==` operator.
  ///
  /// ```dart
  /// final hasEnough = notifier.grabAt(context, (item) => item.quantity > 5);
  /// ```
  ///
  /// Supposing that the quantity was 3 in the previous build and
  /// has changed to 2 now, the widget is not rebuilt because the
  /// value returned by the selector has remained false.
  S grabAt<S>(BuildContext context, GrabSelector<R, S> selector) {
    if (context is GrabElement) {
      return context.listen(listenable: this, selector: selector);
    }
    throw GrabMixinError();
  }
}
