[![Pub Version](https://img.shields.io/pub/v/grab)](https://pub.dev/packages/grab)
[![Flutter CI](https://github.com/kaboc/grab/workflows/Flutter%20CI/badge.svg)](https://github.com/kaboc/grab/actions)
[![codecov](https://codecov.io/gh/kaboc/grab/branch/main/graph/badge.svg?token=TW32ANXCA7)](https://codecov.io/gh/kaboc/grab)

A flutter package providing mixins and extension methods to trigger a rebuild on change
in a [Listenable] (`ChangeNotifier`, `ValueNotifier`, etc).

## What is Grab?

Grab is like a method version of `ValueListenablebuiler`, `AnimatedBuilder` or
`ListenableBuilder`.

If [grab()][grab] or [grabAt()][grabAt] is called on a `Listenable` in the build method
of a widget that has the Grab mixin, the widget is rebuilt whenever the Listenable is
updated, and the extension method grabs and returns the updated value.

```dart
class SignInButton extends StatelessWidget with Grab {
  const SignInButton();

  @override
  Widget build(BuildContext context) {
    final isValid = notifier.grabAt(context, (state) => state.isInputValid);
  
    return ElevatedButton(
      onPressed: isValid ? notifier.signIn : null,
      child: const Text('Sign in'),
    );
  }
}
```

### Good for state management

What this package does is only rebuild a widget according to changes in a Listenable
as stated above. Despite such simplicity, however, it becomes a powerful state management
tool if combined with some DI package such as [get_it] and [pot].

The Listenable does not have to be passed down the widget tree. Because Grab works as
long as a Listenable is available in any way when [grab()][grab] or [grabAt()][grabAt] is
used, you can use your favourite DI solution to pass around the Listenable.

### Motivation

The blog post below shows a picture of how simple state management could be.
It gave the inspiration for this package.

- [Flutter state management for minimalists](https://suragch.medium.com/flutter-state-management-for-minimalists-4c71a2f2f0c1)

With Grab, instead of `ValueListenableBuilder` used in the article, combined with some
sort of DI, you can focus on creating a good app with no difficulty understanding how
to use it. The simplicity is an advantage over other packages with a larger API surface
and too much functionality.

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
- [Todo app](https://github.com/kaboc/todo-with-grab) - basic
- [pub.dev explorer](https://github.com/kaboc/pubdev-explorer) - advanced

## Companion package (optional)

- [grab_lints](https://github.com/kaboc/grab-lints)
    - A Dart analyzer plugin to add lint rules for Grab.
    - Warns you about misuses of Grab and helps you fix them quickly.

## Usage

### Mixins

Add [StatelessGrabMixin] or [StatefulGrabMixin] to a widget in which you want to
use extensions.

```dart
class MyWidget extends StatelessWidget with StatelessGrabMixin
```

```dart
class MyWidget extends StatefulWidget with StatefulGrabMixin
```

#### Aliases

Each mixin has an alias.

Use [Grab][Grab-mixin] for `StatelessGrabMixin` or [Grabful][Grabful-mixin] for
`StatefulGrabMixin` if you prefer a shorter name.

```dart
class MyWidget extends StatelessWidget with Grab
```

```dart
class MyWidget extends StatefulWidget with Grabful
```

### Extension methods

[grab()][grab] and [grabAt()][grabAt] are available as extension methods of `Listenable`
and `ValueListenable`. They are similar to `watch()` and `select()` of package:provider.

Make sure to add a mixin to the StatelessWidget / StatefulWidget where these methods are used.
An [GrabMixinError] is thrown otherwise.

#### grab()

[grab()][grab] listens for changes in the Listenable that the method is called on.
Every time there is a change, it rebuilds the widget whose BuildContext is passed in
as an argument.

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

- ValueListenable (like ValueNotifier and TextEditingController)
    - The value of the ValueListenable is returned.
- Listenable other than ValueListenable (like ChangeNotifier and ScrollController)
    - The Listenable itself is returned.

In the above example, the Listenable is a `ValueNotifier`, which is a subtype of
`ValueListenable`, so the `count` returned by [grab()][grab] is the value of ValueNotifier.

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
  final name = notifier.grabAt(context, (item) => item.name);
  return Text(name);
}
```

If the Listenable is `ValueListenable` or its subtype, the selector receives its value.
Otherwise, it receives the Listenable itself.

In the above example, the Listenable is a `ValueNotifier`, which is a subtype of
`ValueListenable`, so its value (an `Item` having `name` and `quantity`) is passed to
the selector. The widget is rebuilt when `name` is updated but not when only `quantity`
is updated, and the selected value (the value of `name`) is returned.

## Type safety

The extension methods of Grab is more type-safe when used with a subtype of
[ValueListenable] (e.g. ValueNotifier).

Compare:

```dart
final valueNotifier = ValueNotifier(MyState);

// `state` is inferred as MyState.
final state = valueNotifier.grab(context);
final prop = valueNotifier.grabAt(context, (state) => s.prop);
```

with:

```dart
final changeNotifier = MyChangeNotifier();

// `n` is not automatically inferred as MyChangeNotifier.
final n = changeNotifier.grab<MyChangeNotifier>(context);
final value = changeNotifier.grabAt(context, (MyChangeNotifier n) => n.prop);

// Specifying a wrong type causes an error only at runtime.
changeNotifier.grab<AnotherChangeNotifier>(context);
```

## Tips

### Value returned by selector

The value is not limited to a property value itself of the Listenable. It can be anything
as long as it is possible to evaluate the equality with its previous value using the `==`
operator.

```dart
final hasEnough = notifier.grabAt(context, (item) => item.quantity > 5);
```

Supposing that the quantity was 3 in the previous build and has changed to 2 now, the
widget is not rebuilt because the value returned by the selector has remained false.

### Getting a property value without rebuilds

Grab is a package for rebuilding a widget, so it does not provide an equivalent of `read()`
of the provider package. If you need a property value of a Listenable, you can just take it
out of the Listenable without Grab.

This is one of the good things about this package. Because Grab does not care about how
a Listenable is passed around, you can use your favourite DI solution to inject ones and get
them anywhere in any layer. Grab does not involve other layers than the presentation layer.

[StatelessGrabMixin]: https://pub.dev/documentation/grab/latest/grab/StatelessGrabMixin-mixin.html
[StatefulGrabMixin]: https://pub.dev/documentation/grab/latest/grab/StatefulGrabMixin-mixin.html
[Grab-mixin]: https://pub.dev/documentation/grab/latest/grab/Grab.html
[Grabful-mixin]: https://pub.dev/documentation/grab/latest/grab/Grabful.html
[GrabMixinError]: https://pub.dev/documentation/grab/latest/grab/GrabMixinError-class.html
[grab]: https://pub.dev/documentation/grab/latest/grab/GrabValueListenableExtension/grab.html
[grabAt]: https://pub.dev/documentation/grab/latest/grab/GrabValueListenableExtension/grabAt.html
[Listenable]: https://api.flutter.dev/flutter/foundation/Listenable-class.html
[ValueListenable]: https://api.flutter.dev/flutter/foundation/ValueListenable-class.html
[get_it]: https://pub.dev/packages/get_it
[pot]: https://pub.dev/packages/pot
