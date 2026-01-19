import 'dart:io';

import 'package:flutter/services.dart';

import 'ai_service.dart';

/// Apple Intelligence (on-device AI) implementation of AIService
/// This is a fallback for iOS devices when Vertex AI is unavailable
class AppleIntelligenceService implements AIService {
  static const MethodChannel _channel =
      MethodChannel('com.triplystays.app/apple_intelligence');

  bool? _isAvailableCache;

  /// Check if Apple Intelligence is available on this device
  Future<bool> checkAvailability() async {
    if (!Platform.isIOS) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      _isAvailableCache = result ?? false;
      return _isAvailableCache!;
    } catch (e) {
      _isAvailableCache = false;
      return false;
    }
  }

  @override
  Future<String> generateResponse({
    required String prompt,
    List<AIMessage>? history,
    String? systemPrompt,
  }) async {
    if (!Platform.isIOS) {
      throw UnsupportedError('Apple Intelligence is only available on iOS');
    }

    try {
      // Build context from history
      final context = history
          ?.map((m) => '${m.role}: ${m.content}')
          .join('\n');

      final result = await _channel.invokeMethod<String>('generateResponse', {
        'prompt': prompt,
        'context': context,
        'systemPrompt': systemPrompt ?? _defaultSystemPrompt,
      });

      return result ?? 'Unable to generate response';
    } on PlatformException catch (e) {
      throw Exception('Apple Intelligence error: ${e.message}');
    }
  }

  @override
  Future<Map<String, dynamic>> parseStructuredResponse({
    required String prompt,
    required String schema,
  }) async {
    if (!Platform.isIOS) {
      throw UnsupportedError('Apple Intelligence is only available on iOS');
    }

    try {
      final result = await _channel.invokeMethod<Map>('parseStructuredResponse', {
        'prompt': prompt,
        'schema': schema,
      });

      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      throw Exception('Apple Intelligence error: ${e.message}');
    }
  }

  @override
  bool get isAvailable => _isAvailableCache ?? false;

  @override
  String get serviceName => 'Apple Intelligence';

  static const String _defaultSystemPrompt = '''
You are Triply, a helpful AI assistant for a vacation rental app.
Help users find rentals and answer travel questions.
Keep responses brief and helpful.
''';
}
