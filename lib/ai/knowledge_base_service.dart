/// Future: RAG over school policies, curriculum PDFs, handbooks.
///
/// Firestore metadata collections reserved: `ai_documents`, `ai_chunks`.
abstract class KnowledgeBaseService {
  Future<void> ingestDocument({
    required String schoolId,
    required String title,
    required String sourceUrl,
    required List<int> fileBytes,
  });

  Future<List<KnowledgeSearchResult>> search({
    required String schoolId,
    required String query,
    int limit = 5,
  });
}

class KnowledgeSearchResult {
  final String documentTitle;
  final String excerpt;
  final double relevanceScore;

  const KnowledgeSearchResult({
    required this.documentTitle,
    required this.excerpt,
    required this.relevanceScore,
  });
}
