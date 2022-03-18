[![Pub Version](https://img.shields.io/pub/v/grab)](https://pub.dev/packages/grab)
[![Flutter CI](https://github.com/kaboc/grab/workflows/Flutter%20CI/badge.svg)](https://github.com/kaboc/grab/actions)
[![codecov](https://codecov.io/gh/kaboc/grab/branch/main/graph/badge.svg?token=TW32ANXCA7)](https://codecov.io/gh/kaboc/grab)

A flutter package to control rebuilds of a widget based on updates of a Listenable
such as `ChangeNotifier` and `ValueNotifier`.

## What is Grab?

Grab is similar to `ValueListenablebuiler` or `AnimatedBuilder`, but not a widget like them.
It comes with mixins and extension methods of `BuildContext`.

If a Grab mixin is added to a widget and [grab()][grab] or [grabAt()][grabAt] is used inside
it with some [Listenable][Listenable] passed in, the widget is rebuilt whenever the Listenable
(or only partial value of it, like a particular property) is updated.

### Good for state management

What this package does is only rebuild a widget according to changes in a Listenable.
Despite such simplicity, it becomes a powerful state management tool if combined with
some DI package such as [get_it][get_it] and [pot][pot].

The Listenable does not have to be passed down the widget tree. Because Grab works as
long as a Listenable is available in any way when [grab()][grab] or [grabAt()][grabAt] is
used, so you can use your favourite DI solution to pass Listenables around.

### Motivation

The blog post below shows a picture of how simple state management could be, and
it really inspired the author to create this package.

- [Flutter state management for minimalists](https://suragch.medium.com/flutter-state-management-for-minimalists-4c71a2f2f0c1)

With Grab, instead of `ValueListenableBuilder`, combined with some sort of DI, you can
focus on creating a good app with no trouble understanding how to use it. This is an
advantage over other packages with a larger API surface and too much functionality.

### Supported Listenables

Anything that inherits the [Listenable][Listenable] class:

- ChangeNotifier
- ValueNotifier
- TextEditingController
- Animation / AnimationController
- ScrollController
- etc.

## Samples

- [Todo app](https://github.com/kaboc/todo-with-grab)

## Usage

### Overview

```dart
class LikeButton extends StatelessWidget with Grab {
  const LikeButton(this.index);

  final int index;

  @override
  Widget build(BuildContext context) {
    final liked = context.grabAt(notifier, (Items items) => items[index].liked);
  
    return IconButton(
      icon: Icon(liked ? Icons.thumb_up : Icons.thumb_up_outlined),
      onPressed: userNotifier.toggleLike,
    );
  }
}
```

### Mixins

Add [StatelessGrabMixin][StatelessGrabMixin] or [StatefulGrabMixin][StatefulGrabMixin]
to a widget in which you want to use extensions.

```dart
class MyWidget extends StatelessWidget with StatelessGrabMixin
```

```dart
class MyWidget extends StatefulWidget with StatefulGrabMixin
```

#### Aliases

Each mixin has an alias.

Use [Grab][Grab-mixin] for `StatelessGrabMixin` or [Grabful][Grabful-mixin] for
`StatefulGrabMixin` if you like shorter names.

```dart
class MyWidget extends StatelessWidget with Grab
```

```dart
class MyWidget extends StatefulWidget with Grabful
```

### Extension methods

[grab()][grab] and [grabAt()][grabAt] are available as extension methods of `BuildContext`.
They are almost like `watch()` and `select()` of the [provider][provider] package.

Make sure to add a mixin to the StatelessWidget / StatefulWidget where these methods are used.
An [GrabMixinError][GrabMixinError] is thrown otherwise.

#### grab()

[grab()][grab] listens to the Listenable passed to it, and the widget that the BuildContext
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

The return value is the Listenable itself, or its value if the Listenable is
[ValueListenable][ValueListenable]; that is, if the first parameter is:

- Listenable other than ValueListenable (like ChangeNotifier and ScrollController)
    - The Listenable itself is returned.
- ValueListenable (like ValueNotifier and TextEditingController)
    - The value of the Listenable is returned.

In the above example, the Listenable is a `ValueNotifier` extending `ValueListenable`, so
the `count` returned by [grab()][grab] is not the Listenable itself but the value of ValueNotifier.

This is a little tricky, but has been designed that way for convenience.

#### grabAt()

[grabAt()][grabAt] allows you to choose a value that a rebuild is triggered by and that
is returned.

- The widget is rebuilt only when there is a change in the value returned by the selector,
  which is a callback function passed as the second argument.
- `grabAt()` returns the value of the target selected by the selector. 


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

The selector receives the Listenable itself, or its value if the Listenable is `ValueListenable`;
that is, if the first parameter is:

- Listenable other than ValueListenable (like ChangeNotifier and ScrollController)
    - The Listenable itself is passed to the selector.
- ValueListenable (like ValueNotifier and TextEditingController)
    - The value of the Listenable is passed to the selector.

In the above example, the listenable is a `ValueNotifier` extending `ValueListenable`, so its
value, which is `Item` having `name` and `quantity`, is passed to the selector.
The widget is rebuilt when `name` is updated, and not when only `quantity` is updated.

## Tips

### Value returned by selector

The value is not limited to a property value itself of the Listenable. It can be anything as
long as it is possible to evaluate its equality with  the previous value using the `==` operator.

```dart
final bool isEnough = context.grabAt(
  notifier,
  (Item item) => item.quantity > 5,
);
```

Supposing that the quantity was 3 in the previous build, if it's changed to 2, the widget is
not going to be rebuilt because `isEnough` remains false.

### Getting a property value without rebuilds

Grab is a package for rebuilding a widget, so it does not provide an equivalent of `read()`
of the provider package. If you need a property value of a Listenable, you can just take it
out of the Listenable without Grab.

This is one of the good things about this package. Because Grab does not care about how
a Listenable is passed around, you can use your favourite DI package to inject one and
get it anywhere without the need of using `BuildContext`, and in a widget in the presentation
layer where `BuildContext` is available, you can use its extensions with the Listenable to
control rebuilds of the widget.

[StatelessGrabMixin]: https://pub.dev/documentation/grab/latest/grab/StatelessGrabMixin-mixin.html
[StatefulGrabMixin]: https://pub.dev/documentation/grab/latest/grab/StatefulGrabMixin-mixin.html
[Grab-mixin]: https://pub.dev/documentation/grab/latest/grab/Grab.html
[Grabful-mixin]: https://pub.dev/documentation/grab/latest/grab/Grabful.html
[GrabMixinError]: https://pub.dev/documentation/grab/latest/grab/GrabMixinError-class.html
[grab]: https://pub.dev/documentation/grab/latest/grab/GrabBuildContext/grab.html
[grabAt]: https://pub.dev/documentation/grab/latest/grab/GrabBuildContext/grabAt.html
[Listenable]: https://api.flutter.dev/flutter/foundation/Listenable-class.html
[ValueListenable]: https://api.flutter.dev/flutter/foundation/ValueListenable-class.html
[get_it]: https://pub.dev/packages/get_it
[pot]: https://pub.dev/packages/pot
[provider]: https://pub.dev/packages/provider
