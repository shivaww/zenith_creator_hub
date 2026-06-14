import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
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
      body: Column(
        children: [
          TableCalendar(
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
          const Divider(),
          Expanded(
            child: selectedBlocks.isEmpty
                ? const Center(child: Text('No blocks scheduled.'))
                : ListView.builder(
                    itemCount: selectedBlocks.length,
                    itemBuilder: (context, index) {
                      final block = selectedBlocks[index];
                      return _buildTimeBlockTile(block);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditBlockModal(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTimeBlockTile(TimeBlock block) {
    return Dismissible(
      key: Key(block.id),
      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
      onDismissed: (_) {
        ref.read(timeBlocksProvider.notifier).removeBlock(block.id);
      },
      child: ListTile(
        leading: Container(
          width: 12,
          color: Color(int.parse(block.colorTag.replaceFirst('#', '0xFF'))),
        ),
        title: Text(block.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${DateFormat.jm().format(block.startTime)} - ${DateFormat.jm().format(block.endTime)} \nRepeat: ${block.recurrence.name}'),
        trailing: Switch(
          value: block.remindersEnabled,
          onChanged: (val) {
            ref.read(timeBlocksProvider.notifier).updateBlock(block.copyWith(remindersEnabled: val));
          },
          activeColor: Theme.of(context).primaryColor,
        ),
        onTap: () => _showAddEditBlockModal(context, ref, block: block),
      ),
    );
  }

  void _showAddEditBlockModal(BuildContext context, WidgetRef ref, {TimeBlock? block}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: _AddEditBlockForm(block: block, initialDate: _selectedDay ?? DateTime.now()),
        );
      },
    );
  }
}

extension on TimeBlock {
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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Task Title'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Start'),
                  subtitle: Text(_startTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: _startTime);
                    if (time != null) setState(() => _startTime = time);
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  title: const Text('End'),
                  subtitle: Text(_endTime.format(context)),
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
            decoration: const InputDecoration(labelText: 'Recurrence'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final sDateTime = DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day, _startTime.hour, _startTime.minute);
              final eDateTime = DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day, _endTime.hour, _endTime.minute);
              
              final newBlock = TimeBlock(
                id: widget.block?.id,
                title: _titleController.text.trim().isEmpty ? 'Untitled' : _titleController.text.trim(),
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
            child: const Text('Save Block'),
          )
        ],
      ),
    );
  }
}
