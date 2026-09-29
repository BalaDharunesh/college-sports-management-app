class UserModel {
  final int id;
  final String email;
  final String role; // 'STAFF', 'CAPTAIN', 'PLAYER'
  final String name;
  final String? registerNumber;
  final String? department;
  final String? academicYear;
  final String? phone;
  final int? teamId;
  final String? teamName;
  final String? sportName;
  final int? playerId;
  final String? position;
  final int? jerseyNumber;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.registerNumber,
    this.department,
    this.academicYear,
    this.phone,
    this.teamId,
    this.teamName,
    this.sportName,
    this.playerId,
    this.position,
    this.jerseyNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      email: json['email'] ?? '',
      role: json['role'] ?? 'PLAYER',
      name: json['name'] ?? '',
      registerNumber: json['registerNumber'] ?? json['register_number'],
      department: json['department'],
      academicYear: json['academicYear'] ?? json['academic_year'],
      phone: json['phone'],
      teamId: json['teamId'] != null ? (json['teamId'] is int ? json['teamId'] : int.tryParse(json['teamId'].toString())) : null,
      teamName: json['teamName'],
      sportName: json['sportName'],
      playerId: json['playerId'] != null ? (json['playerId'] is int ? json['playerId'] : int.tryParse(json['playerId'].toString())) : null,
      position: json['position'],
      jerseyNumber: json['jerseyNumber'] != null ? (json['jerseyNumber'] is int ? json['jerseyNumber'] : int.tryParse(json['jerseyNumber'].toString())) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'name': name,
      'registerNumber': registerNumber,
      'department': department,
      'academicYear': academicYear,
      'phone': phone,
      'teamId': teamId,
      'teamName': teamName,
      'sportName': sportName,
      'playerId': playerId,
      'position': position,
      'jerseyNumber': jerseyNumber,
    };
  }
}
