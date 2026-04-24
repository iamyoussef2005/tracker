class Category {
  const Category({this.id, required this.name, this.icon, this.colorHex});

  final int? id;
  final String name;
  final String? icon;
  final String? colorHex;

  Category copyWith({int? id, String? name, String? icon, String? colorHex}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'icon': icon, 'color_hex': colorHex};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      colorHex: map['color_hex'] as String?,
    );
  }
}
