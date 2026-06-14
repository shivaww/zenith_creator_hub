import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const String _projectsKey = 'projects';
  static const String _timeBlocksKey = 'timeBlocks';
  static const String _earningsKey = 'earnings';
  static const String _notesKey = 'notes';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Projects
  List<CreatorProject> getProjects() {
    final List<String> items = _prefs.getStringList(_projectsKey) ?? [];
    return items.map((e) => CreatorProject.fromJson(e)).toList();
  }

  Future<void> saveProjects(List<CreatorProject> projects) async {
    final List<String> items = projects.map((e) => e.toJson()).toList();
    await _prefs.setStringList(_projectsKey, items);
  }

  // TimeBlocks
  List<TimeBlock> getTimeBlocks() {
    final List<String> items = _prefs.getStringList(_timeBlocksKey) ?? [];
    return items.map((e) => TimeBlock.fromJson(e)).toList();
  }

  Future<void> saveTimeBlocks(List<TimeBlock> blocks) async {
    final List<String> items = blocks.map((e) => e.toJson()).toList();
    await _prefs.setStringList(_timeBlocksKey, items);
  }

  // Earnings
  List<Earning> getEarnings() {
    final List<String> items = _prefs.getStringList(_earningsKey) ?? [];
    return items.map((e) => Earning.fromJson(e)).toList();
  }

  Future<void> saveEarnings(List<Earning> earnings) async {
    final List<String> items = earnings.map((e) => e.toJson()).toList();
    await _prefs.setStringList(_earningsKey, items);
  }

  // Notes
  List<Note> getNotes() {
    final List<String> items = _prefs.getStringList(_notesKey) ?? [];
    return items.map((e) => Note.fromJson(e)).toList();
  }

  Future<void> saveNotes(List<Note> notes) async {
    final List<String> items = notes.map((e) => e.toJson()).toList();
    await _prefs.setStringList(_notesKey, items);
  }

  // Export App State
  String exportData() {
    final Map<String, dynamic> data = {
      _projectsKey: getProjects().map((e) => e.toMap()).toList(),
      _timeBlocksKey: getTimeBlocks().map((e) => e.toMap()).toList(),
      _earningsKey: getEarnings().map((e) => e.toMap()).toList(),
      _notesKey: getNotes().map((e) => e.toMap()).toList(),
    };
    return json.encode(data);
  }

  // Import App State
  Future<void> importData(String jsonString) async {
    try {
      final Map<String, dynamic> data = json.decode(jsonString);
      
      if (data.containsKey(_projectsKey)) {
        final List projects = data[_projectsKey];
        await saveProjects(projects.map((e) => CreatorProject.fromMap(e)).toList());
      }
      if (data.containsKey(_timeBlocksKey)) {
        final List blocks = data[_timeBlocksKey];
        await saveTimeBlocks(blocks.map((e) => TimeBlock.fromMap(e)).toList());
      }
      if (data.containsKey(_earningsKey)) {
        final List earnings = data[_earningsKey];
        await saveEarnings(earnings.map((e) => Earning.fromMap(e)).toList());
      }
      if (data.containsKey(_notesKey)) {
        final List notes = data[_notesKey];
        await saveNotes(notes.map((e) => Note.fromMap(e)).toList());
      }
    } catch (e) {
      throw Exception("Failed to import data: \$e");
    }
  }

  // Seed Placeholder Data
  Future<void> seedIfEmpty() async {
    if (getProjects().isEmpty && getTimeBlocks().isEmpty && getEarnings().isEmpty && getNotes().isEmpty) {
      await saveProjects([
        CreatorProject(
          title: 'Ultimate Flutter Guide',
          status: ProjectStatus.planning,
          deadline: DateTime.now().add(const Duration(days: 7)),
          paymentStatus: PaymentStatus.pending,
          paymentAmount: 15000,
        ),
        CreatorProject(
          title: 'Top AI Tools',
          status: ProjectStatus.research,
          deadline: DateTime.now().add(const Duration(days: 2)),
          paymentStatus: PaymentStatus.completed,
          paymentAmount: 5000,
        ),
      ]);

      await saveTimeBlocks([
        TimeBlock(title: 'Deep Work', startTime: DateTime.now().add(const Duration(minutes: 5)), endTime: DateTime.now().add(const Duration(hours: 1)), colorTag: '#FFB026FF', recurrence: Recurrence.none),
      ]);

      await saveEarnings([
        Earning(amount: 5000.0, source: 'Sponsorship', date: DateTime.now().subtract(const Duration(days: 1))),
        Earning(amount: 15000.0, source: 'Freelance App', date: DateTime.now().subtract(const Duration(days: 3))),
      ]);

      await saveNotes([
        Note(title: 'AI Script Ideas', body: 'Cover cursor, claude, and zenith.', tags: ['Ideas', 'AI']),
      ]);
    }
  }
}
