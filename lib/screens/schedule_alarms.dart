import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class ScheduleAlarms extends ConsumerStatefulWidget {
  const ScheduleAlarms({super.key});

  @override
  ConsumerState<ScheduleAlarms> createState() => _ScheduleAlarmsState();
}

class _ScheduleAlarmsState extends ConsumerState<ScheduleAlarms> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final blocks = ref.watch(timeBlocksProvider);

    final selectedBlocks = blocks.where((b) {
      if (_selectedDay == null) return false;
      if (b.recurrence == Recurrence.daily) return true;
      if (b.recurrence == Recurrence.weekdays) {
        return _selectedDay!.weekday >= DateTime.monday && _selectedDay!.weekday <= DateTime.friday;
      }
      return isSameDay(b.startTime, _selectedDay);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule & Alarms')),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.week,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ).animate().fade().slideY(begin: -0.1),
            Expanded(
              child: selectedBlocks.isEmpty
                  ? Center(child: const Text('No blocks scheduled.').animate().fade())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: selectedBlocks.length,
                      itemBuilder: (context, index) {
                        final block = selectedBlocks[index];
                        return _buildTimeBlockTile(block).animate().fade(duration: (200 + (index * 100)).ms).slideY(begin: 0.2, end: 0);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditBlockModal(context, ref),
        child: const Icon(Icons.add),
      ).animate().scale(delay: 400.ms),
    );
  }

  Widget _buildTimeBlockTile(TimeBlock block) {
    return Dismissible(
      key: Key(block.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(timeBlocksProvider.notifier).removeBlock(block.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 6,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Color(int.parse(block.colorTag.replaceFirst('#', '0xFF'))),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          title: Text(block.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${DateFormat.jm().format(block.startTime)} - ${DateFormat.jm().format(block.endTime)} \nRepeat: ${block.recurrence.name.toUpperCase()}'),
          trailing: Switch(
            value: block.remindersEnabled,
            onChanged: (val) {
              ref.read(timeBlocksProvider.notifier).updateBlock(block.copyWith(remindersEnabled: val));
            },
            activeColor: Theme.of(context).primaryColor,
          ),
          onTap: () => _showAddEditBlockModal(context, ref, block: block),
        ),
      ),
    );
  }

  void _showAddEditBlockModal(BuildContext context, WidgetRef ref, {TimeBlock? block}) {
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              child: _AddEditBlockForm(block: block, initialDate: _selectedDay ?? DateTime.now()),
            ),
          ).animate().slideY(begin: 1.0, end: 0, duration: 300.ms, curve: Curves.easeOutCubic),
        );
      },
    );
  }
}

class _AddEditBlockForm extends ConsumerStatefulWidget {
  final TimeBlock? block;
  final DateTime initialDate;
  const _AddEditBlockForm({this.block, required this.initialDate});

  @override
  ConsumerState<_AddEditBlockForm> createState() => _AddEditBlockFormState();
}

class _AddEditBlockFormState extends ConsumerState<_AddEditBlockForm> {
  late TextEditingController _titleController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late Recurrence _recurrence;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.block?.title ?? '');
    _startTime = widget.block != null ? TimeOfDay.fromDateTime(widget.block!.startTime) : TimeOfDay.now();
    _endTime = widget.block != null ? TimeOfDay.fromDateTime(widget.block!.endTime) : TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
    _recurrence = widget.block?.recurrence ?? Recurrence.none;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 32),
          Text(widget.block == null ? 'New Schedule' : 'Edit Schedule', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: 'Task Title', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white24)),
                  title: const Text('Start'),
                  subtitle: Text(_startTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: _startTime);
                    if (time != null) setState(() => _startTime = time);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white24)),
                  title: const Text('End'),
                  subtitle: Text(_endTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: _endTime);
                    if (time != null) setState(() => _endTime = time);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Recurrence>(
            value: _recurrence,
            items: Recurrence.values.map((r) => DropdownMenuItem(value: r, child: Text(r.name.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => _recurrence = v!),
            decoration: InputDecoration(labelText: 'Recurrence', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                final title = _titleController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task Title cannot be empty')));
                  return;
                }
                final sDateTime = DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day, _startTime.hour, _startTime.minute);
                final eDateTime = DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day, _endTime.hour, _endTime.minute);
                
                final newBlock = TimeBlock(
                  id: widget.block?.id,
                  title: title,
                  startTime: sDateTime,
                  endTime: eDateTime,
                  colorTag: '#FF00FFCC', // Default cyan for simplicity
                  recurrence: _recurrence,
                  remindersEnabled: widget.block?.remindersEnabled ?? true,
                );

                if (widget.block == null) {
                  ref.read(timeBlocksProvider.notifier).addBlock(newBlock);
                } else {
                  ref.read(timeBlocksProvider.notifier).updateBlock(newBlock);
                }
                Navigator.pop(context);
              },
              child: const Text('Save Block', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
