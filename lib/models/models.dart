import 'dart:convert';
import 'package:uuid/uuid.dart';

enum ProjectStatus { planning, research, scripting, production, completed }
enum PaymentStatus { pending, completed, none }

class CreatorProject {
  final String id;
  final String title;
  final ProjectStatus status;
  final DateTime deadline;
  final DateTime? completionDate;
  
  // File Paths stored locally
  final String? scriptFilePath;
  final List<String> researchFilePaths;
  
  // Payment Tracking
  final PaymentStatus paymentStatus;
  final double paymentAmount;

  CreatorProject({
    String? id,
    required this.title,
    required this.status,
    required this.deadline,
    this.completionDate,
    this.scriptFilePath,
    this.researchFilePaths = const [],
    this.paymentStatus = PaymentStatus.none,
    this.paymentAmount = 0.0,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'status': status.index,
      'deadline': deadline.millisecondsSinceEpoch,
      'completionDate': completionDate?.millisecondsSinceEpoch,
      'scriptFilePath': scriptFilePath,
      'researchFilePaths': researchFilePaths,
      'paymentStatus': paymentStatus.index,
      'paymentAmount': paymentAmount,
    };
  }

  factory CreatorProject.fromMap(Map<String, dynamic> map) {
    return CreatorProject(
      id: map['id'],
      title: map['title'],
      status: ProjectStatus.values[map['status'] ?? 0],
      deadline: DateTime.fromMillisecondsSinceEpoch(map['deadline']),
      completionDate: map['completionDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['completionDate']) : null,
      scriptFilePath: map['scriptFilePath'],
      researchFilePaths: List<String>.from(map['researchFilePaths'] ?? []),
      paymentStatus: PaymentStatus.values[map['paymentStatus'] ?? 2],
      paymentAmount: map['paymentAmount']?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());
  factory CreatorProject.fromJson(String source) => CreatorProject.fromMap(json.decode(source));

  CreatorProject copyWith({
    String? title,
    ProjectStatus? status,
    DateTime? deadline,
    DateTime? completionDate,
    String? scriptFilePath,
    List<String>? researchFilePaths,
    PaymentStatus? paymentStatus,
    double? paymentAmount,
  }) {
    return CreatorProject(
      id: id,
      title: title ?? this.title,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      completionDate: completionDate ?? this.completionDate,
      scriptFilePath: scriptFilePath ?? this.scriptFilePath,
      researchFilePaths: researchFilePaths ?? this.researchFilePaths,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentAmount: paymentAmount ?? this.paymentAmount,
    );
  }
}

enum Recurrence { none, daily, weekdays }

class TimeBlock {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String colorTag;
  final Recurrence recurrence;
  final bool remindersEnabled;

  TimeBlock({
    String? id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.colorTag,
    required this.recurrence,
    this.remindersEnabled = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'colorTag': colorTag,
      'recurrence': recurrence.index,
      'remindersEnabled': remindersEnabled,
    };
  }

  factory TimeBlock.fromMap(Map<String, dynamic> map) {
    return TimeBlock(
      id: map['id'],
      title: map['title'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['endTime']),
      colorTag: map['colorTag'],
      recurrence: Recurrence.values[map['recurrence'] ?? 0],
      remindersEnabled: map['remindersEnabled'] ?? true,
    );
  }
  
  String toJson() => json.encode(toMap());
  factory TimeBlock.fromJson(String source) => TimeBlock.fromMap(json.decode(source));

  TimeBlock copyWith({bool? remindersEnabled}) {
    return TimeBlock(
      id: id,
      title: title,
      startTime: startTime,
      endTime: endTime,
      colorTag: colorTag,
      recurrence: recurrence,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    );
  }
}

class Earning {
  final String id;
  final double amount;
  final String source;
  final DateTime date;

  Earning({
    String? id,
    required this.amount,
    required this.source,
    required this.date,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'source': source,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory Earning.fromMap(Map<String, dynamic> map) {
    return Earning(
      id: map['id'],
      amount: map['amount']?.toDouble() ?? 0.0,
      source: map['source'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    );
  }
  
  String toJson() => json.encode(toMap());
  factory Earning.fromJson(String source) => Earning.fromMap(json.decode(source));
}

class Note {
  final String id;
  final String title;
  final String body;
  final String? url;
  final List<String> tags;
  final DateTime updatedAt;

  Note({
    String? id,
    required this.title,
    required this.body,
    this.url,
    this.tags = const [],
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'url': url,
      'tags': tags,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      url: map['url'],
      tags: List<String>.from(map['tags'] ?? []),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  String toJson() => json.encode(toMap());
  factory Note.fromJson(String source) => Note.fromMap(json.decode(source));
}
