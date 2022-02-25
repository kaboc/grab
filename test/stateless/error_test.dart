import 'package:flutter_test/flutter_test.dart';

import '../common/notifiers.dart';
import '../common/stateless_widgets.dart';

void main() {
  group('AssertionError when without mixin', () {
    late TestChangeNotifier notifier;

    setUp(() => notifier = TestChangeNotifier());
    tearDown(() => notifier.dispose());

    testWidgets('StatelessWidget without mixin throws', (tester) async {
      await tester.pumpWidget(NoMixinStateless(listenable: notifier));
      final error = tester.takeException() as Object;

      expect(error, isAssertionError);
      expect((error as AssertionError).message, contains('Mixin'));
    });
  });
}
