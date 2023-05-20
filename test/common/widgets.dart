// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';

import 'package:grab/grab.dart';

class StatelessWithoutMixin extends StatelessWidget {
  const StatelessWithoutMixin({required this.funcCalledInBuild});

  final void Function(BuildContext) funcCalledInBuild;

  @override
  Widget build(BuildContext context) {
    funcCalledInBuild(context);
    return const SizedBox.shrink();
  }
}

class StatefulWithoutMixin extends StatefulWidget {
  const StatefulWithoutMixin({required this.funcCalledInBuild});

  final void Function(BuildContext) funcCalledInBuild;

  @override
  State<StatefulWithoutMixin> createState() => _StatefulWithoutMixinState();
}

class _StatefulWithoutMixinState extends State<StatefulWithoutMixin> {
  @override
  Widget build(BuildContext context) {
    widget.funcCalledInBuild(context);
    return const SizedBox.shrink();
  }
}

class StatelessWithMixin extends StatelessWidget with Grab {
  const StatelessWithMixin({required this.funcCalledInBuild});

  final void Function(BuildContext) funcCalledInBuild;

  @override
  Widget build(BuildContext context) {
    funcCalledInBuild(context);
    return const SizedBox.shrink();
  }
}

class StatefulWithMixin extends StatefulWidget with Grabful {
  const StatefulWithMixin({required this.funcCalledInBuild});

  final void Function(BuildContext) funcCalledInBuild;

  @override
  State<StatefulWithMixin> createState() => _StatefulWithMixinState();
}

class _StatefulWithMixinState extends State<StatefulWithMixin> {
  @override
  Widget build(BuildContext context) {
    widget.funcCalledInBuild(context);
    return const SizedBox.shrink();
  }
}
