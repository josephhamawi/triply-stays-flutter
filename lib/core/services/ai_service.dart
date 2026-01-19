/// Message for AI chat context
class AIMessage {
  final String content;
  final String role; // 'user' or 'model'

  const AIMessage({
    required this.content,
    required this.role,
  });
}

/// Abstract AI service interface
/// Allows swapping between different AI backends (Vertex AI, Apple Intelligence, etc.)
abstract class AIService {
  /// Generate a response from the AI model
  Future<String> generateResponse({
    required String prompt,
    List<AIMessage>? history,
    String? systemPrompt,
  });

  /// Parse a structured response from the AI model
  /// Returns a JSON-compatible map based on the provided schema
  Future<Map<String, dynamic>> parseStructuredResponse({
    required String prompt,
    required String schema,
  });

  /// Check if the AI service is available
  bool get isAvailable;

  /// Get the name of the AI service
  String get serviceName;
}
