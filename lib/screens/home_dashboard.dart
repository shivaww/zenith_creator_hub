import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scripts = ref.watch(scriptsProvider);
    final blocks = ref.watch(timeBlocksProvider);
    final earnings = ref.watch(earningsProvider);
    final notes = ref.watch(notesProvider);

    final upcomingBlocks = blocks.where((b) => b.startTime.isAfter(DateTime.now())).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final dueScripts = scripts.where((s) => s.status != ScriptStatus.published).toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));

    final totalEarningsThisWeek = earnings
        .where((e) => e.date.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zenith Dashboard'),
        actions: [
          IconButton(
            icon: Icon(ref.watch(themeModeProvider) ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              final isDark = ref.read(themeModeProvider);
              ref.read(themeModeProvider.notifier).state = !isDark;
              ref.read(sharedPreferencesProvider).setBool('isDarkMode', !isDark);
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle(context, 'Upcoming Schedule'),
          if (upcomingBlocks.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No upcoming blocks.')))
          else
            ...upcomingBlocks.take(2).map((b) => _buildTimeBlockCard(context, b)),

          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Scripts Due Soon'),
          if (dueScripts.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text('All caught up!')))
          else
            ...dueScripts.take(2).map((s) => _buildScriptCard(context, s)),

          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Earnings This Week'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 18)),
                  Text(
                    NumberFormat.currency(symbol: '\$').format(totalEarningsThisWeek),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Recent Notes'),
          if (notes.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No notes yet.')))
          else
            ...notes.take(2).map((n) => Card(
              child: ListTile(
                title: Text(n.title),
                subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildTimeBlockCard(BuildContext context, TimeBlock block) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 12,
          color: Color(int.parse(block.colorTag.replaceFirst('#', '0xFF'))),
        ),
        title: Text(block.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${DateFormat.jm().format(block.startTime)} - ${DateFormat.jm().format(block.endTime)}'),
      ),
    );
  }

  Widget _buildScriptCard(BuildContext context, Script script) {
    double progress = script.status.index / 3;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(script.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Chip(label: Text(script.status.name.toUpperCase(), style: const TextStyle(fontSize: 10))),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress, backgroundColor: Colors.white12),
            const SizedBox(height: 8),
            Text('Due: ${DateFormat.yMMMd().format(script.deadline)}', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
