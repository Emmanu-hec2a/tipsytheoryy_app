import 'product_model.dart';

class ShirikiSessionModel {
  final String inviteCode;
  final String status;
  final String hostName;
  final int hostId;
  final double totalAmount;
  final double amountCollected;
  final List<ShirikiContributionModel> contributions;
  final DateTime createdAt;
  final DateTime expiresAt;
  final dynamic orderDetails;

  ShirikiSessionModel({
    required this.inviteCode,
    required this.status,
    required this.hostName,
    required this.hostId,
    required this.totalAmount,
    required this.amountCollected,
    required this.contributions,
    required this.createdAt,
    required this.expiresAt,
    this.orderDetails,
  });

  factory ShirikiSessionModel.fromJson(Map<String, dynamic> json) {
    return ShirikiSessionModel(
      inviteCode: json['invite_code'],
      status: json['status'],
      hostName: json['host_name'],
      hostId: json['host_id'],
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      amountCollected: double.tryParse(json['amount_collected'].toString()) ?? 0.0,
      contributions: (json['contributions'] as List)
          .map((i) => ShirikiContributionModel.fromJson(i))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      orderDetails: json['order_details'],
    );
  }

  double get progress => totalAmount > 0 ? amountCollected / totalAmount : 0.0;
  double get remainingAmount => totalAmount - amountCollected;
}

class ShirikiContributionModel {
  final int id;
  final String username;
  final double amount;
  final String status;
  final DateTime? paidAt;
  final DateTime createdAt;

  ShirikiContributionModel({
    required this.id,
    required this.username,
    required this.amount,
    required this.status,
    this.paidAt,
    required this.createdAt,
  });

  factory ShirikiContributionModel.fromJson(Map<String, dynamic> json) {
    return ShirikiContributionModel(
      id: json['id'],
      username: json['username'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      status: json['status'],
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
