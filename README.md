[![Pub Version](https://img.shields.io/pub/v/grab)](https://pub.dev/packages/grab)
[![Flutter CI](https://github.com/kaboc/grab/workflows/Flutter%20CI/badge.svg)](https://github.com/kaboc/grab/actions)
[![codecov](https://codecov.io/gh/kaboc/grab/branch/main/graph/badge.svg?token=TW32ANXCA7)](https://codecov.io/gh/kaboc/grab)

A flutter package providing extension methods to trigger a rebuild on change
in a [Listenable] (`ChangeNotifier`, `ValueNotifier`, etc).

## What is Grab?

Grab is like a method version of `ValueListenablebuiler`, `AnimatedBuilder` or
`ListenableBuilder`.

If [grab()] or [grabAt()] is called on a `Listenable`, the widget associated
with the provided BuildContext is rebuilt whenever the Listenable (or a selected
value) is updated, and the method "grab"s the updated value and returns it.

```dart
class UserProfile extends StatelessWidget {
  const UserProfile();

  @override
  Widget build(BuildContext context) {
    final userName = userNotifier.grabAt(context, (state) => state.name);
    return Text(userName);
  }
}
```

### Good for state management

What this package does is only rebuild a widget according to changes in a
`Listenable` as stated above. Despite such simplicity, however, it becomes
a powerful state management tool if combined with some DI package such as
[get_it] and [pot].

The Listenable does not have to be passed down the widget tree. Because Grab
works as long as a Listenable is available in any way when [grab()] or [grabAt()]
is used, you can use your favourite DI solution to pass around the Listenable.

### Motivation

The blog post below by someone else gave me the inspiration for this package.
It shows a picture of how simple state management could be.

- [Flutter state management for minimalists](https://suragch.medium.com/flutter-state-management-for-minimalists-4c71a2f2f0c1)

With Grab, instead of `ValueListenableBuilder` used in the article, combined
with some sort of DI, you can focus on creating a good app with no difficulty
understanding how to use it. The simplicity is an advantage over other packages
with a larger API surface and too much functionality.

### Supported Listenables

Anything that inherits the [Listenable] class:

- ChangeNotifier
- ValueNotifier
- TextEditingController
- Animation / AnimationController
- ScrollController
- etc.

It is recommended to use Grab with subtypes of `ValueListenable` for type safety.
Please see the related section later in this document.

## Examples

- [Counters](https://github.com/kaboc/grab/tree/main/example) - simple
- [Useless Facts](https://github.com/kaboc/async-phase/tree/main/packages/async_phase_notifier/example) - simple
- [Todo app](https://github.com/kaboc/todo-with-grab) - basic
- [pub.dev explorer](https://github.com/kaboc/pubdev-explorer) - advanced

## Usage

### Getting started

The [Grab] widget is necessary somewhere accessible via the tree from any widget
where grab extension methods are used. It is recommended the root widget is
wrapped as follows.

```dart
import 'package:grab/grab.dart';
...

void main() {
  runApp(
    const Grab(child: MyApp()),
  );
}
```

### Extension methods

[grab()] and [grabAt()] are available as extension methods of `Listenable` and
`ValueListenable`. They are similar to `watch()` and `select()` of package:provider.

Make sure to have the [Grab] widget up in the tree. A [GrabMissingError] is
thrown otherwise.

#### grab()

[grab()] listens for changes in the Listenable that the method is called on.
Every time there is a change, it rebuilds the widget associated with the provided
BuildContext.

```dart
final notifier = ValueNotifier(0);
```

```dart
@override
Widget build(BuildContext context) {
  final count = notifier.grab(context);
  return Text('$count');
}
```

What is returned from the method depends on the type of the Listenable which the
method is called on:

- ValueListenable (e.g. ValueNotifier, TextEditingController)
    - The `value` of the ValueListenable is returned.
- Listenable other than ValueListenable (e.g. ChangeNotifier, ScrollController)
    - The Listenable itself is returned.

In the above example, the Listenable is a `ValueNotifier`, which is a subtype of
`ValueListenable`, so the `count` returned by [grab()] is the `value` of
ValueNotifier.

This is a little tricky, but has been designed that way for convenience.

#### grabAt()

[grabAt()] allows you to choose a value to be returned. The value is also used
to evaluate the necessity of a rebuild.

- The widget is rebuilt only when there is a change in the value returned by
  the selector, which is a callback function passed as the second argument.
- `grabAt()` returns the value selected by the selector. 

```dart
final notifier = ValueNotifier(
  Item(name: 'Milk', quantity: 3),
);
```

```dart
@override
Widget build(BuildContext context) {
  final name = notifier.grabAt(context, (item) => item.name);
  return Text(name);
}
```

If the Listenable is `ValueListenable` or its subtype, the selector receives
its value. Otherwise, it receives the Listenable itself.

In the above example, the Listenable is a `ValueNotifier`, which is a subtype
of `ValueListenable`, so its value (an `Item` having `name` and `quantity`) is
passed to the selector. The widget is rebuilt when `name` is updated but not
when only `quantity` is updated, and the selected value (the value of `name`)
is returned.

## Type safety

The extension methods are more type-safe when used with a subtype of
[ValueListenable] (e.g. `ValueNotifier`).

ValueNotifier:

```dart
final valueNotifier = ValueNotifier(MyState);

// The type is inferred.
final state = valueNotifier.grab(context);
final prop = valueNotifier.grabAt(context, (state) => state.prop);
```

ChangeNotifier (not type-safe):

```dart
final changeNotifier = MyChangeNotifier();

// The type is not inferred, so needs to be annotated.
final notifier = changeNotifier.grab<MyChangeNotifier>(context);
final prop = changeNotifier.grabAt(context, (MyChangeNotifier notifier) => notifier.prop);

// Specifying a wrong type raises an error only at runtime.
changeNotifier.grab<AnotherChangeNotifier>(context);
```

## Tips

### Value returned by selector

The value is not limited to a field value itself of the Listenable. It can be
anything as long as it is possible to evaluate the equality with its previous
value using the `==` operator.

```dart
final hasEnough = notifier.grabAt(context, (item) => item.quantity > 5);
```

Supposing that the quantity was 3 in the previous build and has changed to 2 now,
the widget is not rebuilt because the value returned by the selector has remained
false.

### Getting a value without rebuilds

Grab is a package for rebuilding a widget, so it does not provide an equivalent
of `read()` of the provider package. If you need a field value of a Listenable,
you can just take it out of the Listenable without Grab.

### DI (Dependency Injection)

Grab does not care about how a Listenable is passed around, so you can use your
favourite DI solution to inject ones and get them anywhere in any layer.

[pottery] is a good option for this purpose. It is a package that manages the
lifespan of [pot] (a single-type DI container) according to the lifecycle of
Flutter. Grab used along with it provides an experience similar to package:provider
but with more flexibility.

[Grab]: https://pub.dev/documentation/grab/latest/grab/Grab-class.html
[grab()]: https://pub.dev/documentation/grab/latest/grab/GrabValueListenableExtension/grab.html
[grabAt()]: https://pub.dev/documentation/grab/latest/grab/GrabValueListenableExtension/grabAt.html
[GrabMissingError]: https://pub.dev/documentation/grab/latest/grab/GrabMissingError-class.html
[Listenable]: https://api.flutter.dev/flutter/foundation/Listenable-class.html
[ValueListenable]: https://api.flutter.dev/flutter/foundation/ValueListenable-class.html
[get_it]: https://pub.dev/packages/get_it
[pot]: https://pub.dev/packages/pot
[pottery]: https://pub.dev/packages/pottery
