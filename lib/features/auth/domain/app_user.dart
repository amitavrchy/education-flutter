/// Roles, matching the backend's RoleKey values.
enum UserRole {
  student(key: 'STUDENT', pathSegment: 'student', labelBn: 'শিক্ষার্থী'),
  teacher(key: 'TEACHER', pathSegment: 'teacher', labelBn: 'শিক্ষক'),
  parent(key: 'PARENT', pathSegment: 'parent', labelBn: 'অভিভাবক'),
  superAdmin(key: 'SUPER_ADMIN', pathSegment: 'admin', labelBn: 'অ্যাডমিন');

  const UserRole({required this.key, required this.pathSegment, required this.labelBn});

  final String key;
  final String pathSegment;
  final String labelBn;

  /// Admins use the web dashboard; the app serves the other three.
  bool get supportedOnMobile =>
      this == UserRole.student || this == UserRole.teacher || this == UserRole.parent;

  /// Accepts the app's own keys (`STUDENT`) and the backend's role names (`student`,
  /// `content_reviewer`, …). Reviewers use the teacher portal; other staff roles are web-only.
  static UserRole fromKey(String key) {
    for (final role in UserRole.values) {
      if (role.key == key || role.pathSegment == key) return role;
    }
    return switch (key.toLowerCase()) {
      'student' => UserRole.student,
      'teacher' || 'content_reviewer' => UserRole.teacher,
      'parent' || 'guardian' => UserRole.parent,
      'super_admin' || 'platform_admin' || 'content_manager' || 'school_admin' || 'college_admin' || 'support' => UserRole.superAdmin,
      _ => throw FormatException('Unknown role key: $key'),
    };
  }
}

class AppUser {
  const AppUser({required this.id, required this.name, required this.role, this.email, this.phone});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    name: json['name'] as String,
    role: UserRole.fromKey(json['role'] as String),
    email: json['email'] as String?,
    phone: json['phone'] as String?,
  );

  /// Parses the backend's `GET /users/me` payload.
  factory AppUser.fromMeResponse(Map<String, dynamic> json) {
    final roles = (json['roles'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((entry) => (entry['role'] as Map<String, dynamic>)['key'] as String)
        .toList();
    if (roles.isEmpty) throw const FormatException('User has no role');

    String? profileName(String key) => (json[key] as Map<String, dynamic>?)?['fullName'] as String?;
    final email = json['email'] as String?;
    final phone = json['phone'] as String?;

    return AppUser(
      id: json['id'] as String,
      name:
          profileName('studentProfile') ??
          profileName('teacherProfile') ??
          profileName('parentProfile') ??
          email ??
          phone ??
          'ব্যবহারকারী',
      role: UserRole.fromKey(roles.first),
      email: email,
      phone: phone,
    );
  }

  final String id;
  final String name;
  final UserRole role;
  final String? email;
  final String? phone;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role.key,
    'email': email,
    'phone': phone,
  };
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.user, this.refreshToken});

  final String accessToken;
  final String? refreshToken;
  final AppUser user;
}
