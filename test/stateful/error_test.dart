import 'package:flutter_test/flutter_test.dart';

import 'package:grab/grab.dart';

import '../common/notifiers.dart';
import '../common/widgets.dart';

void main() {
  group('GrabMissingError', () {
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

    testWidgets(
      'Throws if grab() is used on Listenable in StatefulWidget '
      'without Grab as ancestor',
      (tester) async {
        await tester.pumpWidget(
          TestStatefulWidget(
            funcCalledInBuild: (context) {
              changeNotifier.grab(context);
            },
          ),
        );
        expect(tester.takeException(), isA<GrabMissingError>());
      },
    );

    testWidgets(
      'Throws if grabAt() is used on Listenable in StatefulWidget '
      'without Grab as ancestor',
      (tester) async {
        await tester.pumpWidget(
          TestStatefulWidget(
            funcCalledInBuild: (context) {
              changeNotifier.grabAt(context, (_) => null);
            },
          ),
        );
        expect(tester.takeException(), isA<GrabMissingError>());
      },
    );

    testWidgets(
      'Throws if grab() is used on ValueListenable in StatefulWidget '
      'without Grab as ancestor',
      (tester) async {
        await tester.pumpWidget(
          TestStatefulWidget(
            funcCalledInBuild: (context) {
              valueNotifier.grab(context);
            },
          ),
        );
        expect(tester.takeException(), isA<GrabMissingError>());
      },
    );

    testWidgets(
      'Throws if grabAt() is used on ValueListenable in StatefulWidget '
      'without Grab as ancestor',
      (tester) async {
        await tester.pumpWidget(
          TestStatefulWidget(
            funcCalledInBuild: (context) {
              valueNotifier.grabAt(context, (_) => null);
            },
          ),
        );
        expect(tester.takeException(), isA<GrabMissingError>());
      },
    );
  });
}
