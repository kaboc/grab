import 'package:flutter_test/flutter_test.dart';

import 'package:grab/grab.dart';

import '../common/notifiers.dart';
import '../common/widgets.dart';

void main() {
  group('GrabMixinError', () {
    late TestChangeNotifier notifier;

    setUp(() => notifier = TestChangeNotifier());
    tearDown(() => notifier.dispose());

    testWidgets(
      'Throws if grab() is used in StatelessWidget without mixin',
      (tester) async {
        await tester.pumpWidget(
          StatelessWithoutMixin(
            funcCalledInBuild: (context) {
              context.grab<TestChangeNotifier>(notifier);
            },
          ),
        );
        expect(tester.takeException(), isA<GrabMixinError>());
      },
    );

    testWidgets(
      'Throws if grabAt() is used in StatelessWidget without mixin',
      (tester) async {
        await tester.pumpWidget(
          StatelessWithoutMixin(
            funcCalledInBuild: (context) {
              context.grabAt(notifier, (_) => null);
            },
          ),
        );
        expect(tester.takeException(), isA<GrabMixinError>());
      },
    );
  });
}
