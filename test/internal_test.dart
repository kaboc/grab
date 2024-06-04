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

  test('Handlers are removed when relevant BuildContext is GCed', () async {
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

    expect(manager.handlerCounts, {hash1: 2, hash2: 1});
    expect(valueNotifier1.hasListeners, isTrue);
    expect(valueNotifier2.hasListeners, isTrue);

    element1 = null;
    await forceGC();

    expect(manager.handlerCounts, {hash2: 1});
    expect(valueNotifier1.hasListeners, isTrue);
    expect(valueNotifier2.hasListeners, isFalse);

    element2 = null;
    await forceGC();

    expect(manager.handlerCounts, isEmpty);
    expect(valueNotifier1.hasListeners, isFalse);
    expect(valueNotifier2.hasListeners, isFalse);
  });

  test('Handlers are removed when relevant listenable is GCed', () async {
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

    expect(manager.handlerCounts, {hash1: 2, hash2: 2});
    expect(tempNotifier.hasListeners, isTrue);
    expect(valueNotifier1.hasListeners, isTrue);

    tempNotifier.dispose();
    tempNotifier = null;
    await forceGC();

    expect(manager.handlerCounts, {hash1: 1, hash2: 1});
    expect(valueNotifier1.hasListeners, isTrue);

    element1 = null;
    await forceGC();

    expect(manager.handlerCounts, {hash2: 1});
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

    expect(manager.handlerCounts, {hash1: 2, hash2: 1});
    expect(valueNotifier1.hasListeners, isTrue);
    expect(valueNotifier2.hasListeners, isTrue);
    expect(grabCallFlags, isNotEmpty);

    manager.dispose();

    expect(manager.handlerCounts, isEmpty);
    expect(valueNotifier1.hasListeners, isFalse);
    expect(valueNotifier2.hasListeners, isFalse);
    expect(grabCallFlags, isEmpty);
  });

  testWidgets(
    'isFirstCallInCurrentBuild flag in listen method is only true during first '
    'call in a build even if the method is called multiple times in the build',
    (tester) async {
      final records = <({int contextHash, bool firstCall})>[];
      GrabManager.onGrabCallEnd = records.add;

      int? hash1;
      int? hash2;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Grab(
            child: StatefulBuilder(
              builder: (context, setState) {
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
      var tapCount = 0;
      int? hash1;
      int? hash2;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Grab(
            child: StatefulBuilder(
              builder: (context, setState) {
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

      expect(grabCallFlags, {hash1: true, hash2: true});

      await tester.tap(buttonFinder);
      await tester.pump();
      expect(grabCallFlags, {hash2: true});

      await tester.tap(buttonFinder);
      await tester.pump();
      expect(grabCallFlags, isEmpty);
    },
  );
}
