// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grab/grab.dart';
import 'package:grab/src/private/manager.dart';

import 'common/notifiers.dart';
import 'common/utils.dart';
import 'common/widgets.dart';

void main() {
  late TestValueNotifier valueNotifier1;
  late TestValueNotifier valueNotifier2;
  late TestValueNotifier valueNotifier3;
  late TestValueNotifier valueNotifier4;

  setUp(() {
    valueNotifier1 = TestValueNotifier();
    valueNotifier2 = TestValueNotifier();
    valueNotifier3 = TestValueNotifier();
    valueNotifier4 = TestValueNotifier();
  });
  tearDown(() {
    valueNotifier1.dispose();
    valueNotifier2.dispose();
    valueNotifier3.dispose();
    valueNotifier4.dispose();
  });

  test('Listeners are removed when relevant BuildContext is GCed', () async {
    final manager = GrabManager();
    addTearDown(manager.dispose);

    Element? element1 = StatelessElement(const Text(''));
    Element? element2 = StatelessElement(const Text(''));
    final hash1 = element1.hashCode;
    final hash2 = element2.hashCode;

    manager
      ..listen(
        context: element1,
        listenable: valueNotifier1,
        selector: (notifier) => notifier,
      )
      ..listen(
        context: element1,
        listenable: valueNotifier2,
        selector: (notifier) => notifier,
      )
      ..listen(
        context: element1,
        listenable: valueNotifier2,
        selector: (notifier) => notifier,
      )
      ..listen(
        context: element2,
        listenable: valueNotifier1,
        selector: (notifier) => notifier,
      );

    expect(manager.listenerCounts, {hash1: 2, hash2: 1});
    expect(valueNotifier1.hasListeners, isTrue);
    expect(valueNotifier2.hasListeners, isTrue);

    element1 = null;
    await forceGC();

    expect(manager.listenerCounts, {hash2: 1});
    expect(valueNotifier1.hasListeners, isTrue);
    expect(valueNotifier2.hasListeners, isFalse);

    element2 = null;
    await forceGC();

    expect(manager.listenerCounts, isEmpty);
    expect(valueNotifier1.hasListeners, isFalse);
    expect(valueNotifier2.hasListeners, isFalse);
  });

  test('Listeners are removed when relevant listenable is GCed', () async {
    final manager = GrabManager();
    TestValueNotifier? tempNotifier = TestValueNotifier();
    addTearDown(() {
      manager.dispose();
      tempNotifier?.dispose();
    });

    Element? element1 = StatelessElement(const Text(''));
    final element2 = StatelessElement(const Text(''));
    final hash1 = element1.hashCode;
    final hash2 = element2.hashCode;

    manager
      ..listen(
        context: element1,
        listenable: tempNotifier,
        selector: (notifier) => notifier,
      )
      ..listen(
        context: element1,
        listenable: valueNotifier1,
        selector: (notifier) => notifier,
      )
      ..listen(
        context: element2,
        listenable: tempNotifier,
        selector: (notifier) => notifier,
      )
      ..listen(
        context: element2,
        listenable: valueNotifier1,
        selector: (notifier) => notifier,
      );

    expect(manager.listenerCounts, {hash1: 2, hash2: 2});
    expect(tempNotifier.hasListeners, isTrue);
    expect(valueNotifier1.hasListeners, isTrue);

    tempNotifier.dispose();
    tempNotifier = null;
    await forceGC();

    expect(manager.listenerCounts, {hash1: 1, hash2: 1});
    expect(valueNotifier1.hasListeners, isTrue);

    element1 = null;
    await forceGC();

    expect(manager.listenerCounts, {hash2: 1});
    expect(valueNotifier1.hasListeners, isTrue);
  });

  test('Resources are discarded if GrabManager is disposed', () async {
    final manager = GrabManager();

    final element1 = StatelessElement(const Text(''));
    final element2 = StatelessElement(const Text(''));
    final hash1 = element1.hashCode;
    final hash2 = element2.hashCode;

    manager
      ..listen(
        context: element1,
        listenable: valueNotifier1,
        selector: (notifier) => notifier,
      )
      ..listen(
        context: element1,
        listenable: valueNotifier2,
        selector: (notifier) => notifier,
      )
      ..listen(
        context: element1,
        listenable: valueNotifier2,
        selector: (notifier) => notifier,
      )
      ..listen(
        context: element2,
        listenable: valueNotifier1,
        selector: (notifier) => notifier,
      );

    expect(manager.grabCallFlags, isNotEmpty);
    expect(manager.listenerCounts, {hash1: 2, hash2: 1});
    expect(valueNotifier1.hasListeners, isTrue);
    expect(valueNotifier2.hasListeners, isTrue);

    manager.dispose();

    expect(manager.grabCallFlags, isEmpty);
    expect(manager.listenerCounts, isEmpty);
    expect(valueNotifier1.hasListeners, isFalse);
    expect(valueNotifier2.hasListeners, isFalse);
  });

  test(
    'BuildContext keeps being referenced if selector of grabAt() has captured '
    'outer variable, but gets unreferenced a while after onBeforeBuild() call',
    () async {
      final manager = GrabManager();

      UnmountableBuildContext? context = UnmountableBuildContext();
      final hash = context.hashCode;

      manager.listen(
        context: context,
        listenable: valueNotifier1,
        selector: (notifier) => context,
      );

      expect(manager.existingContextHash, [hash]);
      expect(manager.listenerCounts, {hash: 1});

      context.mounted = false;
      context = null;

      // GC does not work for the BuildContext that is still referenced.
      await forceGC();
      expect(manager.existingContextHash, [hash]);
      expect(manager.listenerCounts, {hash: 1});

      const cleanUpDelay = Duration(milliseconds: 20);

      // Clean-up (i.e. removal of selector stored in a map) is debounced
      // while build keeps occurring at shorter intervals than clean-up delay.
      for (var i = 0; i < 5; i++) {
        manager.onBeforeBuild(cleanUpDelay: cleanUpDelay);
        await Future<void>.delayed(cleanUpDelay ~/ 2);

        expect(manager.existingContextHash, [hash]);
        expect(manager.listenerCounts, {hash: 1});
      }

      // Clean-up is performed when the delay duration elapses.
      manager.onBeforeBuild(cleanUpDelay: cleanUpDelay);
      await Future<void>.delayed(cleanUpDelay);
      expect(manager.existingContextHash, isEmpty);
      expect(manager.listenerCounts, {hash: 1});

      // GC works now. It triggers finalizer, which removes listeners.
      await forceGC();
      expect(manager.listenerCounts, isEmpty);
    },
  );

  testWidgets(
    'Timer to clean up rebuild deciders is cancelled and context hashes '
    'in _wrContexts are cleared quickly when Grab is disposed.',
    (tester) async {
      GrabManager? manager;
      var visible = true;
      int? hash;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) {
              return visible
                  ? Grab(
                      child: Builder(
                        builder: (context) {
                          manager ??= Grab.stateOf(context)?.manager;
                          hash = context.hashCode;
                          valueNotifier1.grab(context);

                          return Column(
                            children: [
                              ElevatedButton(
                                onPressed: () => setState(() {}),
                                child: const Text('btn1'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    setState(() => visible = false),
                                child: const Text('btn2'),
                              ),
                            ],
                          );
                        },
                      ),
                    )
                  : const SizedBox();
            },
          ),
        ),
      );

      final rebuildButtonFinder = find.widgetWithText(ElevatedButton, 'btn1');
      final hideButtonFinder = find.widgetWithText(ElevatedButton, 'btn2');

      // A rebuild triggers onBeforeBuild, where clean-up timer is started.
      await tester.tap(rebuildButtonFinder);
      await tester.pump();

      // The timer ends after a fixed duration.
      for (var i = 0; i < 5; i++) {
        await tester.binding.delayed(kRebuildDecidersCleanUpDelay ~/ 5);
        expect(manager?.isAwaitingCleanUp, i < 4);
        expect(manager?.existingContextHash, [hash]);
      }

      // Another rebuild starts the timer again.
      await tester.tap(rebuildButtonFinder);
      await tester.pump();
      expect(manager?.isAwaitingCleanUp, isTrue);
      expect(manager?.existingContextHash, [hash]);

      // Removing Grab before the timer ends stops the timer quickly.
      await tester.tap(hideButtonFinder);
      await tester.pump();
      expect(manager?.isAwaitingCleanUp, isFalse);
      expect(manager?.existingContextHash, isEmpty);
    },
  );

  testWidgets(
    'isFirstCallInCurrentBuild flag in listen method is only true during first '
    'call in a build even if the method is called multiple times in the build',
    (tester) async {
      final records = <({int contextHash, bool firstCall})>[];
      int? hash1;
      int? hash2;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Grab(
            child: StatefulBuilder(
              builder: (context, setState) {
                final manager = Grab.stateOf(context)?.manager;
                manager?.onGrabCallEnd ??= records.add;

                return Column(
                  children: [
                    TestStatelessWidget(
                      funcCalledInBuild: (context) {
                        hash1 = context.hashCode;
                        valueNotifier1.grab(context);
                        valueNotifier2.grab(context);
                      },
                    ),
                    TestStatelessWidget(
                      funcCalledInBuild: (context) {
                        hash2 = context.hashCode;
                        valueNotifier3.grab(context);
                        valueNotifier4.grab(context);
                      },
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Button'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(records, [
        (contextHash: hash1, firstCall: true),
        (contextHash: hash1, firstCall: false),
        (contextHash: hash2, firstCall: true),
        (contextHash: hash2, firstCall: false),
      ]);

      records.clear();

      // Rebuilding a particular widget by an update of ValueNotifier.
      valueNotifier4.updateIntValue(10);
      await tester.pump();

      expect(records, [
        (contextHash: hash2, firstCall: true),
        (contextHash: hash2, firstCall: false),
      ]);

      records.clear();

      // Rebuilding multiple widgets.
      final buttonFinder = find.byType(ElevatedButton).first;
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(records, [
        (contextHash: hash1, firstCall: true),
        (contextHash: hash1, firstCall: false),
        (contextHash: hash2, firstCall: true),
        (contextHash: hash2, firstCall: false),
      ]);
    },
  );

  testWidgets(
    'Grab call flags are cleared before the first build in a frame, '
    'and set again at first listen() call in a build of every widget',
    (tester) async {
      GrabManager? manager;
      var tapCount = 0;
      int? hash1;
      int? hash2;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Grab(
            child: StatefulBuilder(
              builder: (context, setState) {
                manager ??= Grab.stateOf(context)?.manager;

                return Column(
                  children: [
                    if (tapCount < 1)
                      TestStatelessWidget(
                        funcCalledInBuild: (context) {
                          hash1 = context.hashCode;
                          valueNotifier1.grab(context);
                        },
                      ),
                    if (tapCount < 2)
                      TestStatelessWidget(
                        funcCalledInBuild: (context) {
                          hash2 = context.hashCode;
                          valueNotifier2.grab(context);
                        },
                      ),
                    ElevatedButton(
                      onPressed: () => setState(() => tapCount++),
                      child: const Text('Button'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(ElevatedButton).first;

      expect(manager?.grabCallFlags, {hash1: true, hash2: true});

      await tester.tap(buttonFinder);
      await tester.pump();
      expect(manager?.grabCallFlags, {hash2: true});

      await tester.tap(buttonFinder);
      await tester.pump();
      expect(manager?.grabCallFlags, isEmpty);
    },
  );
}
