import 'package:flutter_test/flutter_test.dart';

import 'package:grab/grab.dart';

import '../common/notifiers.dart';
import '../common/widgets.dart';

void main() {
  group('GrabMixinError', () {
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
      'Throws if grab() is used on Listenable in StatelessWidget '
      'without mixin',
      (tester) async {
        await tester.pumpWidget(
          StatelessWithoutMixin(
            funcCalledInBuild: (context) {
              changeNotifier.grab(context);
            },
          ),
        );
        expect(tester.takeException(), isA<GrabMixinError>());
      },
    );

    testWidgets(
      'Throws if grabAt() is used on Listenable in StatelessWidget '
      'without mixin',
      (tester) async {
        await tester.pumpWidget(
          StatelessWithoutMixin(
            funcCalledInBuild: (context) {
              changeNotifier.grabAt(context, (_) => null);
            },
          ),
        );
        expect(tester.takeException(), isA<GrabMixinError>());
      },
    );

    testWidgets(
      'Throws if grab() is used on ValueListenable in StatelessWidget '
      'without mixin',
      (tester) async {
        await tester.pumpWidget(
          StatelessWithoutMixin(
            funcCalledInBuild: (context) {
              valueNotifier.grab(context);
            },
          ),
        );
        expect(tester.takeException(), isA<GrabMixinError>());
      },
    );

    testWidgets(
      'Throws if grabAt() is used on ValueListenable in StatelessWidget '
      'without mixin',
      (tester) async {
        await tester.pumpWidget(
          StatelessWithoutMixin(
            funcCalledInBuild: (context) {
              valueNotifier.grabAt(context, (_) => null);
            },
          ),
        );
        expect(tester.takeException(), isA<GrabMixinError>());
      },
    );
  });
}
