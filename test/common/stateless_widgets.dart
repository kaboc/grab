// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';

import 'package:grab/grab.dart';

class NoMixinStateless extends StatelessWidget {
  const NoMixinStateless({required this.listenable});

  final Listenable listenable;

  @override
  Widget build(BuildContext context) {
    context.grab<Object>(listenable);
    return const SizedBox.shrink();
  }
}

class GrabStateless extends StatelessWidget with Grab {
  const GrabStateless({
    required this.listenable,
    required this.onBuild,
  });

  final Listenable listenable;
  final ValueChanged<Object> onBuild;

  @override
  Widget build(BuildContext context) {
    final value = context.grab<Object>(listenable);
    onBuild(value);

    return const SizedBox.shrink();
  }
}

class GrabAtStateless<R, S> extends StatelessWidget with Grab {
  const GrabAtStateless({
    required this.listenable,
    required this.selector,
    this.onBuild,
  });

  final Listenable listenable;
  final GrabSelector<R, S> selector;
  final ValueChanged<S>? onBuild;

  @override
  Widget build(BuildContext context) {
    final value = context.grabAt(listenable, selector);
    onBuild?.call(value);

    return const SizedBox.shrink();
  }
}

class MultiGrabAtsStateless<R, S1, S2> extends StatelessWidget {
  const MultiGrabAtsStateless({
    required this.listenable,
    required this.selector1,
    required this.selector2,
    required this.onBuild1,
    required this.onBuild2,
  });

  final Listenable listenable;
  final GrabSelector<R, S1> selector1;
  final GrabSelector<R, S2> selector2;
  final ValueChanged<S1> onBuild1;
  final ValueChanged<S2> onBuild2;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GrabAtStateless(
          listenable: listenable,
          selector: selector1,
          onBuild: onBuild1,
        ),
        GrabAtStateless(
          listenable: listenable,
          selector: selector2,
          onBuild: onBuild2,
        ),
      ],
    );
  }
}

class MultiListenablesStateless<R1, R2, S1, S2> extends StatelessWidget
    with Grab {
  const MultiListenablesStateless({
    required this.listenable1,
    required this.listenable2,
    required this.selector1,
    required this.selector2,
    required this.onBuild,
  });

  final Listenable listenable1;
  final Listenable listenable2;
  final GrabSelector<R1, S1> selector1;
  final GrabSelector<R2, S2> selector2;
  final void Function(S1, S2) onBuild;

  @override
  Widget build(BuildContext context) {
    final value1 = context.grabAt(listenable1, selector1);
    final value2 = context.grabAt(listenable2, selector2);
    onBuild.call(value1, value2);

    return const SizedBox.shrink();
  }
}

class ExtOrderSwitchStateless<R, S1, S2> extends StatelessWidget with Grab {
  const ExtOrderSwitchStateless({
    required this.flagNotifier,
    required this.listenable,
    required this.selector1,
    required this.selector2,
    required this.onBuild,
  });

  final ValueNotifier<bool> flagNotifier;
  final Listenable listenable;
  final GrabSelector<R, S1> selector1;
  final GrabSelector<R, S2> selector2;
  final void Function(S1, S2, bool) onBuild;

  @override
  Widget build(BuildContext context) {
    late final S1 value1;
    late final S2 value2;

    return ValueListenableBuilder<bool>(
      valueListenable: flagNotifier,
      builder: (_, flag, child) {
        if (flag) {
          value1 = context.grabAt(listenable, selector1);
          value2 = context.grabAt(listenable, selector2);
        } else {
          value2 = context.grabAt(listenable, selector2);
          value1 = context.grabAt(listenable, selector1);
        }
        onBuild.call(value1, value2, flag);

        return child!;
      },
      child: const SizedBox.shrink(),
    );
  }
}
