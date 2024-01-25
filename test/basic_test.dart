import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grab/grab.dart';

import 'common/notifiers.dart';
import 'common/widgets.dart';

void main() {
  late TestValueNotifier valueNotifier;

  setUp(() => valueNotifier = TestValueNotifier());
  tearDown(() => valueNotifier.dispose());

  testWidgets(
    'The furthest Grab is used without error if there is more than one',
    (tester) async {
      BuildContext? targetContext;
      int? value;

      final grab2 = Grab(
        child: TestStatelessWidget(
          funcCalledInBuild: (context) {
            targetContext = context;
            value = valueNotifier.grabAt(context, (n) => n.intValue);
          },
        ),
      );
      final grab1 = Grab(child: grab2);
      await tester.pumpWidget(grab1);

      expect(Grab.stateOf(targetContext!)!.widget, same(grab1));

      valueNotifier.updateIntValue(10);
      await tester.pump();
      expect(value, 10);
    },
  );

  testWidgets(
    'Only the widget associated with the provided BuildContext is rebuilt',
    (tester) async {
      var parentBuildCount = 0;
      var targetBuildContext = 0;

      await tester.pumpWidget(
        Grab(
          child: TestStatelessWidget(
            funcCalledInBuild: (context) => parentBuildCount++,
            child: Builder(
              builder: (context) {
                targetBuildContext++;
                valueNotifier.grab(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(parentBuildCount, 1);
      expect(targetBuildContext, 1);

      valueNotifier.updateStringValue('abc');
      await tester.pump();
      expect(parentBuildCount, 1);
      expect(targetBuildContext, 2);
    },
  );

  testWidgets(
    'No error is thrown when notifier notifies after a widget that was '
    'listening to the notifier is removed',
    (tester) async {
      var visible = true;
      int? value;

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
                        value =
                            valueNotifier.grabAt(context, (n) => n.intValue);
                      },
                    ),
                    if (visible)
                      TestStatelessWidget(
                        funcCalledInBuild: (context) {
                          valueNotifier.grab(context);
                        },
                      ),
                    ElevatedButton(
                      onPressed: () => setState(() => visible = !visible),
                      child: const Text('Button'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(TestStatelessWidget), findsNWidgets(2));

      final buttonFinder = find.byType(ElevatedButton).first;
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(find.byType(TestStatelessWidget), findsOneWidget);

      valueNotifier.updateIntValue(10);
      await tester.pump();

      expect(find.byType(TestStatelessWidget), findsOneWidget);
      expect(value, 10);
    },
  );
}
