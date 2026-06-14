import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class ProjectManager extends ConsumerWidget {
  const ProjectManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Manager'),
      ),
      body: SafeArea(
        child: projects.isEmpty
            ? Center(child: const Text('No active projects.').animate().fade().scale())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return Dismissible(
                    key: Key(project.id),
                    background: Container(
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(24)),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      ref.read(projectsProvider.notifier).removeProject(project.id);
                    },
                    child: GestureDetector(
                      onTap: () => _showAddEditProjectModal(context, ref, project: project),
                      child: _buildProjectCard(context, project),
                    ),
                  ).animate().fade(duration: (200 + (index * 100)).ms).slideY(begin: 0.2, end: 0);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditProjectModal(context, ref),
        child: const Icon(Icons.add),
      ).animate().scale(delay: 500.ms),
    );
  }

  Widget _buildProjectCard(BuildContext context, CreatorProject project) {
    double progress = project.status.index / 4;
    Color statusColor;
    switch (project.status) {
      case ProjectStatus.planning: statusColor = Colors.grey; break;
      case ProjectStatus.research: statusColor = Colors.orange; break;
      case ProjectStatus.scripting: statusColor = Colors.blue; break;
      case ProjectStatus.production: statusColor = Theme.of(context).primaryColor; break;
      case ProjectStatus.completed: statusColor = Colors.green; break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(project.title, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    project.status.name.toUpperCase(),
                    style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress, backgroundColor: Colors.white12, color: statusColor, minHeight: 6, borderRadius: BorderRadius.circular(3)),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.payment, size: 16, color: project.paymentStatus == PaymentStatus.completed ? Colors.green : Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '₹${project.paymentAmount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text('Due: ${DateFormat.MMMEd().format(project.deadline)}', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            if (project.scriptFilePath != null || project.researchFilePaths.isNotEmpty) ...[
              const Divider(height: 24),
              Wrap(
                spacing: 16,
                children: [
                  if (project.scriptFilePath != null)
                    const Icon(Icons.description, size: 16, color: Colors.blue),
                  if (project.researchFilePaths.isNotEmpty)
                    Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.folder_shared, size: 16, color: Colors.orange), const SizedBox(width: 4), Text('${project.researchFilePaths.length}', style: const TextStyle(fontSize: 12))]),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  void _showAddEditProjectModal(BuildContext context, WidgetRef ref, {CreatorProject? project}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: _AddEditProjectForm(project: project),
            ),
          ).animate().slideY(begin: 1.0, end: 0, duration: 300.ms, curve: Curves.easeOutCubic),
        );
      },
    );
  }
}

class _AddEditProjectForm extends ConsumerStatefulWidget {
  final CreatorProject? project;
  const _AddEditProjectForm({this.project});

  @override
  ConsumerState<_AddEditProjectForm> createState() => _AddEditProjectFormState();
}

class _AddEditProjectFormState extends ConsumerState<_AddEditProjectForm> {
  late TextEditingController _titleController;
  late TextEditingController _paymentAmountController;
  late ProjectStatus _status;
  late PaymentStatus _paymentStatus;
  late DateTime _deadline;
  
  String? _scriptFile;
  List<String> _researchFiles = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.project?.title ?? '');
    _paymentAmountController = TextEditingController(text: widget.project?.paymentAmount.toStringAsFixed(0) ?? '0');
    _status = widget.project?.status ?? ProjectStatus.planning;
    _paymentStatus = widget.project?.paymentStatus ?? PaymentStatus.none;
    _deadline = widget.project?.deadline ?? DateTime.now().add(const Duration(days: 7));
    _scriptFile = widget.project?.scriptFilePath;
    _researchFiles = List.from(widget.project?.researchFilePaths ?? []);
  }

  Future<void> _handleFileOpen(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      // Fallback: Use share to allow user to open with any app
      await Share.shareXFiles([XFile(path)], text: 'Open Project File');
    }
  }

  Future<void> _pickScriptFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _scriptFile = result.files.single.path;
      });
    }
  }

  Future<void> _pickResearchFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _researchFiles.addAll(result.paths.where((p) => p != null).cast<String>());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Text(widget.project == null ? 'New Project' : 'Edit Project', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Project Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ProjectStatus>(
            value: _status,
            items: ProjectStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => _status = v!),
            decoration: const InputDecoration(labelText: 'Project Status', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _paymentAmountController,
                  decoration: const InputDecoration(labelText: 'Payment (₹)', border: OutlineInputBorder(), prefixText: '₹ '),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<PaymentStatus>(
                  value: _paymentStatus,
                  items: PaymentStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                  onChanged: (v) => setState(() => _paymentStatus = v!),
                  decoration: const InputDecoration(labelText: 'Payment Status', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.white24)),
            title: const Text('Deadline'),
            subtitle: Text(DateFormat.yMMMd().format(_deadline)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _deadline,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) setState(() => _deadline = date);
            },
          ),
          const Divider(height: 32),
          Text('Files & Assets (Tap icon to Open in External Apps)', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).primaryColor)),
          const SizedBox(height: 16),
          // Script File
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.white24)),
            leading: const Icon(Icons.description, color: Colors.blue),
            title: Text(_scriptFile != null ? _scriptFile!.split('/').last : 'No Script Attached', overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_scriptFile != null) IconButton(icon: const Icon(Icons.open_in_new), onPressed: () => _handleFileOpen(_scriptFile!)),
                IconButton(icon: const Icon(Icons.attach_file), onPressed: _pickScriptFile),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Research Files
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.white24)),
            leading: const Icon(Icons.folder_shared, color: Colors.orange),
            title: Text('${_researchFiles.length} Research Files'),
            trailing: IconButton(icon: const Icon(Icons.add), onPressed: _pickResearchFiles),
          ),
          if (_researchFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 16),
              child: Column(
                children: _researchFiles.map((f) => Row(
                  children: [
                    Expanded(child: Text(f.split('/').last, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                    IconButton(icon: const Icon(Icons.open_in_new, size: 16), onPressed: () => _handleFileOpen(f)),
                    IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.red), onPressed: () => setState(() => _researchFiles.remove(f))),
                  ],
                )).toList(),
              ),
            ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final title = _titleController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project Title cannot be empty')));
                return;
              }
              
              final paymentText = _paymentAmountController.text.replaceAll(',', '').trim();
              
              final newProject = CreatorProject(
                id: widget.project?.id,
                title: title,
                status: _status,
                deadline: _deadline,
                paymentAmount: double.tryParse(paymentText) ?? 0.0,
                paymentStatus: _paymentStatus,
                scriptFilePath: _scriptFile,
                researchFilePaths: _researchFiles,
                completionDate: _status == ProjectStatus.completed && widget.project?.status != ProjectStatus.completed ? DateTime.now() : widget.project?.completionDate,
              );
              
              if (widget.project == null) {
                ref.read(projectsProvider.notifier).addProject(newProject);
              } else {
                ref.read(projectsProvider.notifier).updateProject(newProject);
              }
              Navigator.pop(context);
            },
            child: const Text('Save Project', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
