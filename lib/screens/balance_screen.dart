import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/money_transaction.dart';
import '../services/db_service.dart';
import 'add_transaction_screen.dart';
import 'transaction_history_screen.dart';

class BalanceScreen extends StatefulWidget {
  final String ownerPersonnelNo;

  const BalanceScreen({super.key, required this.ownerPersonnelNo});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  List<MoneyTransaction> _transactions = [];
  bool _loading = true;

  double get _income => _transactions
      .where((transaction) => transaction.isIncome)
      .fold(0, (total, transaction) => total + transaction.amount);

  double get _expenses => _transactions
      .where((transaction) => !transaction.isIncome)
      .fold(0, (total, transaction) => total + transaction.amount);

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final transactions = await DBService.listMoneyTransactions(
        widget.ownerPersonnelNo,
      );
      if (!mounted) return;
      setState(() {
        _transactions = transactions;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Loading transactions failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load transactions: $error')),
      );
    }
  }

  Future<void> _addTransaction() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                AddTransactionScreen(ownerPersonnelNo: widget.ownerPersonnelNo),
      ),
    );
    if (saved == true && mounted) await _load();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Text(
                    'Balance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Income',
                          amount: _income,
                          icon: Icons.north,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Expenses',
                          amount: _expenses,
                          icon: Icons.south,
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SummaryCard(
                    title: 'Balance',
                    amount: _income - _expenses,
                    icon: Icons.account_balance_wallet_outlined,
                    color: colorScheme.primary,
                    expanded: true,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recent Transactions',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => TransactionHistoryScreen(
                                    ownerPersonnelNo: widget.ownerPersonnelNo,
                                  ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('History'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          const Text('No transactions yet.'),
                          const Text('Tap + to add income or an expense.'),
                        ],
                      ),
                    )
                  else
                    for (final transaction in _transactions.take(20))
                      _TransactionTile(transaction: transaction),
                ],
              ),
            ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            onPressed: _addTransaction,
            tooltip: 'Add transaction',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final bool expanded;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final amountStyle = (expanded
            ? Theme.of(context).textTheme.headlineMedium
            : Theme.of(context).textTheme.titleLarge)
        ?.copyWith(color: color, fontWeight: FontWeight.bold);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '৳${NumberFormat('#,##0.00').format(amount)}',
              style: amountStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final MoneyTransaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final color = transaction.isIncome ? Colors.green : Colors.red;
    final date = DateFormat('MMM d, yyyy').format(transaction.date);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            transaction.isIncome ? Icons.north : Icons.south,
            color: color,
          ),
        ),
        title: Text(transaction.title),
        subtitle: Text(
          '${transaction.category} • $date'
          '${transaction.tags == null ? '' : ' • ${transaction.tags}'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${transaction.isIncome ? '+' : '-'}৳${NumberFormat('#,##0.00').format(transaction.amount)}',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
