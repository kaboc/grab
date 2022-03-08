import 'mixins.dart';

/// An alias for [StatelessGrabMixin] for those who prefer a shorter name.
///
/// See [StatelessGrabMixin] for details.
typedef Grab = StatelessGrabMixin;

/// An alias for [StatefulGrabMixin] for those who prefer a shorter name.
///
/// See [StatefulGrabMixin] for details.
typedef Grabful = StatefulGrabMixin;

/// The signature of a callback that receives an object of type [R] and
/// returns a value of type [S] chosen out of it.
typedef GrabSelector<R, S> = S Function(R);
