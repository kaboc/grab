import 'package:flutter_test/flutter_test.dart';

import 'package:grab/grab.dart';

import '../common/notifiers.dart';
import '../common/stateful_widgets.dart';

void main() {
  group('GrabMixinError', () {
    late TestChangeNotifier notifier;

    setUp(() => notifier = TestChangeNotifier());
    tearDown(() => notifier.dispose());

    testWidgets(
      'Throws if grab() is used in StatefulWidget without mixin',
      (tester) async {
        await tester.pumpWidget(
          GrabWithoutMixinStateful(listenable: notifier),
        );
        expect(tester.takeException(), isA<GrabMixinError>());
      },
    );

    testWidgets(
      'Throws if grabAt() is used in StatefulWidget without mixin',
      (tester) async {
        await tester.pumpWidget(
          GrabAtWithoutMixinStateful(listenable: notifier),
        );
        expect(tester.takeException(), isA<GrabMixinError>());
      },
    );
  });
}
