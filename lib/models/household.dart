class Household {
  final String id;
  final String name;
  final String inviteCode;
  final List<String> memberIds;

  Household({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.memberIds,
  });

  factory Household.fromMap(String id, Map<String, dynamic> data) {
    return Household(
      id: id,
      name: data['name'] as String? ?? '',
      inviteCode: data['inviteCode'] as String? ?? '',
      memberIds: List<String>.from(data['memberIds'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'inviteCode': inviteCode, 'memberIds': memberIds};
  }
}

class HouseholdMember {
  final String userId;
  final String displayName;

  HouseholdMember({required this.userId, required this.displayName});

  factory HouseholdMember.fromMap(String userId, Map<String, dynamic> data) {
    return HouseholdMember(
      userId: userId,
      displayName: data['displayName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'displayName': displayName};
  }
}

extension HouseholdMemberLookup on List<HouseholdMember> {
  String nameFor(String userId) {
    return firstWhere(
      (member) => member.userId == userId,
      orElse: () => HouseholdMember(userId: userId, displayName: 'Unknown'),
    ).displayName;
  }
}
