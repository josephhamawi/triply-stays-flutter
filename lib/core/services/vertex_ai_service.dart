import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';

import 'ai_service.dart';

/// Vertex AI (Gemini) implementation of AIService
class VertexAIService implements AIService {
  GenerativeModel? _chatModel;
  GenerativeModel? _structuredModel;
  bool _initialized = false;

  static const String _systemPrompt = '''
You are Triply, a friendly and helpful AI assistant for Triply Stays, a vacation rental marketplace app.

Your role is to:
- Help users find the perfect vacation rental by understanding their needs
- Answer questions about properties, amenities, and locations
- Provide travel advice and recommendations
- Be conversational, warm, and professional

Guidelines:
- Keep responses concise but helpful (2-4 sentences unless more detail is needed)
- When recommending properties, focus on what makes them special
- If you don't know something specific about a property, say so honestly
- Use a friendly, approachable tone
- Format lists and important info clearly using markdown when helpful
''';

  /// Initialize the Vertex AI models
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize chat model for general responses
      _chatModel = FirebaseAI.vertexAI().generativeModel(
        model: 'gemini-1.5-flash',
        systemInstruction: Content.system(_systemPrompt),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 1024,
        ),
      );

      // Initialize structured model for JSON responses
      _structuredModel = FirebaseAI.vertexAI().generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          temperature: 0.2,
          maxOutputTokens: 512,
          responseMimeType: 'application/json',
        ),
      );

      _initialized = true;
    } catch (e) {
      _initialized = false;
      rethrow;
    }
  }

  @override
  Future<String> generateResponse({
    required String prompt,
    List<AIMessage>? history,
    String? systemPrompt,
  }) async {
    await initialize();

    if (_chatModel == null) {
      throw Exception('Vertex AI not initialized');
    }

    try {
      // Build chat history if provided
      final chatHistory = <Content>[];
      if (history != null) {
        for (final message in history) {
          chatHistory.add(Content(
            message.role == 'user' ? 'user' : 'model',
            [TextPart(message.content)],
          ));
        }
      }

      // Create chat session with history
      final chat = _chatModel!.startChat(history: chatHistory);

      // Send the prompt and get response
      final response = await chat.sendMessage(Content.text(prompt));

      return response.text ?? 'I apologize, but I could not generate a response.';
    } catch (e) {
      throw Exception('Failed to generate AI response: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> parseStructuredResponse({
    required String prompt,
    required String schema,
  }) async {
    await initialize();

    if (_structuredModel == null) {
      throw Exception('Vertex AI not initialized');
    }

    try {
      final fullPrompt = '''
$prompt

Respond with valid JSON matching this schema:
$schema

Only respond with the JSON object, no other text.
''';

      final response = await _structuredModel!.generateContent([
        Content.text(fullPrompt),
      ]);

      final text = response.text ?? '{}';

      // Parse the JSON response
      try {
        return jsonDecode(text) as Map<String, dynamic>;
      } catch (e) {
        // Try to extract JSON from the response if it's wrapped in markdown
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch != null) {
          return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        }
        return {};
      }
    } catch (e) {
      throw Exception('Failed to parse structured response: $e');
    }
  }

  @override
  bool get isAvailable => _initialized || Firebase.apps.isNotEmpty;

  @override
  String get serviceName => 'Vertex AI (Gemini)';
}
