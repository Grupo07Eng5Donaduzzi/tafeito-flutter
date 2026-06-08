class UpdateUserRequest {
  const UpdateUserRequest({
    this.name,
    this.email,
    this.password,
    this.identification,
    this.pixKey,
    this.hourlyRate,
  });

  factory UpdateUserRequest.fromJson(Map<String, dynamic> json) {
    return UpdateUserRequest(
      name: json['name'] as String?,
      email: json['email'] as String?,
      password: json['password'] as String?,
      identification: json['identification'] as String?,
      pixKey: json['pixKey'] as String?,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
    );
  }

  final String? name;
  final String? email;
  final String? password;
  final String? identification;
  final String? pixKey;
  final double? hourlyRate;

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (password != null) 'password': password,
      if (identification != null) 'identification': identification,
      if (pixKey != null) 'pixKey': pixKey,
      if (hourlyRate != null) 'hourlyRate': hourlyRate,
    };
  }
}
