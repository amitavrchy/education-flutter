import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/features/auth/domain/app_user.dart';

void main() {
  test('parses the backend GET /users/me payload', () {
    final user = AppUser.fromMeResponse({
      'id': 'u1',
      'email': 'student@shikkha.ai',
      'phone': null,
      'status': 'ACTIVE',
      'roles': [
        {
          'institutionId': null,
          'role': {'key': 'STUDENT', 'name': 'Student'},
        },
      ],
      'studentProfile': {'id': 'sp1', 'fullName': 'রাফি আহমেদ', 'level': 'HSC'},
      'teacherProfile': null,
      'parentProfile': null,
    });

    expect(user.role, UserRole.student);
    expect(user.name, 'রাফি আহমেদ');
    expect(user.email, 'student@shikkha.ai');
  });

  test('round-trips through JSON for secure storage', () {
    const user = AppUser(id: 'u2', name: 'নাসরিন', role: UserRole.teacher, phone: '+8801712345678');
    final restored = AppUser.fromJson(user.toJson());
    expect(restored.role, UserRole.teacher);
    expect(restored.phone, '+8801712345678');
  });

  test('knows which roles the app serves', () {
    expect(UserRole.student.supportedOnMobile, isTrue);
    expect(UserRole.superAdmin.supportedOnMobile, isFalse);
    expect(() => UserRole.fromKey('UNKNOWN'), throwsFormatException);
  });
}
