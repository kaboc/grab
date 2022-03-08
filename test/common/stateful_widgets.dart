// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';

import 'package:grab/grab.dart';

class NoMixinStateful extends StatefulWidget {
  const NoMixinStateful({required this.listenable});

  final Listenable listenable;

  @override
  State<NoMixinStateful> createState() => _NoMixinState();
}

class _NoMixinState extends State<NoMixinStateful> {
  @override
  Widget build(BuildContext context) {
    context.grab<Object>(widget.listenable);
    return const SizedBox.shrink();
  }
}

class GrabStateful extends StatefulWidget with Grabful {
  const GrabStateful({
    required this.listenable,
    required this.onBuild,
  });

  final Listenable listenable;
  final ValueChanged<Object> onBuild;

  @override
  State<GrabStateful> createState() => _GrabState();
}

class _GrabState extends State<GrabStateful> {
  @override
  Widget build(BuildContext context) {
    final value = context.grab<Object>(widget.listenable);
    widget.onBuild(value);

    return const SizedBox.shrink();
  }
}

class GrabAtStateful<R, S> extends StatefulWidget with Grabful {
  const GrabAtStateful({
    required this.listenable,
    required this.selector,
    this.onBuild,
  });

  final Listenable listenable;
  final GrabSelector<R, S> selector;
  final ValueChanged<S>? onBuild;

  @override
  State<GrabAtStateful<R, S>> createState() => _GrabAtState<R, S>();
}

class _GrabAtState<R, S> extends State<GrabAtStateful<R, S>> {
  @override
  Widget build(BuildContext context) {
    final value = context.grabAt(widget.listenable, widget.selector);
    widget.onBuild?.call(value);

    return const SizedBox.shrink();
  }
}

class MultiGrabAtsStateful<R, S1, S2> extends StatefulWidget {
  const MultiGrabAtsStateful({
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
  State<MultiGrabAtsStateful<R, S1, S2>> createState() =>
      _MultiGrabAtsState<R, S1, S2>();
}

class _MultiGrabAtsState<R, S1, S2>
    extends State<MultiGrabAtsStateful<R, S1, S2>> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GrabAtStateful(
          listenable: widget.listenable,
          selector: widget.selector1,
          onBuild: widget.onBuild1,
        ),
        GrabAtStateful(
          listenable: widget.listenable,
          selector: widget.selector2,
          onBuild: widget.onBuild2,
        ),
      ],
    );
  }
}

class MultiListenablesStateful<R1, R2, S1, S2> extends StatefulWidget
    with Grabful {
  const MultiListenablesStateful({
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
  State<MultiListenablesStateful<R1, R2, S1, S2>> createState() =>
      _MultiListenablesState<R1, R2, S1, S2>();
}

class _MultiListenablesState<R1, R2, S1, S2>
    extends State<MultiListenablesStateful<R1, R2, S1, S2>> {
  @override
  Widget build(BuildContext context) {
    final value1 = context.grabAt(widget.listenable1, widget.selector1);
    final value2 = context.grabAt(widget.listenable2, widget.selector2);
    widget.onBuild.call(value1, value2);

    return const SizedBox.shrink();
  }
}

class SwitchingOrderStateful<R, S1, S2> extends StatefulWidget with Grabful {
  const SwitchingOrderStateful({
    required this.listenable,
    required this.flagNotifier,
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
  State<SwitchingOrderStateful<R, S1, S2>> createState() =>
      _SwitchingOrderState<R, S1, S2>();
}

class _SwitchingOrderState<R, S1, S2>
    extends State<SwitchingOrderStateful<R, S1, S2>> {
  @override
  Widget build(BuildContext context) {
    final flag = context.grab<bool>(widget.flagNotifier);

    late final S1 value1;
    late final S2 value2;

    if (flag) {
      value1 = context.grabAt(widget.listenable, widget.selector1);
      value2 = context.grabAt(widget.listenable, widget.selector2);
    } else {
      value2 = context.grabAt(widget.listenable, widget.selector2);
      value1 = context.grabAt(widget.listenable, widget.selector1);
    }
    widget.onBuild.call(value1, value2, flag);

    return const SizedBox.shrink();
  }
}
