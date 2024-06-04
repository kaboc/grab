/// The signature for the `selector` callback of `grabAt()` that receives
/// an object of type [R] and returns an object of type [S].
typedef GrabSelector<R, S> = S Function(R);
