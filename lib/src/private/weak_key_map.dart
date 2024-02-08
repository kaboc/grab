class WeakKeyMap<S extends Object, T> {
  final Map<int,
          ({WeakReference<S> key, T value, void Function()? finalization})>
      _properties = {};

  late final Finalizer<int> _finalizer = Finalizer((hashCode) {
    _properties[hashCode]?.finalization?.call();
    _properties.remove(hashCode);
  });

  Iterable<int> get keyHashes => _properties.keys;

  void addOrUpdate(S key, T value, {void Function(T?)? finalization}) {
    final hashCode = key.hashCode;
    if (!_properties.containsKey(hashCode)) {
      _finalizer.attach(key, hashCode, detach: key);
    }

    _properties[hashCode] = (
      key: WeakReference(key),
      value: value,
      finalization: finalization == null ? null : () => finalization(value),
    );
  }

  void putIfAbsent(S key, T value, {void Function(T?)? finalization}) {
    if (!_properties.containsKey(key.hashCode)) {
      addOrUpdate(key, value, finalization: finalization);
    }
  }

  T? operator [](int hashCode) {
    return _properties[hashCode]?.value;
  }

  Iterable<T> get values {
    return _properties.values.map((v) => v.value);
  }

  void reset() {
    for (final value in _properties.values) {
      value.finalization?.call();
    }
    _properties.clear();
  }
}
