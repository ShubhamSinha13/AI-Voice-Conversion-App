/// Voice model for application
class Voice {
  final int id;
  final String name;
  final String type; // 'predefined' or 'custom'
  final String? category; // 'female', 'men', 'special'
  final String? predefinedName;
  final String? userDefinedName;
  final int sampleCount;
  final double accuracyPercentage;
  final bool isPredefined;
  final DateTime createdAt;

  Voice({
    required this.id,
    required this.name,
    required this.type,
    this.category,
    this.predefinedName,
    this.userDefinedName,
    required this.sampleCount,
    required this.accuracyPercentage,
    required this.isPredefined,
    required this.createdAt,
  });

  factory Voice.fromJson(Map<String, dynamic> json) {
    return Voice(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      category: json['category'] as String?,
      predefinedName: json['predefined_name'] as String?,
      userDefinedName: json['user_defined_name'] as String?,
      sampleCount: json['sample_count'] as int? ?? 0,
      accuracyPercentage:
          (json['accuracy_percentage'] as num?)?.toDouble() ?? 0.0,
      isPredefined: json['is_predefined'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'category': category,
      'predefined_name': predefinedName,
      'user_defined_name': userDefinedName,
      'sample_count': sampleCount,
      'accuracy_percentage': accuracyPercentage,
      'is_predefined': isPredefined,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
