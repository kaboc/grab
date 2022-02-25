import 'package:flutter_test/flutter_test.dart';

import '../common/notifiers.dart';
import '../common/stateful_widgets.dart';

void main() {
  group('AssertionError when without mixin', () {
    late TestChangeNotifier notifier;

    setUp(() => notifier = TestChangeNotifier());
    tearDown(() => notifier.dispose());

    testWidgets('StatefulWidget without mixin throws', (tester) async {
      await tester.pumpWidget(NoMixinStateful(listenable: notifier));
      final error = tester.takeException() as Object;

      expect(error, isAssertionError);
      expect((error as AssertionError).message, contains('Mixin'));
    });
  });
}
