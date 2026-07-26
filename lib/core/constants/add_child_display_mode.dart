/// How the parent home screen surfaces the "Add child" action.
enum AddChildDisplayMode {
  inline(
    id: 'inline',
    title: 'In section header',
    description: 'Shows a clear "Add child" button next to My Children.',
  ),
  floating(
    id: 'floating',
    title: 'Floating button',
    description: 'Shows a floating "Add child" button on the home screen.',
  ),
  hidden(
    id: 'hidden',
    title: 'Hidden',
    description: 'Only available from the side menu when you need it.',
  );

  const AddChildDisplayMode({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;

  static AddChildDisplayMode fromId(String? value) {
    for (final mode in AddChildDisplayMode.values) {
      if (mode.id == value) return mode;
    }
    return AddChildDisplayMode.inline;
  }
}
