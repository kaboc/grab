import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'element.dart';
import 'errors.dart';
import 'extensions.dart';

/// A mixin used on [StatelessWidget] for making Grab available
/// in the widget.
///
/// {@template grab_mixin}
/// The [GrabMixinError] is thrown if either [GrabBuildContext.grab]
/// or [GrabBuildContext.grabAt] is used without this mixin.
/// {@endtemplate}
mixin StatelessGrabMixin on StatelessWidget {
  @override
  @nonVirtual
  StatelessElement createElement() => _StatelessElement(this);
}

class _StatelessElement extends StatelessElement with GrabElement {
  _StatelessElement(StatelessWidget widget) : super(widget);
}

/// A mixin used on a [StatefulWidget] for making Grab available
/// in the widget.
///
/// {@macro grab_mixin}
mixin StatefulGrabMixin on StatefulWidget {
  @override
  @nonVirtual
  StatefulElement createElement() => _StatefulElement(this);
}

class _StatefulElement extends StatefulElement with GrabElement {
  _StatefulElement(StatefulWidget widget) : super(widget);
}
