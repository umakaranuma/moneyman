/// Type of reminder: general (date+time+description), loan due date, or package/subscription expiry.
enum ReminderType {
  /// Single reminder at a date and time with a description.
  general,
  loan,
  package,
}

/// Recurrence for general reminders.
enum ReminderRecurrence {
  daily,
  monthly,
  annually,
}

/// A reminder for either a loan due date or a package/subscription expiry.
class Reminder {
  final String id;
  final ReminderType type;
  final String title;
  final String? label;
  final DateTime createdAt;

  // Loan: due date and time, amount, optional note
  final DateTime? dueDate;
  final int? dueTimeHour; // 0-23, null = use default 9:00
  final int? dueTimeMinute; // 0-59
  final double? loanAmount;
  final String? note;
  final ReminderRecurrence recurrence;

  // Package: activation date, expiry date
  final DateTime? activationDate;
  final DateTime? expiryDate;

  // Notification IDs stored so we can cancel when reminder is deleted
  final int? notificationIdDayBefore;
  final int? notificationIdOnDay;

  Reminder({
    required this.id,
    required this.type,
    required this.title,
    this.label,
    required this.createdAt,
    this.dueDate,
    this.dueTimeHour,
    this.dueTimeMinute,
    this.loanAmount,
    this.note,
    this.recurrence = ReminderRecurrence.daily,
    this.activationDate,
    this.expiryDate,
    this.notificationIdDayBefore,
    this.notificationIdOnDay,
  });

  /// Date used for sorting and scheduling (due date, expiry date, or reminder date).
  DateTime? get effectiveDate {
    if (type == ReminderType.general || type == ReminderType.loan) return dueDate;
    if (type == ReminderType.package) return expiryDate;
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'label': label,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'dueTimeHour': dueTimeHour,
      'dueTimeMinute': dueTimeMinute,
      'loanAmount': loanAmount,
      'note': note,
      'recurrence': recurrence.name,
      'activationDate': activationDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'notificationIdDayBefore': notificationIdDayBefore,
      'notificationIdOnDay': notificationIdOnDay,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      type: ReminderType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReminderType.loan,
      ),
      title: json['title'] as String,
      label: json['label'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      dueTimeHour: json['dueTimeHour'] as int?,
      dueTimeMinute: json['dueTimeMinute'] as int?,
      loanAmount: (json['loanAmount'] as num?)?.toDouble(),
      note: json['note'] as String?,
      recurrence: ReminderRecurrence.values.firstWhere(
        (e) => e.name == json['recurrence'],
        orElse: () => ReminderRecurrence.daily,
      ),
      activationDate: json['activationDate'] != null
          ? DateTime.parse(json['activationDate'] as String)
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      notificationIdDayBefore: json['notificationIdDayBefore'] as int?,
      notificationIdOnDay: json['notificationIdOnDay'] as int?,
    );
  }

  Reminder copyWith({
    String? id,
    ReminderType? type,
    String? title,
    String? label,
    DateTime? createdAt,
    DateTime? dueDate,
    int? dueTimeHour,
    int? dueTimeMinute,
    double? loanAmount,
    String? note,
    ReminderRecurrence? recurrence,
    DateTime? activationDate,
    DateTime? expiryDate,
    int? notificationIdDayBefore,
    int? notificationIdOnDay,
  }) {
    return Reminder(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      dueTimeHour: dueTimeHour ?? this.dueTimeHour,
      dueTimeMinute: dueTimeMinute ?? this.dueTimeMinute,
      loanAmount: loanAmount ?? this.loanAmount,
      note: note ?? this.note,
      recurrence: recurrence ?? this.recurrence,
      activationDate: activationDate ?? this.activationDate,
      expiryDate: expiryDate ?? this.expiryDate,
      notificationIdDayBefore:
          notificationIdDayBefore ?? this.notificationIdDayBefore,
      notificationIdOnDay: notificationIdOnDay ?? this.notificationIdOnDay,
    );
  }
}
