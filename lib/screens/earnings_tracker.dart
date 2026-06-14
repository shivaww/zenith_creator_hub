import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
              width: 20,
              borderRadius: BorderRadius.circular(6),
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
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.secondary, Theme.of(context).primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  const Text('All Time Earnings', style: TextStyle(fontSize: 18, color: Colors.white70)),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₹\${NumberFormat.decimalPattern().format(totalEarnings)}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fade().scale(curve: Curves.easeOutBack),
          
          const SizedBox(height: 32),
          const Text('Income Over Time', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)).animate().fade(delay: 200.ms).slideX(),
          const SizedBox(height: 24),
          if (barGroups.isNotEmpty)
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.white12, strokeWidth: 1)),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < sortedKeys.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(DateFormat.MMM().format(sortedKeys[value.toInt()]), style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ).animate().fade(delay: 300.ms).slideY(begin: 0.2)
          else
            const Center(child: Text('No data for chart.')).animate().fade(delay: 300.ms),
          
          const SizedBox(height: 32),
          const Text('Recent Entries', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)).animate().fade(delay: 400.ms).slideX(),
          const SizedBox(height: 16),
          ...earnings.reversed.take(10).toList().asMap().entries.map((entry) {
            int idx = entry.key;
            Earning e = entry.value;
            return Dismissible(
              key: Key(e.id),
              background: Container(
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                ref.read(earningsProvider.notifier).removeEarning(e.id);
              },
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: CircleAvatar(backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2), child: Icon(Icons.arrow_downward, color: Theme.of(context).colorScheme.tertiary)),
                  title: Text(e.source, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat.yMMMd().format(e.date)),
                  trailing: SizedBox(
                    width: 120,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text('₹\${NumberFormat.decimalPattern().format(e.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                ),
              ),
            ).animate().fade(delay: (500 + (idx * 100)).ms).slideY(begin: 0.2);
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEarningModal(context, ref),
        child: const Icon(Icons.add),
      ).animate().scale(delay: 600.ms),
    );
  }

  void _showAddEarningModal(BuildContext context, WidgetRef ref) {
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
          child: const _AddEarningForm(),
        ).animate().slideY(begin: 1.0, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
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
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 32),
          const Text('Add Earning', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: 'Amount (₹)',
              prefixText: '₹ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _sourceController,
            decoration: InputDecoration(
              labelText: 'Source (e.g. YouTube Ads)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white24)),
            title: const Text('Date'),
            subtitle: Text(DateFormat.yMMMd().format(_date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime.now());
              if (d != null) setState(() => _date = d);
            },
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
                final amountText = _amountController.text.replaceAll(',', '').trim();
                final amount = double.tryParse(amountText) ?? 0.0;
                final source = _sourceController.text.trim();
                if (amount > 0 && source.isNotEmpty) {
                  ref.read(earningsProvider.notifier).addEarning(Earning(amount: amount, source: source, date: _date));
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount and source')));
                }
              },
              child: const Text('Save Earning', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
