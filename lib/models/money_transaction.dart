class MoneyTransaction {
  final int? id;
  final String ownerPersonnelNo;
  final String title;
  final double amount;
  final String type;
  final String category;
  final DateTime date;
  final String? tags;

  const MoneyTransaction({
    this.id,
    required this.ownerPersonnelNo,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.tags,
  });

  bool get isIncome => type == 'income';

  Map<String, dynamic> toMap() => {
    'id': id,
    'owner_personnel_no': ownerPersonnelNo,
    'title': title,
    'amount': amount,
    'type': type,
    'category': category,
    'transaction_date': date.toIso8601String(),
    'tags': tags,
  };

  factory MoneyTransaction.fromMap(Map<String, dynamic> map) =>
      MoneyTransaction(
        id: map['id'] as int?,
        ownerPersonnelNo: map['owner_personnel_no'] as String,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        type: map['type'] as String,
        category: map['category'] as String,
        date: DateTime.parse(map['transaction_date'] as String),
        tags: map['tags'] as String?,
      );
}
