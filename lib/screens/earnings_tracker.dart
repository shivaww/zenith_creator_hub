import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/providers.dart';
import '../models/models.dart';

enum EarningsFilter { today, week, month, year, lifetime }

class EarningsTracker extends ConsumerStatefulWidget {
  const EarningsTracker({super.key});

  @override
  ConsumerState<EarningsTracker> createState() => _EarningsTrackerState();
}

class _EarningsTrackerState extends ConsumerState<EarningsTracker> {
  EarningsFilter _currentFilter = EarningsFilter.lifetime;

  @override
  Widget build(BuildContext context) {
    final earnings = ref.watch(earningsProvider);
    final now = DateTime.now();

    final filteredEarnings = earnings.where((e) {
      switch (_currentFilter) {
        case EarningsFilter.today:
          return isSameDay(e.date, now);
        case EarningsFilter.week:
          return e.date.isAfter(now.subtract(const Duration(days: 7)));
        case EarningsFilter.month:
          return e.date.year == now.year && e.date.month == now.month;
        case EarningsFilter.year:
          return e.date.year == now.year;
        case EarningsFilter.lifetime:
          return true;
      }
    }).toList();

    final totalAmount = filteredEarnings.fold(0.0, (sum, e) => sum + e.amount);

    // Grouping for chart (always show by month for historical view)
    final grouped = groupBy(earnings, (Earning e) => DateTime(e.date.year, e.date.month));
    final sortedKeys = grouped.keys.toList()..sort();
    
    List<BarChartGroupData> barGroups = [];
    double maxY = 0;
    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final monthEarnings = grouped[key]!.fold(0.0, (sum, e) => sum + e.amount);
      if (monthEarnings > maxY) maxY = monthEarnings;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: monthEarnings,
              color: Theme.of(context).primaryColor,
              width: 22,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxY > 0 ? maxY : 100, color: Colors.white10),
            )
          ],
          showingTooltipIndicators: [0],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings Tracker')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Filter Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: EarningsFilter.values.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter.name.toUpperCase()),
                      selected: _currentFilter == filter,
                      onSelected: (val) {
                        if (val) setState(() => _currentFilter = filter);
                      },
                      selectedColor: Theme.of(context).primaryColor,
                    ),
                  );
                }).toList(),
              ),
            ).animate().fade().slideY(begin: -0.2),
            
            const SizedBox(height: 24),
            
            // Total Card
            Card(
              child: Container(
                width: double.infinity,
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
                    Text('${_currentFilter.name.toUpperCase()} EARNINGS', style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '₹${NumberFormat.decimalPattern().format(totalAmount)}',
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
            ).animate().fade(delay: 100.ms).scale(curve: Curves.easeOutBack),
            
            const SizedBox(height: 32),
            const Text('Revenue History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)).animate().fade(delay: 200.ms).slideX(),
            const SizedBox(height: 24),
            
            // Chart with Horizontal Scroll for previous months
            if (barGroups.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: sortedKeys.length * 80.0 > MediaQuery.of(context).size.width ? sortedKeys.length * 80.0 : MediaQuery.of(context).size.width,
                  height: 300,
                  padding: const EdgeInsets.only(top: 20, right: 16),
                  child: BarChart(
                    BarChartData(
                      maxY: maxY * 1.2,
                      barGroups: barGroups,
                      barTouchData: BarTouchData(
                        enabled: false,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => Colors.transparent,
                          tooltipPadding: EdgeInsets.zero,
                          tooltipMargin: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '₹${NumberFormat.compact().format(rod.toY)}',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                            );
                          },
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
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
                                  child: Text(DateFormat.MMM().format(sortedKeys[value.toInt()]), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().fade(delay: 300.ms).slideY(begin: 0.1)
            else
              const Center(child: Text('No historical data available.')).animate().fade(delay: 300.ms),
            
            const SizedBox(height: 32),
            const Text('Recent Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)).animate().fade(delay: 400.ms).slideX(),
            const SizedBox(height: 16),
            ...filteredEarnings.reversed.take(15).toList().asMap().entries.map((entry) {
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
                    leading: CircleAvatar(backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2), child: const Icon(Icons.arrow_downward, color: Colors.green)),
                    title: Text(e.source, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat.yMMMd().format(e.date)),
                    trailing: SizedBox(
                      width: 100,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text('₹${NumberFormat.decimalPattern().format(e.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    ),
                  ),
                ),
              ).animate().fade(delay: (500 + (idx * 50)).ms).slideX(begin: 0.1);
            }),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEarningModal(context, ref),
        child: const Icon(Icons.add),
      ).animate().scale(delay: 600.ms),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showAddEarningModal(BuildContext context, WidgetRef ref) {
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
            child: const _AddEarningForm(),
          ),
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
          const Text('New Entry', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: _amountController,
            autofocus: true,
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
              labelText: 'Source Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white24)),
            title: const Text('Transaction Date'),
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount and source')));
                }
              },
              child: const Text('Save Transaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
