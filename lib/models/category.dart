class Category {
  final String id;
  final String? userId;
  final String? familyGroupId;
  final String name;
  final String type; // 'income' or 'expense'
  final String? icon;
  final String? color;
  final String? parentId;
  final int sortOrder;
  final bool isSystem;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    this.userId,
    this.familyGroupId,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.parentId,
    this.sortOrder = 0,
    this.isSystem = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      userId: json['user_id'],
      familyGroupId: json['family_group_id'],
      name: json['name'],
      type: json['type'],
      icon: json['icon'],
      color: json['color'],
      parentId: json['parent_id'],
      sortOrder: json['sort_order'] ?? 0,
      isSystem: json['is_system'] ?? false,
      createdAt: json['created_at'] is String 
          ? DateTime.parse(json['created_at']) 
          : json['created_at'] as DateTime,
      updatedAt: json['updated_at'] is String 
          ? DateTime.parse(json['updated_at']) 
          : json['updated_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'family_group_id': familyGroupId,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'parent_id': parentId,
      'sort_order': sortOrder,
      'is_system': isSystem,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Category copyWith({
    String? id,
    String? userId,
    String? familyGroupId,
    String? name,
    String? type,
    String? icon,
    String? color,
    String? parentId,
    int? sortOrder,
    bool? isSystem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      familyGroupId: familyGroupId ?? this.familyGroupId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}