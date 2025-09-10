class Expense {
  final int? id;
  final String title;
  final double amount;
  final DateTime dateTime;
  String category;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.dateTime,
    this.category = "Uncategorized",
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dateTime': dateTime.toIso8601String(),
      'category': category,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      dateTime: DateTime.parse(map['dateTime']),
      category: map['category'] ?? "Uncategorized",
    );
  }
}
