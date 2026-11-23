import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mock/mock_simulator.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../curriculum/data/curriculum_repository.dart';
import '../../question_bank/data/question_repository.dart';
import '../domain/tutor_models.dart';
import 'mock_tutor_engine.dart';

/// AI tutor contract: a streamed answer (deltas, then final metadata). The real adapter will
/// consume server-sent events from `POST /ai/tutor/sessions/{id}/messages` (docs/api/AI_TUTOR_CONTRACT.md).
abstract interface class AiTutorRepository {
  Stream<TutorEvent> ask({
    required String query,
    required TutorContext context,
    required List<ChatMessage> history,
    int variant = 0,
  });
}

/// Simulated tutor: answers come from [MockTutorEngine] and are streamed word by word with
/// realistic latency. Offline and error toggles apply (AI always needs the server).
class MockAiTutorRepository implements AiTutorRepository {
  MockAiTutorRepository(this._sim, this._engine);

  final MockSimulator _sim;
  final MockTutorEngine _engine;

  @override
  Stream<TutorEvent> ask({required String query, required TutorContext context, required List<ChatMessage> history, int variant = 0}) async* {
    final reply = _engine.answer(query: query, context: context, history: history, variant: variant);
    final chunks = RegExp(r'\S+\s*').allMatches(reply.text).map((m) => m[0]!).toList();
    await for (final chunk in _sim.stream(chunks)) {
      yield TutorDelta(chunk);
    }
    yield TutorDone(reply);
  }
}

/// Backend adapter for the existing `POST /ai/tutor/ask` endpoint (non-streaming).
class ApiAiTutorRepository implements AiTutorRepository {
  ApiAiTutorRepository(this._api);

  final ApiClient _api;

  @override
  Stream<TutorEvent> ask({required String query, required TutorContext context, required List<ChatMessage> history, int variant = 0}) async* {
    final response = await _api.post<Map<String, dynamic>>(
      '/ai/tutor/ask',
      body: {
        'message': query,
        'subjectId': ?context.subjectId,
        'chapterId': ?context.chapterId,
        'mode': context.mode.name,
        'language': context.language.name,
      },
      parse: (data) => data! as Map<String, dynamic>,
    );
    final text = response.data['answer'] as String;
    yield TutorDelta(text);
    yield TutorDone(TutorReply(text: text, grounding: Grounding.general, confidence: 0.5));
  }
}

final mockTutorEngineProvider = Provider<MockTutorEngine>(
  (ref) => MockTutorEngine(
    curriculum: ref.watch(curriculumRepositoryProvider),
    questions: () => ref.read(questionRepositoryProvider).cached,
  ),
);

final aiTutorRepositoryProvider = Provider<AiTutorRepository>(
  (ref) => MockAiTutorRepository(ref.watch(mockSimulatorProvider), ref.watch(mockTutorEngineProvider)),
);

/// Kept so the real adapter can be switched in via configuration.
final apiTutorRepositoryProvider = Provider<AiTutorRepository>((ref) => ApiAiTutorRepository(ref.watch(apiClientProvider)));
