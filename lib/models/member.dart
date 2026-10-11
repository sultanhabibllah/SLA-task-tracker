enum MemberRole { admin, member }

enum MemberPresence { online, away, offline }

class Member {
  final String id;
  final String name;
  final String jobTitle;
  final String email;
  final String team;
  final MemberRole role;
  final MemberPresence presence;
  final DateTime joinedAt;

  const Member({
    required this.id,
    required this.name,
    required this.jobTitle,
    required this.email,
    required this.team,
    required this.joinedAt,
    this.role = MemberRole.member,
    this.presence = MemberPresence.offline,
  });

  // "Alex Carter" -> "AC", "Priya" -> "P"
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Member copyWith({
    String? name,
    String? jobTitle,
    String? email,
    String? team,
    MemberRole? role,
    MemberPresence? presence,
  }) {
    return Member(
      id: id,
      name: name ?? this.name,
      jobTitle: jobTitle ?? this.jobTitle,
      email: email ?? this.email,
      team: team ?? this.team,
      role: role ?? this.role,
      presence: presence ?? this.presence,
      joinedAt: joinedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'jobTitle': jobTitle,
      'email': email,
      'team': team,
      'role': role.name,
      'presence': presence.name,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  // Any field added later must be read with a default here, otherwise members
  // saved by an older version of the app can no longer be loaded.
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      name: json['name'] as String,
      jobTitle: json['jobTitle'] as String,
      email: json['email'] as String,
      team: json['team'] as String,
      role: MemberRole.values.byName(json['role'] as String),
      presence: MemberPresence.values.byName(json['presence'] as String),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }
}
