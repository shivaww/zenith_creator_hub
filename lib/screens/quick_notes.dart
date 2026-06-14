import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import '../providers/providers.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

class QuickNotes extends ConsumerStatefulWidget {
  const QuickNotes({super.key});

  @override
  ConsumerState<QuickNotes> createState() => _QuickNotesState();
}

class _QuickNotesState extends ConsumerState<QuickNotes> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(notesProvider);
    final notes = allNotes.where((n) {
      if (_searchQuery.isEmpty) return true;
      return n.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
             n.body.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Research & Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: () => _showExportImportMenu(context, ref),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ).animate().fade().slideY(begin: -0.2),
          Expanded(
            child: notes.isEmpty
                ? Center(child: const Text('No notes found.').animate().fade())
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return GestureDetector(
                        onTap: () => _showAddEditNoteModal(context, ref, note: note),
                        child: _buildNoteCard(note),
                      ).animate().fade(duration: (200 + (index * 50)).ms).scale(delay: (index * 50).ms);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditNoteModal(context, ref),
        child: const Icon(Icons.add),
      ).animate().scale(delay: 500.ms),
    );
  }

  Widget _buildNoteCard(Note note) {
    return Card(
      color: Colors.primaries[note.id.hashCode % Colors.primaries.length].withOpacity(0.15),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.primaries[note.id.hashCode % Colors.primaries.length].withOpacity(0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Expanded(child: Text(note.body, style: const TextStyle(fontSize: 14), overflow: TextOverflow.fade)),
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: note.tags.take(2).map((t) => Chip(
                  label: Text(t, style: const TextStyle(fontSize: 10)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: Colors.white24),
                )).toList(),
              )
            ]
          ],
        ),
      ),
    );
  }

  void _showExportImportMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.upload, color: Colors.blue),
                title: const Text('Export Data'),
                onTap: () async {
                  Navigator.pop(context);
                  final jsonStr = ref.read(storageServiceProvider).exportData();
                  final dir = await getApplicationDocumentsDirectory();
                  final file = File('\${dir.path}/zenith_export.json');
                  await file.writeAsString(jsonStr);
                  await Share.shareXFiles([XFile(file.path)], text: 'Zenith Creator Hub Backup');
                },
              ),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.green),
                title: const Text('Import Data'),
                onTap: () async {
                  Navigator.pop(context);
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                  );
                  if (result != null) {
                    File file = File(result.files.single.path!);
                    String content = await file.readAsString();
                    await ref.read(storageServiceProvider).importData(content);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import successful! Please restart the app.')));
                  }
                },
              ),
            ],
          ),
        ).animate().slideY(begin: 1.0, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
      },
    );
  }

  void _showAddEditNoteModal(BuildContext context, WidgetRef ref, {Note? note}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: _AddEditNoteForm(note: note),
        ).animate().slideY(begin: 1.0, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
      },
    );
  }
}

class _AddEditNoteForm extends ConsumerStatefulWidget {
  final Note? note;
  const _AddEditNoteForm({this.note});

  @override
  ConsumerState<_AddEditNoteForm> createState() => _AddEditNoteFormState();
}

class _AddEditNoteFormState extends ConsumerState<_AddEditNoteForm> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _urlController;
  late TextEditingController _tagsController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _bodyController = TextEditingController(text: widget.note?.body ?? '');
    _urlController = TextEditingController(text: widget.note?.url ?? '');
    _tagsController = TextEditingController(text: widget.note?.tags.join(', ') ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return ListView(
          padding: const EdgeInsets.all(32.0),
          controller: controller,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Note', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                if (widget.note != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      ref.read(notesProvider.notifier).removeNote(widget.note!.id);
                      Navigator.pop(context);
                    },
                  )
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(labelText: 'Content', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              maxLines: 8,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.open_in_browser),
                  onPressed: () async {
                    final url = _urlController.text.trim();
                    if (url.isNotEmpty) {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(labelText: 'Tags (comma separated)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  final tags = _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  final newNote = Note(
                    id: widget.note?.id,
                    title: _titleController.text.trim().isEmpty ? 'Untitled' : _titleController.text.trim(),
                    body: _bodyController.text.trim(),
                    url: _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
                    tags: tags,
                  );
                  if (widget.note == null) {
                    ref.read(notesProvider.notifier).addNote(newNote);
                  } else {
                    ref.read(notesProvider.notifier).updateNote(newNote);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save Note', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        );
      },
    );
  }
}
