class UserModel {
  final String id;
  final String phone;
  final String? email;
  final String fullName;
  final String? avatarUrl;
  final String role;

  const UserModel({
    required this.id,
    required this.phone,
    this.email,
    required this.fullName,
    this.avatarUrl,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      fullName: json['full_name'] as String? ?? 'User',
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'CUSTOMER',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'email': email,
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'role': role,
  };
}
