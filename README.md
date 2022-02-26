[![Pub Version](https://img.shields.io/pub/v/grab)](https://pub.dev/packages/grab)
[![Flutter CI](https://github.com/kaboc/grab/workflows/Flutter%20CI/badge.svg)](https://github.com/kaboc/grab/actions)

A flutter package to control rebuilds of a widget based on updates of a Listenable.

## What is Grab?

Grab is similar to `ValueListenablebuiler` or `AnimatedBuilder`, but not a widget like them.
It comes with mixins and extensions of `BuildContext`.

If a Grab mixin is added to a widget and an extension method `grab()` or `grabAt()` is
used inside it with some Listenable passed in, the widget is rebuilt whenever the Listenable
(or only specific part of it) is updated.

### Good for state management

What this package does is only rebuild a widget according to changes in a Listenable.
Despite such simplicity, it becomes a powerful state management tool if combined with
some DI package like [get_it](https://pub.dev/packages/get_it).

Grab works as long as a Listenable is available in any way when `grab()` or `grabAt()`
is used, so you can use your favourite DI package to pass a Listenable around.

### Motivation

The blog post below really inspired the author of this package.
It shows a picture of how simple state management could be.

- [Flutter state management for minimalists](https://suragch.medium.com/flutter-state-management-for-minimalists-4c71a2f2f0c1)

Combining this idea, some sort of DI and Grab, you can focus on creating a good app
with no trouble understanding how to use it. This is an advantage over other packages
with a larger API surface.

### Supported Listenables

The Listenable can be anything that inherits a
[Listenable](https://api.flutter.dev/flutter/foundation/Listenable-class.html);
ChangeNotifier, ValueNotifier, TextEditingController, Animation / AnimationController,
ScrollController, etc.

## Usage

### Mixins

Add `StatelessGrabMixin` or `StatefulGrabMixin` to a widget in which you want to use extensions.

```dart
class MyWidget extends StatelessWidget with StatelessGrabMixin
```

```dart
class MyWidget extends StatefulWidget with StatefulGrabMixin
```

Each mixin has an alias.  
Use `Grab` for `StatelessGrabMixin` or `Grabful` for `StatefulGrabMixin` if you
like shorter names.

```dart
class MyWidget extends StatelessWidget with Grab
```

```dart
class MyWidget extends StatefulWidget with Grabful
```

### Extensions

You can use `grab()` and `grabAt()` on a BuildContext.  
They are like `watch()` and `select()` of [provider](https://pub.dev/packages/provider).

Make sure to add a mixin to the StatelessWidget/StatefulWidget where these extensions are used.
An error occurs otherwise. 

#### grab()

`grab()` listens to the Listenable passed to it, and the widget that the BuildContext
belongs to is rebuilt every time the Listenable is updated.

```dart
final notifier = ValueNotifier(0);
```

```dart
@override
Widget build(BuildContext context) {
  final count = context.grab<int>(counterNotifier);
  return Text('$count');
}
```

The return value is the Listenable itself, or its value if the Listenable is `ValueListenable`.

In the above example, the Listenable is a `ValueNotifier` extending `ValueListenable`, so
the `count` returned by `grab()` is not the Listenable itself but the value of ValueNotifier.

#### grabAt()

The widget is rebuilt only when there is a change in the value returned by the selector,
which is a callback function passed as the second argument.


```dart
final notifier = ValueNotifier(
  Item(name: 'Milk', quantity: 3),
);
```

```dart
@override
Widget build(BuildContext context) {
  final name = context.grabAt(notifier, (Item item) => item.name);
  return Text(name);
}
```

The selector receives the Listenable itself, or its value if the Listenable is `ValueListenable`.

In this example, the value of the notifier is `Item` that has `name` and `quantity`.
The widget is not rebuilt if `quantity` has a new value but `name` is not updated.

##### Tip

The value returned by the selector can be anything as long as it is possible to evaluate
its equality with the previous value with the `==` operator.

```dart
final bool isEnough = context.grabAt(
  notifier,
  (Item item) => item.quantity > 5,
);
```

Supposing that the quantity was 3 in the previous build, if it's changed to 2, the widget is
not going to be rebuilt because `isEnough` remains false.
