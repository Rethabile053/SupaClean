class UserModel {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;

  UserModel({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        fullName: json['fullName'] ?? '',
        email: json['email'] ?? '',
        phoneNumber: json['phoneNumber'] ?? '',
        password: json['password'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
      };

  @override
  String toString() => 'UserModel(name: $fullName, email: $email, phone: $phoneNumber)';
}
