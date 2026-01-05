class Tenant {
  final String? id;
  final String? userId;
  final String? userEmail;

  final String? roomId;
  final String? roomNumber;

  final DateTime? checkInDate;
  final DateTime? checkOutDate;

  // 🔹 Emergency Contact
  final String? emergencyName;
  final String? emergencyPhone;

  // 🔹 KTP
  final String? ktpUrl;
  final String? ktpStatus;
  final bool? ktpVerified;

  Tenant({
    this.id,
    this.userId,
    this.userEmail,
    this.roomId,
    this.roomNumber,
    this.checkInDate,
    this.checkOutDate,
    this.emergencyName,
    this.emergencyPhone,
    this.ktpUrl,
    this.ktpStatus,
    this.ktpVerified,
  });

  factory Tenant.fromMap(Map<String, dynamic> map) {
    return Tenant(
      id: map['id'],
      userId: map['user_id'],
      userEmail: map['user_email'],

      roomId: map['room_id'],
      roomNumber: map['rooms']?['number'],

      checkInDate: map['check_in_date'] != null
          ? DateTime.parse(map['check_in_date'])
          : null,
      checkOutDate: map['check_out_date'] != null
          ? DateTime.parse(map['check_out_date'])
          : null,

      // 🔹 Emergency
      emergencyName: map['emergency_name'],
      emergencyPhone: map['emergency_phone'],

      // 🔹 KTP
      ktpUrl: map['ktp_url'],
      ktpStatus: map['ktp_status'],
      ktpVerified: map['ktp_verified'],
    );
  }
}
