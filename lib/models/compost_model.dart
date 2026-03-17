class CompostModel {
  final String id;
  final String userEmail;
  final String wasteType;
  final double weight;
  final int points;
  final String createdAt;

  CompostModel({
    required this.id,
    required this.userEmail,
    required this.wasteType,
    required this.weight,
    required this.points,
    required this.createdAt,
  });

  factory CompostModel.fromJson(Map<String, dynamic> json) {
    return CompostModel(
      id: json['id'],
      userEmail: json['userEmail'],
      wasteType: json['wasteType'],
      weight: (json['weight'] as num).toDouble(),
      points: json['points'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userEmail': userEmail,
      'wasteType': wasteType,
      'weight': weight,
      'points': points,
      'createdAt': createdAt,
    };
  }
}