/// Skill model representing a technical skill
class Skill {
  final String? id;
  final String name;
  final String category;
  final String iconName;
  final String color;
  final int usageCount;
  final DateTime? createdAt;

  Skill({
    this.id,
    required this.name,
    this.category = 'General',
    this.iconName = 'code',
    this.color = '#3D3D8F',
    this.usageCount = 0,
    this.createdAt,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'] as String?,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'General',
      iconName: json['icon_name'] as String? ?? 'code',
      color: json['color'] as String? ?? '#3D3D8F',
      usageCount: json['usage_count'] as int? ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'icon_name': iconName,
      'color': color,
      'usage_count': usageCount,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Skill && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Skill(name: $name, category: $category)';
}

/// User's skill with proficiency details
class UserSkill {
  final String? id;
  final String userId;
  final String skillId;
  final int proficiencyLevel; // 1-5
  final double yearsExperience;
  final bool isPrimary;
  final DateTime? createdAt;
  
  // Skill details (populated from join)
  final Skill? skill;

  UserSkill({
    this.id,
    required this.userId,
    required this.skillId,
    this.proficiencyLevel = 3,
    this.yearsExperience = 0,
    this.isPrimary = false,
    this.createdAt,
    this.skill,
  });

  factory UserSkill.fromJson(Map<String, dynamic> json) {
    return UserSkill(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      skillId: json['skill_id'] as String,
      proficiencyLevel: json['proficiency_level'] as int? ?? 3,
      yearsExperience: (json['years_experience'] as num?)?.toDouble() ?? 0,
      isPrimary: json['is_primary'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      skill: json['skill'] != null ? Skill.fromJson(json['skill']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'skill_id': skillId,
      'proficiency_level': proficiencyLevel,
      'years_experience': yearsExperience,
      'is_primary': isPrimary,
    };
  }

  UserSkill copyWith({
    String? id,
    String? userId,
    String? skillId,
    int? proficiencyLevel,
    double? yearsExperience,
    bool? isPrimary,
    DateTime? createdAt,
    Skill? skill,
  }) {
    return UserSkill(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      skillId: skillId ?? this.skillId,
      proficiencyLevel: proficiencyLevel ?? this.proficiencyLevel,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      skill: skill ?? this.skill,
    );
  }

  /// Get proficiency label
  String get proficiencyLabel {
    switch (proficiencyLevel) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Elementary';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Expert';
      default:
        return 'Intermediate';
    }
  }

  /// Get proficiency percentage (for progress bars)
  double get proficiencyPercentage => proficiencyLevel / 5.0;

  @override
  String toString() => 'UserSkill(skill: ${skill?.name}, level: $proficiencyLabel)';
}

/// Skill category for grouping skills
class SkillCategory {
  final String name;
  final List<Skill> skills;
  final String? iconName;

  SkillCategory({
    required this.name,
    required this.skills,
    this.iconName,
  });

  /// Group skills by category
  static List<SkillCategory> groupSkills(List<Skill> skills) {
    final Map<String, List<Skill>> grouped = {};
    
    for (final skill in skills) {
      grouped.putIfAbsent(skill.category, () => []).add(skill);
    }
    
    return grouped.entries
        .map((e) => SkillCategory(name: e.key, skills: e.value))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}
