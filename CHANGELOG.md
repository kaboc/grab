## 1.0.0-dev.1

- Add dependency on meta.
- **Breaking:**
    - Raise minimum Flutter SDK version to 3.10.
    - Great improvements to eliminate misuse and the hassle of adding a mixin to every widget. ([#4])
        - Changes
            - Remove mixins (`StatelessGrabMixin` and `StatefulGrabMixin`) and
              aliases (`Grab` and `Grabful`).
            - Rename `GrabMixinError` to `GrabMissingError`.
            - Add `Grab` widget.
        - Migration
            - Wrap the root widget with the `Grab` widget.
            - Remove `Grab` mixins from all the widgets where they were used.
            - Remove grab_lints from your project if you were using it.
            ```dart
            void main() {
              runApp(
                // Wrap the root widget with Grab.
                const Grab(child: MyApp),
              );
            }
          
            class MyApp extends StatelessWidget { // Mixin is no longer necessary!
              @override
              Widget build(BuildContext context) {
                final v1 = notifier.grab(context);
          
                return Builder(
                  builder: (context) {
                    // You can use the BuildContext passed to the builder callback too.
                    // This was not possible until the previous version.
                    final v2 = notifier.grab(context);
                    return ...
                  },
                );
              }
            }
            ```

## 0.4.3

- Fix missing mixin in code sample in README.

## 0.4.2

- Refactor `GrabElement` for better maintainability.
- Add the "Limitations" section to README to describe the `BuildContext` that can
  be used with the grab methods.

## 0.4.1

- Small optimisations.
    - Skip check for necessity of rebuild when element is already marked as dirty.
    - Skip reset of counter for debug in production.
- Tiny refactorings.

## 0.4.0

- **Breaking:**
    - Replace `BuildContext` extension with `Listenable` and `ValueListenable` extensions.
        - Before
          ```dart
          final changeNotifier = MyChangeNotifier(value: 'value');
  
          // With ChangeNotifier
          final notifier = context.grab<MyChangeNotifier>(changeNotifier);
          final value = context.grabAt(changeNotifier, (MyChangeNotifier n) => n.value);
          ```
          ```dart
          final valueNotifier = MyValueNotifier(MyState(value: 'value'));
  
          // With ValueNotifier
          final state = context.grab<MyValueNotifier>(valueNotifier);
          final value = context.grabAt(valueNotifier, (MyState state) => state.value);
          ```
        - After\
          Simply swap the position of BuildContext and Listenable.
          Types are inferred correctly now with ValueListenable (e.g. ValueNotifier), but not with other Listenables (e.g. ChangeNotifier).
          ```dart
          // With ChangeNotifier
          final notifier = changeNotifier.grab<MyChangeNotifier>(context);
          final value = changeNotifier.grabAt(context, (MyChangeNotifier n) => n.value);
          ```
          ```dart
          // With ValueNotifier
          // More type-safe and concise now
          final state = valueNotifier.grab(context);
          final value = valueNotifier.grabAt(context, (state) => state.value);
          ```

## 0.3.1

- Refactor extension methods.
- Rename a debug property from `grabCounter` to `grabCallCounter`.
- Simplify tests for maintainability.

## 0.3.0+1

- Fix changelog.

## 0.3.0

- Bump minimum Flutter version to 3.0.0.
- Minor changes.

## 0.2.2

- Remove unnecessary list of previous values from element.
    - `grabValues` was accordingly removed from the debug properties.
- Remove duplicate `_reset()` call.
- Additional minor refactoring.

## 0.2.1

- Improve document of mixins.
- Add sample app link to README.

## 0.2.0

- Implement `debugFillProperties()`.
- Make `GrabSelector` public.
- Refactor GrabMixinError.
- Throw `GrabMixinError` instead of `AssertionError` in debug mode too.
- Improve tests.
- Improve documentation.
- Update lint rules.

## 0.1.0

- Improve documentation.
- Require Flutter >=2.10.

## 0.0.1

- Initial version.

[#4]: https://github.com/kaboc/grab/pull/4
