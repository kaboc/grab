import 'package:flutter_test/flutter_test.dart';

import '../common/notifiers.dart';
import '../common/stateful_widgets.dart';

void main() {
  late TestChangeNotifier changeNotifier;
  late TestValueNotifier valueNotifier;

  setUp(() {
    changeNotifier = TestChangeNotifier();
    valueNotifier = TestValueNotifier();
  });
  tearDown(() {
    changeNotifier.dispose();
    valueNotifier.dispose();
  });

  group('grab', () {
    testWidgets(
      'With non-ValueListenable, listenable itself is returned',
      (tester) async {
        Object? value;
        await tester.pumpWidget(
          GrabStateful(
            listenable: changeNotifier,
            onBuild: (Object v) => value = v,
          ),
        );
        expect(value, equals(changeNotifier));
      },
    );

    testWidgets(
      'With ValueListenable, its value is returned',
      (tester) async {
        Object? value;
        await tester.pumpWidget(
          GrabStateful(
            listenable: valueNotifier,
            onBuild: (Object v) => value = v,
          ),
        );
        expect(value, equals(valueNotifier.value));
      },
    );

    testWidgets(
      'Rebuilds widget and returns latest value when listenable is updated',
      (tester) async {
        valueNotifier.updateIntValue(10);

        Object? value;
        await tester.pumpWidget(
          GrabStateful(
            listenable: valueNotifier,
            onBuild: (Object v) => value = v,
          ),
        );

        valueNotifier.updateIntValue(20);
        await tester.pump();
        expect(value, equals(const TestState(intValue: 20, stringValue: '')));
      },
    );
  });
}
