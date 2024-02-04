// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';

import 'errors.dart';
import 'grab.dart';
import 'private/stream_value_notifier.dart';

final Map<int, Map<int, StreamValueNotifier<Object?>>> _notifiers = {};

final Finalizer<int> _finalizer = Finalizer((contextHash) {
  final notifiers = _notifiers[contextHash];
  if (notifiers != null) {
    notifiers
      ..forEach((_, v) => v.dispose())
      ..clear();
    _notifiers.remove(contextHash);
  }
});

extension GrabStreamExtension<R> on Stream<R> {
  R grab(BuildContext context) {
    return grabAt(context, (value) => value);
  }

  S grabAt<S>(BuildContext context, GrabSelector<R, S> selector) {
    final grabState = Grab.stateOf(context);
    if (grabState == null) {
      throw GrabMissingError();
    }

    final contextHash = context.hashCode;
    _finalizer.attach(context, contextHash, detach: context);

    final streamHash = hashCode;
    _notifiers[contextHash] ??= {};
    _notifiers[contextHash]![streamHash] ??= StreamValueNotifier(this);

    return grabState.listen(
      context: context,
      listenable: _notifiers[contextHash]![streamHash]!,
      selector: selector,
    );
  }
}
