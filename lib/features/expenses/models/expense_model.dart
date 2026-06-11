import 'package:equatable/equatable.dart';

class ExpenseModel extends Equatable {
  final String id;
  final String description;
  final double amount;
  final String paidById;
  final List<String> splitAmongIds;
  final DateTime date;
  final bool isPayment;
  final String? juntadaId;

  const ExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidById,
    required this.splitAmongIds,
    required this.date,
    this.isPayment = false,
    this.juntadaId,
  });

  double get sharePerPerson =>
      splitAmongIds.isEmpty ? amount : amount / splitAmongIds.length;

  ExpenseModel copyWith({
    String? description,
    double? amount,
    String? paidById,
    List<String>? splitAmongIds,
    DateTime? date,
    bool? isPayment,
    String? juntadaId,
    bool removeJuntadaId = false,
  }) =>
      ExpenseModel(
        id: id,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        paidById: paidById ?? this.paidById,
        splitAmongIds: splitAmongIds ?? this.splitAmongIds,
        date: date ?? this.date,
        isPayment: isPayment ?? this.isPayment,
        juntadaId: removeJuntadaId ? null : (juntadaId ?? this.juntadaId),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'paidById': paidById,
        'splitAmongIds': splitAmongIds,
        'date': date.toIso8601String(),
        'isPayment': isPayment,
        'juntadaId': juntadaId,
      };

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
        id: json['id'] as String,
        description: json['description'] as String,
        amount: (json['amount'] as num).toDouble(),
        paidById: json['paidById'] as String,
        splitAmongIds: (json['splitAmongIds'] as List<dynamic>).cast<String>(),
        date: DateTime.parse(json['date'] as String),
        isPayment: json['isPayment'] as bool? ?? false,
        juntadaId: json['juntadaId'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, description, amount, paidById, splitAmongIds, date, isPayment, juntadaId];
}
