class UserModel {
  final String id;
  final String username;
  final List<String> roles;
  final List<String> permissions;

  UserModel({
    required this.id,
    required this.username,
    required this.roles,
    required this.permissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> roleList = [];
    if (json['roles'] != null) {
      roleList = List<String>.from(json['roles']);
    } else if (json['role'] != null) {
      roleList = [json['role'].toString()];
    }

    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      roles: roleList,
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'roles': roles,
      'permissions': permissions,
    };
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }
}
