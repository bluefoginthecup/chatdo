Future<void> showDialoguesSequentially(List<String> lines, void Function(String) show, {Duration delay = const Duration(seconds: 5)}) async {
  while (true) {
    for (final line in lines) {
      show(line);
      await Future.delayed(delay);
    }
  }
}