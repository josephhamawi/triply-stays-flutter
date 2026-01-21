import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai_service.dart';
import '../../../core/services/vertex_ai_service.dart';
import '../../../data/repositories/firebase_ai_repository.dart';
import '../../../data/repositories/noop_ai_repository.dart';
import '../../../domain/repositories/ai_repository.dart';
import '../../../main.dart' show firebaseInitialized;

/// Provider for the AI service (Vertex AI)
final aiServiceProvider = Provider<AIService>((ref) {
  return VertexAIService();
});

/// Provider for the AI repository
final aiRepositoryProvider = Provider<AIRepository>((ref) {
  if (!firebaseInitialized) {
    return NoOpAIRepository();
  }
  final aiService = ref.watch(aiServiceProvider);
  return FirebaseAIRepository(
    aiService: aiService,
    firestore: FirebaseFirestore.instance,
  );
});
