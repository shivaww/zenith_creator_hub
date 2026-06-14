import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class ScriptTracker extends ConsumerWidget {
  const ScriptTracker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scripts = ref.watch(scriptsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Script Tracker'),
      ),
      body: scripts.isEmpty
          ? const Center(child: Text('No scripts. Add one!'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: scripts.length,
              itemBuilder: (context, index) {
                final script = scripts[index];
                return Dismissible(
                  key: Key(script.id),
                  background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
                  onDismissed: (_) {
                    ref.read(scriptsProvider.notifier).removeScript(script.id);
                  },
                  child: GestureDetector(
                    onTap: () => _showAddEditScriptModal(context, ref, script: script),
                    child: _buildScriptCard(context, script),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditScriptModal(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildScriptCard(BuildContext context, Script script) {
    double progress = script.status.index / 3;
    Color statusColor;
    switch (script.status) {
      case ScriptStatus.idea: statusColor = Colors.grey; break;
      case ScriptStatus.draft: statusColor = Colors.orange; break;
      case ScriptStatus.finalEdit: statusColor = Colors.blue; break;
      case ScriptStatus.published: statusColor = Colors.green; break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(script.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                Chip(
                  label: Text(script.status.name.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress, backgroundColor: Colors.white12, color: statusColor),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${script.wordCount} words', style: Theme.of(context).textTheme.bodyMedium),
                Text('Due: ${DateFormat.yMMMd().format(script.deadline)}', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditScriptModal(BuildContext context, WidgetRef ref, {Script? script}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: _AddEditScriptForm(script: script),
        );
      },
    );
  }
}

class _AddEditScriptForm extends ConsumerStatefulWidget {
  final Script? script;
  const _AddEditScriptForm({this.script});

  @override
  ConsumerState<_AddEditScriptForm> createState() => _AddEditScriptFormState();
}

class _AddEditScriptFormState extends ConsumerState<_AddEditScriptForm> {
  late TextEditingController _titleController;
  late TextEditingController _wordCountController;
  late ScriptStatus _status;
  late DateTime _deadline;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.script?.title ?? '');
    _wordCountController = TextEditingController(text: widget.script?.wordCount.toString() ?? '0');
    _status = widget.script?.status ?? ScriptStatus.idea;
    _deadline = widget.script?.deadline ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ScriptStatus>(
            value: _status,
            items: ScriptStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => _status = v!),
            decoration: const InputDecoration(labelText: 'Status'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _wordCountController,
            decoration: const InputDecoration(labelText: 'Word Count'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Deadline'),
            subtitle: Text(DateFormat.yMMMd().format(_deadline)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _deadline,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) setState(() => _deadline = date);
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final newScript = Script(
                id: widget.script?.id,
                title: _titleController.text.trim().isEmpty ? 'Untitled' : _titleController.text.trim(),
                status: _status,
                wordCount: int.tryParse(_wordCountController.text) ?? 0,
                deadline: _deadline,
              );
              if (widget.script == null) {
                ref.read(scriptsProvider.notifier).addScript(newScript);
              } else {
                ref.read(scriptsProvider.notifier).updateScript(newScript);
              }
              Navigator.pop(context);
            },
            child: const Text('Save Script'),
          )
        ],
      ),
    );
  }
}
