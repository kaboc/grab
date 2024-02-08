class WeakKeyMap<S extends Object, T> {
  final Map<int, ({WeakReference<S> key, T value, void Function()? finalizer})>
      _properties = {};

  late final Finalizer<int> _finalizer = Finalizer((hashCode) {
    _properties[hashCode]?.finalizer?.call();
    _properties.remove(hashCode);
  });

  Iterable<int> get keyHashes => _properties.keys;

  void addOrUpdate(S key, T value, {void Function(T)? finalizer}) {
    final hashCode = key.hashCode;
    if (!_properties.containsKey(hashCode)) {
      _finalizer.attach(key, hashCode, detach: key);
    }

    _properties[hashCode] = (
      key: WeakReference(key),
      value: value,
      finalizer: finalizer == null ? null : () => finalizer(value),
    );
  }

  T putIfAbsent(
    S key,
    T Function() ifAbsent, {
    void Function(T)? finalizer,
  }) {
    if (_properties[key.hashCode]?.value case final value?) {
      return value;
    }

    final value = ifAbsent();
    addOrUpdate(key, value, finalizer: finalizer);
    return value;
  }

  T? operator [](int hashCode) {
    return _properties[hashCode]?.value;
  }

  Iterable<T> get values {
    return _properties.values.map((v) => v.value);
  }

  void reset() {
    for (final value in _properties.values) {
      value.finalizer?.call();
    }
    _properties.clear();
  }
}
