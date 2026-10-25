import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/money_transaction.dart';
import '../services/db_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String ownerPersonnelNo;

  const TransactionHistoryScreen({super.key, required this.ownerPersonnelNo});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MoneyTransaction> _allTransactions = [];
  bool _loading = true;
  String _selectedCategory = 'All Categories';
  String _selectedType = 'All';
  String _selectedRange = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _loading = true);
    try {
      final transactions = await DBService.listMoneyTransactions(
        widget.ownerPersonnelNo,
      );
      if (!mounted) return;
      setState(() {
        _allTransactions = transactions;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load history: $error')));
    }
  }

  List<String> get _categories {
    final all = <String>{'All Categories'};
    for (final transaction in _allTransactions) {
      all.add(transaction.category);
    }
    return all.toList()..sort();
  }

  List<MoneyTransaction> get _filteredTransactions {
    final query = _searchController.text.trim().toLowerCase();
    final start = _startDate;
    final end = _endDate;

    return _allTransactions.where((transaction) {
      final matchesQuery = query.isEmpty ||
          transaction.title.toLowerCase().contains(query) ||
          transaction.category.toLowerCase().contains(query) ||
          (transaction.tags ?? '').toLowerCase().contains(query);

      final matchesCategory =
          _selectedCategory == 'All Categories' ||
          transaction.category == _selectedCategory;

      final matchesType =
          _selectedType == 'All' ||
          (transaction.isIncome && _selectedType == 'Income') ||
          (!transaction.isIncome && _selectedType == 'Expense');

      final matchesRange = _matchesRange(transaction.date, start, end);

      return matchesQuery && matchesCategory && matchesType && matchesRange;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  bool _matchesRange(DateTime date, DateTime? startDate, DateTime? endDate) {
    final now = DateTime.now();
    DateTime? normalizedStart;
    DateTime? normalizedEnd;

    switch (_selectedRange) {
      case 'week':
        normalizedStart = now.subtract(const Duration(days: 6));
        normalizedEnd = now;
        break;
      case 'month':
        normalizedStart = DateTime(now.year, now.month, 1);
        final nextMonthYear = now.month == 12 ? now.year + 1 : now.year;
        final nextMonth = now.month == 12 ? 1 : now.month + 1;
        normalizedEnd = DateTime(nextMonthYear, nextMonth, 0, 23, 59, 59);
        break;
      case 'year':
        normalizedStart = DateTime(now.year, 1, 1);
        normalizedEnd = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'all':
        normalizedStart = startDate;
        normalizedEnd = endDate;
        break;
      default:
        normalizedStart = startDate;
        normalizedEnd = endDate;
        break;
    }

    if (normalizedStart != null && date.isBefore(normalizedStart)) return false;
    if (normalizedEnd != null && date.isAfter(normalizedEnd)) return false;
    return true;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = (isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
      _selectedRange = 'all';
    });
  }

  void _clearDateFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedRange = 'all';
    });
  }

  Future<void> _downloadCsv() async {
    final rows = _filteredTransactions;
    final csv = StringBuffer();
    csv.writeln('Title,Type,Category,Date,Amount,Tags');
    for (final item in rows) {
      final line = [
        item.title.replaceAll(',', ' '),
        item.isIncome ? 'Income' : 'Expense',
        item.category.replaceAll(',', ' '),
        DateFormat('yyyy-MM-dd').format(item.date),
        item.amount.toStringAsFixed(2),
        (item.tags ?? '').replaceAll(',', ' '),
      ].join(',');
      csv.writeln(line);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/transaction_history_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(csv.toString());

    final xFile = XFile(file.path);
    await Share.shareXFiles(
      [xFile],
      text: 'Transaction history export',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV exported and ready to share')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 232, 234, 230),
      appBar: AppBar(
        backgroundColor: const Color(0xFFB7DAB1),
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            tooltip: 'Download history',
            onPressed: _downloadCsv,
            icon: const Icon(Icons.picture_as_pdf),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Search transactions...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _FilterField(
                          label: 'Category',
                          value: _selectedCategory,
                          items: _categories,
                          onChanged: (value) => setState(() => _selectedCategory = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FilterField(
                          label: 'Type',
                          value: _selectedType,
                          items: const ['All', 'Expense', 'Income'],
                          onChanged: (value) => setState(() => _selectedType = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDEEE0),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedRange = 'all'),
                            child: _RangePill(
                              label: 'All',
                              selected: _selectedRange == 'all',
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedRange = 'week'),
                            child: _RangePill(
                              label: 'Week',
                              selected: _selectedRange == 'week',
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedRange = 'month'),
                            child: _RangePill(
                              label: 'Month',
                              selected: _selectedRange == 'month',
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedRange = 'year'),
                            child: _RangePill(
                              label: 'Year',
                              selected: _selectedRange == 'year',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickDate(isStart: true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _startDate == null ? 'Start Date' : DateFormat('MMM d, yyyy').format(_startDate!),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickDate(isStart: false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _endDate == null ? 'End Date' : DateFormat('MMM d, yyyy').format(_endDate!),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _clearDateFilters,
                        icon: const Icon(Icons.close),
                        tooltip: 'Clear dates',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Center(child: Text('No transactions found.')),
                    )
                  else ...[
                    for (final item in filtered)
                      _HistoryCard(transaction: item),
                  ],
                ],
              ),
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _FilterField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: (newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ),
    );
  }
}

class _RangePill extends StatelessWidget {
  final String label;
  final bool selected;

  const _RangePill({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFBDE3C3) : Colors.transparent,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.black : Colors.black87,
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final MoneyTransaction transaction;

  const _HistoryCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final color = transaction.isIncome ? Colors.green : Colors.red;
    final formattedAmount =
        '${transaction.isIncome ? '+' : '-'} ৳${NumberFormat('#,##0.00').format(transaction.amount)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withValues(alpha: 0.18),
            child: Icon(
              transaction.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  '${transaction.category} • ${DateFormat('MMM d, yyyy').format(transaction.date)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            formattedAmount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
