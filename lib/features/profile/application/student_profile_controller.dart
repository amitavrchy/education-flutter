import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../domain/student_profile.dart';

class StudentProfileController extends Notifier<StudentProfile> {
  static const collection = 'profile';
  static const _id = 'student';

  @override
  StudentProfile build() {
    final json = ref.watch(localStoreProvider).get(collection, _id);
    return json == null ? const StudentProfile() : StudentProfile.fromJson(json);
  }

  Future<void> update(StudentProfile Function(StudentProfile current) change) async {
    state = change(state);
    await ref.read(localStoreProvider).put(collection, _id, state.toJson());
  }
}

final studentProfileProvider = NotifierProvider<StudentProfileController, StudentProfile>(
  StudentProfileController.new,
);
