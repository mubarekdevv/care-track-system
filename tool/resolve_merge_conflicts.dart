import 'dart:io';

/// Keeps the HEAD (ours) side of git merge conflict markers.
/// Also truncates mangled healthcare_dashboard.dart tail and removes conflicted pubspec.lock.
/// Run: dart tool/resolve_merge_conflicts.dart
void main() {
  final pattern = RegExp(
    r'<<<<<<< HEAD\r?\n(.*?)=======\r?\n.*?>>>>>>> [^\r\n]+\r?\n',
    dotAll: true,
  );

  var count = 0;
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final text = entity.readAsStringSync();
    if (!text.contains('<<<<<<< HEAD')) continue;

    final resolved = text.replaceAllMapped(pattern, (match) => match.group(1)!);
    if (resolved == text) {
      stderr.writeln('Warning: no blocks resolved in ${entity.path}');
      continue;
    }
    entity.writeAsStringSync(resolved);
    stdout.writeln('resolved ${entity.path}');
    count++;
  }

  const healthcarePath = 'lib/screens/healthcare/healthcare_dashboard.dart';
  final healthcareFile = File(healthcarePath);
  if (healthcareFile.existsSync()) {
    final text = healthcareFile.readAsStringSync();
    const orphanMarker =
        "\n                                          ],\n                                        ),\n                                        Flexible(";
    final orphanIndex = text.indexOf(orphanMarker);
    if (orphanIndex != -1) {
      healthcareFile.writeAsStringSync('${text.substring(0, orphanIndex).trimRight()}\n');
      stdout.writeln('truncated orphan tail in $healthcarePath');
    }
  }

  final lockFile = File('pubspec.lock');
  if (lockFile.existsSync() && lockFile.readAsStringSync().contains('<<<<<<< HEAD')) {
    lockFile.deleteSync();
    stdout.writeln('deleted conflicted pubspec.lock');
  }

  stdout.writeln('Done. Resolved $count file(s).');
  stdout.writeln('Next: run flutter pub get && flutter analyze');
}
