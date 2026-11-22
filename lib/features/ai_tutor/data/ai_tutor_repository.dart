import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';

class TutorAnswer {
  const TutorAnswer({required this.answer, required this.model});

  factory TutorAnswer.fromJson(Map<String, dynamic> json) =>
      TutorAnswer(answer: json['answer'] as String, model: json['model'] as String);

  final String answer;
  final String model;
}

/// Calls the backend's `POST /ai/tutor/ask`. The backend answers 503 until an AI provider
/// is configured (AI_PROVIDER=mock gives offline answers for development).
class AiTutorRepository {
  AiTutorRepository(this._api);

  final ApiClient _api;

  Future<TutorAnswer> ask(String message, {String? subjectId, String? chapterId}) async {
    final response = await _api.post<TutorAnswer>(
      '/ai/tutor/ask',
      body: {
        'message': message,
        if (subjectId != null) 'subjectId': subjectId,
        if (chapterId != null) 'chapterId': chapterId,
      },
      parse: (data) => TutorAnswer.fromJson(data! as Map<String, dynamic>),
    );
    return response.data;
  }
}

final aiTutorRepositoryProvider = Provider<AiTutorRepository>(
  (ref) => AiTutorRepository(ref.watch(apiClientProvider)),
);
