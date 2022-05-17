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

      final finder = find.bySubtype<MultiListenablesStateless>();
      var props = finder.debugProps;
      expect(props.grabListenables, equals([valueNotifier1, valueNotifier2]));
      expect(props.grabValues, equals([0, 0]));

      valueNotifier1.updateIntValue(10);
      valueNotifier2.updateIntValue(20);
      await tester.pump();

      props = finder.debugProps;
      expect(props.grabValues, equals([10, 20]));
    });
  });
}

class _Properties {
  const _Properties(this.grabListenables, this.grabValues);

  final List<Listenable> grabListenables;
  final List<Object> grabValues;
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
    var grabValues = <Object>[];

    for (final prop in this) {
      if (prop.name == 'grabListenables') {
        grabListenables = [
          for (final v in prop.value! as List<Object?>) v! as Listenable,
        ];
      } else if (prop.name == 'grabValues') {
        grabValues = [
          for (final v in prop.value! as List<Object?>) v!,
        ];
      }
    }

    return _Properties(grabListenables, grabValues);
  }
}
