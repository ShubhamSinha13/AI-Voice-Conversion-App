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
    // Parse id - handle both int and string from backend
    int parsedId;
    final idValue = json['id'];
    if (idValue is String) {
      parsedId = int.parse(idValue);
    } else {
      parsedId = (idValue as int?) ?? 0;
    }

    return Voice(
      id: parsedId,
      name: json['name'] as String,
      type: json['type'] as String,
      category: json['category'] as String?,
      predefinedName: json['predefined_name'] as String?,
      userDefinedName: json['user_defined_name'] as String?,
      sampleCount: json['sample_count'] as int? ?? 0,
      accuracyPercentage:
          (json['accuracy_percentage'] as num?)?.toDouble() ?? 88.0,
      isPredefined: json['is_predefined'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
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

  Voice copyWith({
    int? id,
    String? name,
    String? type,
    String? category,
    String? predefinedName,
    String? userDefinedName,
    int? sampleCount,
    double? accuracyPercentage,
    bool? isPredefined,
    DateTime? createdAt,
  }) {
    return Voice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      predefinedName: predefinedName ?? this.predefinedName,
      userDefinedName: userDefinedName ?? this.userDefinedName,
      sampleCount: sampleCount ?? this.sampleCount,
      accuracyPercentage: accuracyPercentage ?? this.accuracyPercentage,
      isPredefined: isPredefined ?? this.isPredefined,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
