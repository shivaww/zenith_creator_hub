import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const String _scriptsKey = 'scripts';
  static const String _timeBlocksKey = 'timeBlocks';
  static const String _earningsKey = 'earnings';
  static const String _notesKey = 'notes';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Scripts
  List<Script> getScripts() {
    final List<String> items = _prefs.getStringList(_scriptsKey) ?? [];
    return items.map((e) => Script.fromJson(e)).toList();
  }

  Future<void> saveScripts(List<Script> scripts) async {
    final List<String> items = scripts.map((e) => e.toJson()).toList();
    await _prefs.setStringList(_scriptsKey, items);
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
      _scriptsKey: getScripts().map((e) => e.toMap()).toList(),
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
      
      if (data.containsKey(_scriptsKey)) {
        final List scripts = data[_scriptsKey];
        await saveScripts(scripts.map((e) => Script.fromMap(e)).toList());
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
      throw Exception("Failed to import data: $e");
    }
  }

  // Seed Placeholder Data
  Future<void> seedIfEmpty() async {
    if (getScripts().isEmpty && getTimeBlocks().isEmpty && getEarnings().isEmpty && getNotes().isEmpty) {
      await saveScripts([
        Script(title: 'Flutter UI Tutorial', status: ScriptStatus.idea, wordCount: 0, deadline: DateTime.now().add(const Duration(days: 7))),
        Script(title: 'Top 10 Tech Gadgets 2026', status: ScriptStatus.draft, wordCount: 850, deadline: DateTime.now().add(const Duration(days: 2))),
      ]);

      await saveTimeBlocks([
        TimeBlock(title: 'Script Editing', startTime: DateTime.now().add(const Duration(minutes: 5)), endTime: DateTime.now().add(const Duration(hours: 1)), colorTag: '#FF00FFCC', recurrence: Recurrence.none),
      ]);

      await saveEarnings([
        Earning(amount: 150.0, source: 'Sponsorship', date: DateTime.now().subtract(const Duration(days: 1))),
        Earning(amount: 300.0, source: 'Freelance Design', date: DateTime.now().subtract(const Duration(days: 3))),
      ]);

      await saveNotes([
        Note(title: 'Video Idea: AI Tools', body: 'Discuss latest AI generation tools. Mention Gemini.', tags: ['Ideas', 'AI']),
      ]);
    }
  }
}
