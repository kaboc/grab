class RebuildHandler {
  const RebuildHandler({
    required this.listenerRemover,
    required this.rebuildDeciders,
  });

  final void Function() listenerRemover;
  final List<bool Function()> rebuildDeciders;

  void dispose() {
    listenerRemover();
    rebuildDeciders.clear();
  }
}
