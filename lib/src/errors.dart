import 'grab.dart' show Grab;

/// Error thrown when `grab()` or `grabAt()` is used without a [Grab]
/// up in the widget tree.
class GrabMissingError extends Error {
  @override
  String toString() =>
      'GrabMissingError: `grab()` and `grabAt()` are not available '
      'unless there is a `Grab` as an ancestor.';
}
