import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final blocks = ref.watch(timeBlocksProvider);
    final earnings = ref.watch(earningsProvider);
    final notes = ref.watch(notesProvider);

    final upcomingBlocks = blocks.where((b) => b.startTime.isAfter(DateTime.now())).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final dueProjects = projects.where((s) => s.status != ProjectStatus.completed).toList()
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
          _buildSectionTitle(context, 'Earnings This Week').animate().fade().slideX(),
          Card(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearBinding(context),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 18, color: Colors.white)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '₹\${NumberFormat.decimalPattern().format(totalEarningsThisWeek)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fade(delay: 100.ms).scale(),

          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Upcoming Schedule').animate().fade(delay: 200.ms).slideX(),
          if (upcomingBlocks.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No upcoming blocks.'))).animate().fade(delay: 300.ms)
          else
            ...upcomingBlocks.take(2).map((b) => _buildTimeBlockCard(context, b).animate().fade(delay: 300.ms).slideY(begin: 0.2)),

          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Projects Due Soon').animate().fade(delay: 400.ms).slideX(),
          if (dueProjects.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text('All caught up!'))).animate().fade(delay: 500.ms)
          else
            ...dueProjects.take(2).map((p) => _buildProjectCard(context, p).animate().fade(delay: 500.ms).slideY(begin: 0.2)),

          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Recent Notes').animate().fade(delay: 600.ms).slideX(),
          if (notes.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No notes yet.'))).animate().fade(delay: 700.ms)
          else
            ...notes.take(2).map((n) => Card(
              child: ListTile(
                title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ).animate().fade(delay: 700.ms).slideY(begin: 0.2)),
        ],
      ),
    );
  }

  LinearGradient LinearBinding(BuildContext context) {
      return LinearGradient(
                colors: [Theme.of(context).primaryColor, Theme.of(context).colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildTimeBlockCard(BuildContext context, TimeBlock block) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 4,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Color(int.parse(block.colorTag.replaceFirst('#', '0xFF'))),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(block.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('\${DateFormat.jm().format(block.startTime)} - \${DateFormat.jm().format(block.endTime)}'),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, CreatorProject project) {
    double progress = project.status.index / 4;
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
                Expanded(child: Text(project.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Text(project.status.name.toUpperCase(), style: TextStyle(fontSize: 10, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress, backgroundColor: Colors.white12, color: Theme.of(context).colorScheme.tertiary, borderRadius: BorderRadius.circular(2)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.payment, size: 14, color: project.paymentStatus == PaymentStatus.completed ? Colors.green : Colors.orange),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '₹\${project.paymentAmount.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text('Due: \${DateFormat.yMMMd().format(project.deadline)}', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
