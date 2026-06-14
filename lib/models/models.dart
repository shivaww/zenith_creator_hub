import 'dart:convert';
import 'package:uuid/uuid.dart';

enum ScriptStatus { idea, draft, finalEdit, published }

class Script {
  final String id;
  final String title;
  final ScriptStatus status;
  final int wordCount;
  final DateTime deadline;

  Script({
    String? id,
    required this.title,
    required this.status,
    required this.wordCount,
    required this.deadline,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'status': status.index,
      'wordCount': wordCount,
      'deadline': deadline.millisecondsSinceEpoch,
    };
  }

  factory Script.fromMap(Map<String, dynamic> map) {
    return Script(
      id: map['id'],
      title: map['title'],
      status: ScriptStatus.values[map['status'] ?? 0],
      wordCount: map['wordCount']?.toInt() ?? 0,
      deadline: DateTime.fromMillisecondsSinceEpoch(map['deadline']),
    );
  }

  String toJson() => json.encode(toMap());
  factory Script.fromJson(String source) => Script.fromMap(json.decode(source));

  Script copyWith({
    String? title,
    ScriptStatus? status,
    int? wordCount,
    DateTime? deadline,
  }) {
    return Script(
      id: id,
      title: title ?? this.title,
      status: status ?? this.status,
      wordCount: wordCount ?? this.wordCount,
      deadline: deadline ?? this.deadline,
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
