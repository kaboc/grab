import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
      expect(props.grabCounter, equals(2));
    });

    testWidgets(
      'Props are reset on rebuilt by other causes than listenable update too',
      (tester) async {
        var rebuildCount = 0;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: StatefulBuilder(
              builder: (_, setState) {
                return Column(
                  children: [
                    MultiListenablesStateless(
                      listenable1: valueNotifier1,
                      listenable2: valueNotifier2,
                      selector1: (TestState state) => state.intValue,
                      selector2: (TestState state) => state.intValue,
                    ),
                    ElevatedButton(
                      child: const Text('test'),
                      onPressed: () => setState(() => rebuildCount++),
                    ),
                  ],
                );
              },
            ),
          ),
        );
        final props = find.bySubtype<MultiListenablesStateless>().debugProps;
        expect(props.grabCounter, equals(2));

        final buttonFinder = find.byType(ElevatedButton).first;
        for (var i = 1; i <= 3; i++) {
          await tester.tap(buttonFinder);
          await tester.pump();

          final newProps =
              find.bySubtype<MultiListenablesStateless>().debugProps;
          expect(rebuildCount, equals(i));
          expect(newProps.grabCounter, equals(2));
        }
      },
    );
  });
}

class _Properties {
  const _Properties(this.grabListenables, this.grabCounter);

  final List<Listenable> grabListenables;
  final int grabCounter;
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
    var listenables = <Listenable>[];
    var counter = 0;

    for (final prop in this) {
      if (prop.name == 'grabListenables') {
        listenables = [
          for (final v in prop.value! as List<Object?>) v! as Listenable,
        ];
      } else if (prop.name == 'grabCounter') {
        counter = (prop.value ?? 0) as int;
      }
    }

    return _Properties(listenables, counter);
  }
}
