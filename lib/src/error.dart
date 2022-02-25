part of 'extensions.dart';

const _kErrorMessage = '`grab()` and `grabAt()` are only available '
    'in a StatelessWidget with the `StatelessGrabMixin`, or in the '
    'State of a StatefulWidget with the `StatefulGrabMixin`.\n'
    'Alternatively, you can use an alias for each: `Grab` for '
    'StatelessGrabMixin, and `Grabful` for StatefulGrabMixin.';

/// Error thrown when [GrabBuildContext.grab] or [GrabBuildContext.grabAt]
/// is used without a relevant mixin.
class GrabMixinError extends Error {
  GrabMixinError._();

  @override
  String toString() => 'GrabMixinError: $_kErrorMessage';
}
