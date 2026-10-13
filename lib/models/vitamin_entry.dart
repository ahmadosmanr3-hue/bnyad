class VitaminEntry {
  final String id;
  final String name;
  final String dosage;
  bool taken;
  bool reminderEnabled;
  int? reminderHour;
  int? reminderMinute;

  VitaminEntry({
    required this.id,
    required this.name,
    required this.dosage,
    this.taken = false,
    this.reminderEnabled = false,
    this.reminderHour,
    this.reminderMinute,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'taken': taken,
    'reminderEnabled': reminderEnabled,
    if (reminderHour != null) 'reminderHour': reminderHour,
    if (reminderMinute != null) 'reminderMinute': reminderMinute,
  };

  factory VitaminEntry.fromMap(Map<String, dynamic> map) => VitaminEntry(
    id: map['id'] as String,
    name: map['name'] as String,
    dosage: map['dosage'] as String,
    taken: map['taken'] as bool? ?? false,
    reminderEnabled: map['reminderEnabled'] as bool? ?? false,
    reminderHour: (map['reminderHour'] as num?)?.toInt(),
    reminderMinute: (map['reminderMinute'] as num?)?.toInt(),
  );

  VitaminEntry copyWith({
    String? name,
    String? dosage,
    bool? taken,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) => VitaminEntry(
    id: id,
    name: name ?? this.name,
    dosage: dosage ?? this.dosage,
    taken: taken ?? this.taken,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
  );
}
