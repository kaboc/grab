class CustomFinalizer {
  final Map<int, void Function(int)> _callbacks = {};

  late final Finalizer<int> _finalizer = Finalizer((hashCode) {
    _callbacks[hashCode]?.call(hashCode);
    _callbacks.remove(hashCode);
  });

  void dispose() {
    for (final hashCode in _callbacks.keys) {
      _callbacks[hashCode]?.call(hashCode);
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
      _callbacks[hashCode] = onFinalized;
    }
  }
}
