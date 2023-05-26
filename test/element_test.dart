import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grab/grab.dart';

import 'common/notifiers.dart';
import 'common/widgets.dart';

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
        StatelessWithMixin(
          funcCalledInBuild: (context) {
            valueNotifier1.grabAt(context, (s) => s.intValue);
            valueNotifier2.grabAt(context, (s) => s.intValue);
          },
        ),
      );

      // ignore: strict_raw_type
      final props = find.bySubtype<StatelessWithMixin>().debugProps;
      expect(props.grabListenables, equals([valueNotifier1, valueNotifier2]));
      expect(props.grabCallCounter, equals(2));
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
                    StatelessWithMixin(
                      funcCalledInBuild: (context) {
                        valueNotifier1.grabAt(context, (s) => s.intValue);
                        valueNotifier2.grabAt(context, (s) => s.intValue);
                      },
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

        // ignore: strict_raw_type
        final props = find.bySubtype<StatelessWithMixin>().debugProps;
        expect(props.grabCallCounter, equals(2));

        final buttonFinder = find.byType(ElevatedButton).first;
        for (var i = 1; i <= 3; i++) {
          await tester.tap(buttonFinder);
          await tester.pump();

          final newProps = find.bySubtype<StatelessWithMixin>().debugProps;
          expect(rebuildCount, equals(i));
          expect(newProps.grabCallCounter, equals(2));
        }
      },
    );
  });
}

class _Properties {
  const _Properties(this.grabListenables, this.grabCallCounter);

  final List<Listenable> grabListenables;
  final int grabCallCounter;
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
      } else if (prop.name == 'grabCallCounter') {
        counter = (prop.value ?? 0) as int;
      }
    }

    return _Properties(listenables, counter);
  }
}
