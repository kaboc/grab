import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common/notifiers.dart';
import 'common/stateless_widgets.dart';

void main() {
  late TestValueNotifier valueNotifier1;
  late TestValueNotifier valueNotifier2;

  setUp(() {
    valueNotifier1 = TestValueNotifier();
    valueNotifier2 = TestValueNotifier();
  });
  tearDown(() {
    valueNotifier1.dispose();
    valueNotifier2.dispose();
  });

  group('element', () {
    testWidgets('debugFillProperties()', (tester) async {
      await tester.pumpWidget(
        MultiListenablesStateless(
          listenable1: valueNotifier1,
          listenable2: valueNotifier2,
          selector1: (TestState state) => state.intValue,
          selector2: (TestState state) => state.intValue,
        ),
      );

      final props = find.bySubtype<MultiListenablesStateless>().debugProps;
      expect(props.grabListenables, equals([valueNotifier1, valueNotifier2]));
    });
  });
}

class _Properties {
  const _Properties(this.grabListenables);

  final List<Listenable> grabListenables;
}

extension on Finder {
  _Properties get debugProps {
    final builder = DiagnosticPropertiesBuilder();
    evaluate().single.debugFillProperties(builder);

    return builder.properties.get;
  }
}

extension on List<DiagnosticsNode> {
  _Properties get get {
    var grabListenables = <Listenable>[];

    for (final prop in this) {
      if (prop.name == 'grabListenables') {
        grabListenables = [
          for (final v in prop.value! as List<Object?>) v! as Listenable,
        ];
      }
    }

    return _Properties(grabListenables);
  }
}
