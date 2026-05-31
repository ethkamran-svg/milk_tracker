class Customer {
  int? id;
  String name;
  String phone;
  String address;
  double totalBill;
  double totalPaid;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.address = '',
    this.totalBill = 0,
    this.totalPaid = 0,
  });

  double get balance => totalBill - totalPaid;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
      };

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
        id: m['id'],
        name: m['name'],
        phone: m['phone'],
        address: m['address'] ?? '',
        totalBill: (m['total_bill'] ?? 0).toDouble(),
        totalPaid: (m['total_paid'] ?? 0).toDouble(),
      );
}
