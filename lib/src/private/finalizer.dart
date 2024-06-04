class CustomFinalizer {
  final Map<int, List<void Function(int)>> _callbacks = {};

  late final Finalizer<int> _finalizer = Finalizer((hashCode) {
    if (_callbacks[hashCode] case final callbacks?) {
      for (final callback in callbacks) {
        callback.call(hashCode);
      }
    }
    _callbacks.remove(hashCode);
  });

  void dispose() {
    for (final hashCode in _callbacks.keys) {
      for (final callback in _callbacks[hashCode]!) {
        callback(hashCode);
      }
    }
    _callbacks.clear();
  }

  void attachIfNotYet(
    Object object, {
    required void Function(int) onFinalized,
  }) {
    final hashCode = object.hashCode;
    if (!_callbacks.containsKey(hashCode)) {
      _finalizer.attach(object, hashCode);
      _callbacks[hashCode] = [];
      _callbacks[object.hashCode]?.add(onFinalized);
    }
  }
}
