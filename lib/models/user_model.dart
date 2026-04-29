class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final int? branchId;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    this.branchId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      phone: json['phone'] ?? '',
      branchId: json['branch_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'branch_id': branchId,
    };
  }
}