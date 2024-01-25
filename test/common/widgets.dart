import 'package:flutter/material.dart';

class TestStatelessWidget extends StatelessWidget {
  const TestStatelessWidget({required this.funcCalledInBuild, this.child});

  final void Function(BuildContext) funcCalledInBuild;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    funcCalledInBuild(context);
    return child ?? const SizedBox.shrink();
  }
}

class TestStatefulWidget extends StatefulWidget {
  const TestStatefulWidget({required this.funcCalledInBuild});

  final void Function(BuildContext) funcCalledInBuild;

  @override
  State<TestStatefulWidget> createState() => _TestStatefulWidgetState();
}

class _TestStatefulWidgetState extends State<TestStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    widget.funcCalledInBuild(context);
    return const SizedBox.shrink();
  }
}
