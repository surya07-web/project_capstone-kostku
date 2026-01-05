class Room {
  final String id;
  final String number;
  final String type;
  final int price;
  final String facilities;
  final String status;
  final String? photoUrl;

  Room({
    required this.id,
    required this.number,
    required this.type,
    required this.price,
    required this.facilities,
    required this.status,
    this.photoUrl,
  });

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'],
      number: map['number'],
      type: map['type'],
      price: map['price'],
      facilities: map['facilities'],
      status: map['status'],
      photoUrl: map['photo_url'],
    );
  }
}
