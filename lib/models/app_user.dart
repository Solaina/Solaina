class AppUser {
  final String id;
  final String displayName;
  final String email;
  final String? householdId;

  AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.householdId,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      householdId: data['householdId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'householdId': householdId,
    };
  }
}
