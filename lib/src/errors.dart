import 'extensions.dart';
import 'mixins.dart';
import 'types.dart';

/// Error thrown when [GrabBuildContext.grab] or [GrabBuildContext.grabAt]
/// is used without a mixin, either [StatelessGrabMixin] / [Grab] in a
/// StatelessWidget or [StatefulGrabMixin] / [Grabful] in a StatefulWidget.
class GrabMixinError extends Error {
  @override
  String toString() =>
      'GrabMixinError: `grab()` and `grabAt()` are only available '
      'in a StatelessWidget with the `StatelessGrabMixin`, or in the '
      'State of a StatefulWidget with the `StatefulGrabMixin`.\n'
      'Alternatively, you can use an alias for each: `Grab` for '
      'StatelessGrabMixin, and `Grabful` for StatefulGrabMixin.';
}
