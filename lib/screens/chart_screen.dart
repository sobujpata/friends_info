import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/money_transaction.dart';
import '../services/db_service.dart';

class ChartScreen extends StatefulWidget {
  final String ownerPersonnelNo;

  const ChartScreen({super.key, required this.ownerPersonnelNo});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  List<MoneyTransaction> _transactions = [];
  bool _loading = true;
  String _range = 'month';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _applyRange('month');
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await DBService.listMoneyTransactions(widget.ownerPersonnelNo);
      if (!mounted) return;
      setState(() {
        _transactions = rows
            .where(
              (transaction) =>
                  !transaction.date.isBefore(_startDate) &&
                  !transaction.date.isAfter(_endDate),
            )
            .toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load chart data: $error')));
    }
  }

  void _applyRange(String range) {
    final now = DateTime.now();
    DateTime start;
    switch (range) {
      case 'week':
        start = now.subtract(const Duration(days: 6));
        break;
      case 'year':
        start = DateTime(now.year, 1, 1);
        break;
      case 'month':
      default:
        start = DateTime(now.year, now.month, 1);
        break;
    }

    setState(() {
      _range = range;
      _startDate = DateTime(start.year, start.month, start.day);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
    _load();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = DateTime(picked.year, picked.month, picked.day);
      } else {
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
      _range = 'custom';
    });
    _load();
  }

  List<MoneyTransaction> get _filteredTransactions => _transactions;

  double get _income => _filteredTransactions
      .where((transaction) => transaction.isIncome)
      .fold(0.0, (sum, transaction) => sum + transaction.amount);

  double get _expenses => _filteredTransactions
      .where((transaction) => !transaction.isIncome)
      .fold(0.0, (sum, transaction) => sum + transaction.amount);

  @override
  Widget build(BuildContext context) {
    final expenseGroups = <String, double>{};
    for (final transaction in _filteredTransactions) {
      if (!transaction.isIncome) {
        expenseGroups[transaction.category] =
            (expenseGroups[transaction.category] ?? 0) + transaction.amount;
      }
    }

    final chartSlices = <_ChartSlice>[];
    final palette = const [
      Color(0xFF2F8DDC),
      Color(0xFFE74C3C),
      Color(0xFFF39C12),
      Color(0xFF78D6A0),
      Color(0xFF7F8C8D),
      Color(0xFF9B59B6),
      Color(0xFF1ABC9C),
    ];
    final entries = expenseGroups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalExpenses = entries.fold<double>(0, (sum, item) => sum + item.value);

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final percent = totalExpenses == 0 ? 0.0 : (entry.value / totalExpenses) * 100;
      chartSlices.add(
        _ChartSlice(percent, palette[i % palette.length], entry.key, entry.value),
      );
    }

    final maxSummary = [_income, _expenses].fold<double>(0, math.max);
    final heatmapValues = List.generate(5, (_) => List.filled(7, 0));
    final daysInRange = _endDate.difference(_startDate).inDays + 1;
    for (final transaction in _filteredTransactions) {
      final dayIndex = transaction.date.difference(_startDate).inDays;
      if (dayIndex >= 0 && dayIndex < daysInRange) {
        final row = dayIndex ~/ 7;
        final col = dayIndex % 7;
        if (row < 5) {
          heatmapValues[row][col] += 1;
        }
      }
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        children: [
          _DateRangeSelector(
            startDate: _startDate,
            endDate: _endDate,
            range: _range,
            onRangeChanged: _applyRange,
            onPickDate: _pickDate,
          ),
          const SizedBox(height: 18),
          _RangeToggle(
            range: _range,
            onChanged: _applyRange,
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_filteredTransactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text('No balance data for this date range.'),
              ),
            )
          else ...[
            _DonutChartCard(slices: chartSlices),
            const SizedBox(height: 18),
            _IncomeVsExpenseCard(
              income: _income,
              expenses: _expenses,
              balance: _income - _expenses,
              maxValue: maxSummary == 0 ? 1.0 : maxSummary,
              startDate: _startDate,
              endDate: _endDate,
            ),
            const SizedBox(height: 18),
            _HeatmapCard(values: heatmapValues),
          ],
        ],
      ),
    );
  }
}

class _DateRangeSelector extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String range;
  final ValueChanged<String> onRangeChanged;
  final Future<void> Function({required bool isStart}) onPickDate;

  const _DateRangeSelector({
    required this.startDate,
    required this.endDate,
    required this.range,
    required this.onRangeChanged,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => onPickDate(isStart: true),
              borderRadius: BorderRadius.circular(24),
              child: _Pill(
                label: DateFormat('MMM d, yyyy').format(startDate),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => onPickDate(isStart: false),
              borderRadius: BorderRadius.circular(24),
              child: _Pill(
                label: DateFormat('MMM d, yyyy').format(endDate),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeToggle extends StatelessWidget {
  final String range;
  final ValueChanged<String> onChanged;

  const _RangeToggle({required this.range, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ranges = ['week', 'month', 'year'];
    return Row(
      children: [
        for (int i = 0; i < ranges.length; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(ranges[i]),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: range == ranges[i]
                      ? const Color(0xFFB3D9BA)
                      : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black.withOpacity(0.15)),
                ),
                child: Text(
                  ranges[i][0].toUpperCase() + ranges[i].substring(1),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2A1F),
                  ),
                ),
              ),
            ),
          ),
          if (i < ranges.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final TextStyle? style;

  const _Pill({required this.label, this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.44),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: style ?? Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _DonutChartCard extends StatelessWidget {
  final List<_ChartSlice> slices;

  const _DonutChartCard({required this.slices});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expenses by Category',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: CustomPaint(
                painter: _DonutChartPainter(slices),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              for (final slice in slices)
                _LegendItem(slice.label, '৳${NumberFormat('#,##0.00').format(slice.value)}', slice.color),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartSlice {
  final double percent;
  final Color color;
  final String label;
  final double value;

  const _ChartSlice(this.percent, this.color, this.label, this.value);
}

class _DonutChartPainter extends CustomPainter {
  final List<_ChartSlice> data;

  _DonutChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.33;
    final strokeWidth = radius * 0.9;
    double start = -math.pi / 2;

    for (final item in data) {
      final sweep = (item.percent / 100) * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = item.color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }

    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.42, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LegendItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LegendItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _IncomeVsExpenseCard extends StatelessWidget {
  final double income;
  final double expenses;
  final double balance;
  final double maxValue;
  final DateTime startDate;
  final DateTime endDate;

  const _IncomeVsExpenseCard({
    required this.income,
    required this.expenses,
    required this.balance,
    required this.maxValue,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final incomeRatio = maxValue == 0 ? 0.0 : (income / maxValue).clamp(0.0, 1.0);
    final expenseRatio = maxValue == 0 ? 0.0 : (expenses / maxValue).clamp(0.0, 1.0);
    final rangeText =
        '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Text(
            'Income vs Expenses',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            rangeText,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black54),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _BarCluster(color: const Color(0xFF4CAF50), value: incomeRatio)),
                const SizedBox(width: 26),
                Expanded(child: _BarCluster(color: const Color(0xFFE53935), value: expenseRatio)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MetricLabel(label: 'Income', value: '৳${NumberFormat('#,##0.00').format(income)}', color: const Color(0xFF4CAF50)),
              _MetricLabel(label: 'Expense', value: '৳${NumberFormat('#,##0.00').format(expenses)}', color: const Color(0xFFE53935)),
              _MetricLabel(label: 'Balance', value: '৳${NumberFormat('#,##0.00').format(balance)}', color: const Color(0xFF3f8fd3)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarCluster extends StatelessWidget {
  final Color color;
  final double value;

  const _BarCluster({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 54,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 54,
            height: 120 * value,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricLabel({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  final List<List<int>> values;

  const _HeatmapCard({required this.values});

  @override
  Widget build(BuildContext context) {
    final cells = <Color>[
      Colors.white,
      const Color(0xFFD9EFD9),
      const Color(0xFFC5E8C5),
      const Color(0xFF86CAA0),
      const Color(0xFF27AE60),
      const Color(0xFF1E7F4F),
    ];

    final maxValue = values.expand((row) => row).fold<int>(0, math.max);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.52),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Heatmap',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: values.length * 7,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final row = index ~/ 7;
              final col = index % 7;
              final value = row < values.length ? values[row][col] : 0;
              final cellIndex = maxValue == 0 ? 0 : ((value / maxValue) * (cells.length - 1)).round();
              final color = cells[cellIndex.clamp(0, cells.length - 1)];
              return Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('Less', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              SizedBox(width: 18),
              _MiniLegendBox(color: Color(0xFFE5F0E5)),
              _MiniLegendBox(color: Color(0xFFBEE4C5)),
              _MiniLegendBox(color: Color(0xFF7BC49A)),
              _MiniLegendBox(color: Color(0xFF2F9E63)),
              _MiniLegendBox(color: Color(0xFF1D7047)),
              SizedBox(width: 18),
              Text('More', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniLegendBox extends StatelessWidget {
  final Color color;

  const _MiniLegendBox({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
