import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String description;
  final double amount;
  final String paidBy;
  final List<String> splitAmong;
  final DateTime createdAt;
  final bool settled;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.splitAmong,
    required this.createdAt,
    required this.settled,
  });

  double get shareAmount => splitAmong.isEmpty ? 0 : amount / splitAmong.length;

  factory Expense.fromMap(String id, Map<String, dynamic> data) {
    return Expense(
      id: id,
      description: data['description'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      paidBy: data['paidBy'] as String? ?? '',
      splitAmong: List<String>.from(data['splitAmong'] as List? ?? const []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      settled: data['settled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'amount': amount,
      'paidBy': paidBy,
      'splitAmong': splitAmong,
      'createdAt': FieldValue.serverTimestamp(),
      'settled': settled,
    };
  }
}
