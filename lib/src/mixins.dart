import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'element.dart';
import 'errors.dart';
import 'types.dart';

/// A mixin used on [StatelessWidget] for making Grab available
/// in the widget.
///
/// ```dart
/// class MyWidget extends StatelessWidget with StatelessGrabMixin {
///   ...
/// }
/// ```
///
/// You can use [Grab] instead of [StatelessGrabMixin]. It is just
/// a shorter alias.
///
/// {@template grab.alias.grab.example}
/// ```dart
/// class MyWidget extends StatelessWidget with Grab {
///   ...
/// }
/// ```
/// {@endtemplate}
///
/// {@template grab.mixin}
/// The [GrabMixinError] is thrown if either `grab()` or `grabAt()`
/// is used without this mixin.
/// {@endtemplate}
mixin StatelessGrabMixin on StatelessWidget {
  @override
  @nonVirtual
  StatelessElement createElement() => _StatelessElement(this);
}

class _StatelessElement extends StatelessElement with GrabElement {
  _StatelessElement(super.widget);
}

/// A mixin used on a [StatefulWidget] for making Grab available
/// in the widget.
///
/// ```dart
/// class MyWidget extends StatefulWidget with StatefulGrabMixin {
///   ...
/// }
/// ```
///
/// You can use [Grabful] instead of [StatefulGrabMixin]. It is just
/// a shorter alias.
///
/// {@template grab.alias.grabful.example}
/// ```dart
/// class MyWidget extends StatefulWidget with Grabful {
///   ...
/// }
/// ```
/// {@endtemplate}
///
/// {@macro grab.mixin}
mixin StatefulGrabMixin on StatefulWidget {
  @override
  @nonVirtual
  StatefulElement createElement() => _StatefulElement(this);
}

class _StatefulElement extends StatefulElement with GrabElement {
  _StatefulElement(super.widget);
}
