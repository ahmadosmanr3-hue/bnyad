import 'dart:convert';

class ShoppingItem {
  final String id;
  final String name;
  final bool checked;

  ShoppingItem({
    required this.id,
    required this.name,
    this.checked = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'checked': checked,
      };

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      checked: map['checked'] == true,
    );
  }

  ShoppingItem copyWith({String? id, String? name, bool? checked}) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      checked: checked ?? this.checked,
    );
  }

  String toJsonString() => jsonEncode(toMap());

  static ShoppingItem? tryParse(String raw) {
    try {
      return ShoppingItem.fromMap(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }
}
