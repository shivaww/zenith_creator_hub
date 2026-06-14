import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class EarningsTracker extends ConsumerWidget {
  const EarningsTracker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(earningsProvider);

    final totalEarnings = earnings.fold(0.0, (sum, e) => sum + e.amount);
    
    // Group by month
    final grouped = groupBy(earnings, (Earning e) => DateTime(e.date.year, e.date.month));
    final sortedKeys = grouped.keys.toList()..sort();
    
    List<BarChartGroupData> barGroups = [];
    int x = 0;
    for (var key in sortedKeys) {
      final monthEarnings = grouped[key]!.fold(0.0, (sum, e) => sum + e.amount);
      barGroups.add(
        BarChartGroupData(
          x: x,
          barRods: [
            BarChartRodData(
              toY: monthEarnings,
              color: Theme.of(context).primaryColor,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        ),
      );
      x++;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings Tracker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text('All Time Earnings', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat.currency(symbol: '\$').format(totalEarnings),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Income Over Time', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (barGroups.isNotEmpty)
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < sortedKeys.length) {
                            return Text(DateFormat.MMM().format(sortedKeys[value.toInt()]));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            const Center(child: Text('No data for chart.')),
          const SizedBox(height: 24),
          const Text('Recent Entries', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ...earnings.reversed.take(10).map((e) => Dismissible(
                key: Key(e.id),
                background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
                onDismissed: (_) {
                  ref.read(earningsProvider.notifier).removeEarning(e.id);
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(e.source),
                    subtitle: Text(DateFormat.yMMMd().format(e.date)),
                    trailing: Text(NumberFormat.currency(symbol: '\$').format(e.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEarningModal(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEarningModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: const _AddEarningForm(),
        );
      },
    );
  }
}

class _AddEarningForm extends ConsumerStatefulWidget {
  const _AddEarningForm();

  @override
  ConsumerState<_AddEarningForm> createState() => _AddEarningFormState();
}

class _AddEarningFormState extends ConsumerState<_AddEarningForm> {
  final _sourceController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Amount (\$)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sourceController,
            decoration: const InputDecoration(labelText: 'Source (e.g. YouTube Ads)'),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Date'),
            subtitle: Text(DateFormat.yMMMd().format(_date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime.now());
              if (d != null) setState(() => _date = d);
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_amountController.text) ?? 0.0;
              final source = _sourceController.text.trim();
              if (amount > 0 && source.isNotEmpty) {
                ref.read(earningsProvider.notifier).addEarning(Earning(amount: amount, source: source, date: _date));
                Navigator.pop(context);
              }
            },
            child: const Text('Add Earning'),
          )
        ],
      ),
    );
  }
}
