class PaymentAttemptModel {
  final String paymentId;
  final String status;
  final String? checkoutRequestId;
  final int? orderId;
  final String? orderNumber;
  final double amount;
  final int? nextPollAfterSeconds;
  final int? retryAfterSeconds;
  final String? failureMessage;

  const PaymentAttemptModel({
    required this.paymentId,
    required this.status,
    this.checkoutRequestId,
    this.orderId,
    this.orderNumber,
    required this.amount,
    this.nextPollAfterSeconds,
    this.retryAfterSeconds,
    this.failureMessage,
  });

  factory PaymentAttemptModel.fromJson(Map<String, dynamic> json) {
    return PaymentAttemptModel(
      paymentId: json['payment_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      checkoutRequestId: json['checkout_request_id']?.toString(),
      orderId: json['order_id'] is int
          ? json['order_id']
          : int.tryParse(json['order_id']?.toString() ?? ''),
      orderNumber: json['order_number']?.toString(),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      nextPollAfterSeconds: int.tryParse(
        json['next_poll_after_seconds']?.toString() ?? '',
      ),
      retryAfterSeconds: int.tryParse(
        json['retry_after_seconds']?.toString() ?? '',
      ),
      failureMessage: json['failure_message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'payment_id': paymentId,
    'status': status,
    'checkout_request_id': checkoutRequestId,
    'order_id': orderId,
    'order_number': orderNumber,
    'amount': amount,
    'next_poll_after_seconds': nextPollAfterSeconds,
    'retry_after_seconds': retryAfterSeconds,
    'failure_message': failureMessage,
  };
}
