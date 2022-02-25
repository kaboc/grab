A flutter package to control rebuilds of a widget based on updates of Listenables.

Although this package is extremely simple, it becomes a powerful state management tool
if combined with some DI package like [GetIt](https://pub.dev/packages/get_it).

## Usage

This package contains mixins and extensions of `BuildContext`.

### Mixins

Add `StatelessGrabMixin` or `StatefulGrabMixin` to a widget in which you want to use extensions.

```dart
class MyWidget extends StatelessWidget with StatelessGrabMixin
```

```dart
class MyWidget extends StatefulWidget with StatefulGrabMixin
```

Each mixin has an alias.  
Use `Grab` for `StatelessGrabMixin` or `Grabful` for `StatefulMixin` if you like shorter names.

```dart
class MyWidget extends StatelessWidget with Grab
```

```dart
class MyWidget extends StatefulWidget with Grabful
```

### Extensions

You can use `grab()` and `grabAt()` on a BuildContext.  
They are like `watch()` and `select()` of package:provider.

Make sure to add a mixin to the StatelessWidget/StatefulMixin where these extensions are used.
An error occurs otherwise. 

#### grab()

`grab()` listens to the listenable passed to it, and the widget that the BuildContext
belongs to is rebuilt every time the listenable is updated.

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

The return value is the listenable itself, or its value if the listenable is `ValueListenable`.

In the above example, the listenable is a `ValueNotifier` extending `ValueListenable`, so
the `count` returned by `grab()` is not the listenable itself but the value of ValueNotifier.

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

The selector receives the listenable itself, or its value if the listenable is `ValueListenable`.

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
