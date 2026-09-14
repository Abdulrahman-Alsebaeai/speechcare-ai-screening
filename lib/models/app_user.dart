class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'passwordHash': passwordHash,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AppUser.fromMap(Map<String, Object?> map) => AppUser(
    id: map['id'] as int?,
    name: map['name'] as String,
    email: map['email'] as String,
    passwordHash: map['passwordHash'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
  );

  AppUser copyWith({int? id}) => AppUser(
    id: id ?? this.id,
    name: name,
    email: email,
    passwordHash: passwordHash,
    createdAt: createdAt,
  );
}
