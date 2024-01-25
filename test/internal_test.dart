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

  test(
    'BuildContext is stored in GrabManager when grab methods are called '
    'and then removed when GCed',
    () async {
      final manager = GrabManager();
      addTearDown(manager.dispose);

      Element? element1 = StatelessElement(const Text(''));
      final element2 = StatelessElement(const Text(''));
      final wrContext1 = WeakReference<BuildContext>(element1);
      final wrContext2 = WeakReference<BuildContext>(element2);

      final hash1 = wrContext1.target.hashCode;
      final hash2 = wrContext2.target.hashCode;

      manager
        ..listen(
          context: wrContext1.target!,
          listenable: valueNotifier1,
          selector: (notifier) => notifier,
        )
        ..listen(
          context: wrContext2.target!,
          listenable: valueNotifier2,
          selector: (notifier) => notifier,
        );

      expect(manager.contextHashes, [hash1, hash2]);

      element1 = null;
      await forceGC();

      expect(manager.contextHashes, [hash2]);
    },
  );

  testWidgets(
    'Only handlers for widget to be built are reset right before the build '
    'and not after that, and then reset again before the next build',
    (tester) async {
      final records = <({int contextHash, bool wasReset})>[];
      GrabManager.onHandlersReset = records.add;

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
        (contextHash: hash1, wasReset: true),
        (contextHash: hash1, wasReset: false),
        (contextHash: hash2, wasReset: true),
        (contextHash: hash2, wasReset: false),
      ]);

      records.clear();
      expect(records, isEmpty);

      // Rebuilding a particular widget by an update of ValueNotifier.
      valueNotifier4.updateIntValue(10);
      await tester.pump();

      expect(records, [
        (contextHash: hash2, wasReset: true),
        (contextHash: hash2, wasReset: false),
      ]);

      records.clear();
      expect(records, isEmpty);

      // Rebuilding multiple widgets.
      final buttonFinder = find.byType(ElevatedButton).first;
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(records, [
        (contextHash: hash1, wasReset: true),
        (contextHash: hash1, wasReset: false),
        (contextHash: hash2, wasReset: true),
        (contextHash: hash2, wasReset: false),
      ]);
    },
  );
}
