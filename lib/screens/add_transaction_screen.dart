import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/money_transaction.dart';
import '../services/db_service.dart';

const List<String> _defaultCategories = [
  'Shopping',
  'Food',
  'Transportation',
  'Bills',
  'Health',
  'Entertainment',
  'Salary',
  'Other',
];

class AddTransactionScreen extends StatefulWidget {
  final String ownerPersonnelNo;

  const AddTransactionScreen({super.key, required this.ownerPersonnelNo});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _categories = List.of(_defaultCategories);
  String _type = 'expense';
  String _category = 'Shopping';
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final category = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add category'),
            content: TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Category name'),
              onSubmitted: (value) => Navigator.pop(context, value.trim()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Add'),
              ),
            ],
          ),
    );
    controller.dispose();
    if (!mounted || category == null || category.isEmpty) return;
    setState(() {
      if (!_categories.contains(category)) _categories.add(category);
      _category = category;
    });
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      await DBService.insertMoneyTransaction(
        MoneyTransaction(
          ownerPersonnelNo: widget.ownerPersonnelNo,
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          type: _type,
          category: _category,
          date: _date,
          tags:
              _tagController.text.trim().isEmpty
                  ? null
                  : _tagController.text.trim(),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error, stackTrace) {
      debugPrint('Saving transaction failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save transaction: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Transaction Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'expense',
                  label: Text('Expense'),
                  icon: Icon(Icons.south),
                ),
                ButtonSegment(
                  value: 'income',
                  label: Text('Income'),
                  icon: Icon(Icons.north),
                ),
              ],
              selected: {_type},
              onSelectionChanged:
                  (selection) => setState(() => _type = selection.first),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator:
                  (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter a title'
                          : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '৳ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                if (amount == null || !amount.isFinite || amount <= 0) {
                  return 'Enter an amount greater than zero';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text('Category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _category = value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _addCategory,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Date', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(DateFormat('MMM d, yyyy').format(_date)),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _tagController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Tags (Optional)',
                hintText: 'Add a tag',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child:
                  _saving
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
