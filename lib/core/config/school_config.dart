/// Single-school deployment configuration.
///
/// Each customer deployment (school / childcare) uses its own Firebase project.
/// [defaultSchoolId] is written on all documents and read at app startup.
class SchoolConfig {
  SchoolConfig._();

  /// Set per deployment — override via `--dart-define=SCHOOL_ID=...` in Phase 3.
  static const String defaultSchoolId = String.fromEnvironment(
    'SCHOOL_ID',
    defaultValue: 'school_default',
  );

  static const int currentStudentSchemaVersion = 1;

  /// One class per grade (no A/B sections) for parent enrollment UI.
  static const bool gradeOnlyEnrollment = true;
}
