class Payment {
  final String id;
  final String tenantId;
  final String month;
  final int amount;
  final String status;
  final String? paidDate;

  // join info
  final String? userEmail;
  final String? roomNumber;

  Payment({
    required this.id,
    required this.tenantId,
    required this.month,
    required this.amount,
    required this.status,
    this.paidDate,
    this.userEmail,
    this.roomNumber,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      tenantId: map['tenant_id'],
      month: map['month'],
      amount: map['amount'],
      status: map['status'],
      paidDate: map['paid_date'],
      userEmail: map['tenants']?['user_email'],
      roomNumber: map['tenants']?['rooms']?['number']?.toString(),
    );
  }
}
