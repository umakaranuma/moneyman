class Todo {
  String id;
  String title;
  String? description;
  DateTime scheduledDate; // The date when this todo should be displayed
  bool isDone;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? originalScheduledDate; // Track original date if rescheduled

  Todo({
    required this.id,
    required this.title,
    this.description,
    required this.scheduledDate,
    this.isDone = false,
    required this.createdAt,
    required this.updatedAt,
    this.originalScheduledDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scheduledDate': scheduledDate.toIso8601String(),
      'isDone': isDone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'originalScheduledDate': originalScheduledDate?.toIso8601String(),
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      scheduledDate: DateTime.parse(json['scheduledDate']),
      isDone: json['isDone'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      originalScheduledDate: json['originalScheduledDate'] != null
          ? DateTime.parse(json['originalScheduledDate'])
          : null,
    );
  }

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? scheduledDate,
    bool? isDone,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? originalScheduledDate,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      originalScheduledDate: originalScheduledDate ?? this.originalScheduledDate,
    );
  }
}



