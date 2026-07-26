/// Future: teacher lesson planning, parent Q&A, performance summaries.
abstract class TeacherAssistantService {
  Future<String> suggestLessonPlan({
    required String schoolId,
    required String subjectId,
    required String gradeLevelId,
    required String topic,
  });

  Future<String> summarizeClassPerformance({
    required String schoolId,
    required String classRoomId,
  });
}

/// Future: homework help within curriculum bounds, todo coaching.
abstract class StudentLearningAssistantService {
  Future<String> explainConcept({
    required String schoolId,
    required String subjectId,
    required String question,
  });
}
