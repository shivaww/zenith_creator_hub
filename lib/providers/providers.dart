import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(sharedPreferencesProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// App Theme Mode Provider
final themeModeProvider = StateProvider<bool>((ref) {
  return ref.watch(sharedPreferencesProvider).getBool('isDarkMode') ?? true;
});

// Scripts Provider
class ScriptsNotifier extends StateNotifier<List<Script>> {
  final StorageService storage;
  ScriptsNotifier(this.storage) : super(storage.getScripts());

  void addScript(Script script) {
    state = [...state, script];
    storage.saveScripts(state);
  }

  void updateScript(Script updated) {
    state = [
      for (final script in state)
        if (script.id == updated.id) updated else script
    ];
    storage.saveScripts(state);
  }

  void removeScript(String id) {
    state = state.where((script) => script.id != id).toList();
    storage.saveScripts(state);
  }
}

final scriptsProvider = StateNotifierProvider<ScriptsNotifier, List<Script>>((ref) {
  return ScriptsNotifier(ref.watch(storageServiceProvider));
});

// TimeBlocks Provider
class TimeBlocksNotifier extends StateNotifier<List<TimeBlock>> {
  final StorageService storage;
  final NotificationService notifications;

  TimeBlocksNotifier(this.storage, this.notifications) : super(storage.getTimeBlocks());

  void addBlock(TimeBlock block) {
    state = [...state, block];
    _saveAndSchedule();
  }

  void updateBlock(TimeBlock updated) {
    state = [
      for (final block in state)
        if (block.id == updated.id) updated else block
    ];
    _saveAndSchedule();
  }

  void removeBlock(String id) {
    state = state.where((block) => block.id != id).toList();
    _saveAndSchedule();
  }

  void _saveAndSchedule() {
    storage.saveTimeBlocks(state);
    notifications.scheduleBlockAlarms(state);
  }
}

final timeBlocksProvider = StateNotifierProvider<TimeBlocksNotifier, List<TimeBlock>>((ref) {
  return TimeBlocksNotifier(ref.watch(storageServiceProvider), ref.watch(notificationServiceProvider));
});

// Earnings Provider
class EarningsNotifier extends StateNotifier<List<Earning>> {
  final StorageService storage;
  EarningsNotifier(this.storage) : super(storage.getEarnings());

  void addEarning(Earning earning) {
    state = [...state, earning];
    storage.saveEarnings(state);
  }

  void removeEarning(String id) {
    state = state.where((earning) => earning.id != id).toList();
    storage.saveEarnings(state);
  }
}

final earningsProvider = StateNotifierProvider<EarningsNotifier, List<Earning>>((ref) {
  return EarningsNotifier(ref.watch(storageServiceProvider));
});

// Notes Provider
class NotesNotifier extends StateNotifier<List<Note>> {
  final StorageService storage;
  NotesNotifier(this.storage) : super(storage.getNotes());

  void addNote(Note note) {
    state = [...state, note];
    storage.saveNotes(state);
  }

  void updateNote(Note updated) {
    state = [
      for (final note in state)
        if (note.id == updated.id) updated else note
    ];
    storage.saveNotes(state);
  }

  void removeNote(String id) {
    state = state.where((note) => note.id != id).toList();
    storage.saveNotes(state);
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  return NotesNotifier(ref.watch(storageServiceProvider));
});
