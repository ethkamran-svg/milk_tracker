class Sale {
  int? id;
  int customerId;
  String customerName;
  String saleDate;
  String milkType;
  double quantity;
  double price;
  double total;
  double paid;
  String status;

  Sale({
    this.id,
    required this.customerId,
    this.customerName = '',
    required this.saleDate,
    required this.milkType,
    required this.quantity,
    required this.price,
    required this.total,
    required this.paid,
    required this.status,
  });

  double get due => total - paid;

  Map<String, dynamic> toMap() => {
        'id': id,
        'customer_id': customerId,
        'sale_date': saleDate,
        'milk_type': milkType,
        'quantity': quantity,
        'price': price,
        'total': total,
        'paid': paid,
        'status': status,
      };

  factory Sale.fromMap(Map<String, dynamic> m) => Sale(
        id: m['id'],
        customerId: m['customer_id'],
        customerName: m['cust_name'] ?? '',
        saleDate: m['sale_date'],
        milkType: m['milk_type'],
        quantity: (m['quantity']).toDouble(),
        price: (m['price']).toDouble(),
        total: (m['total']).toDouble(),
        paid: (m['paid']).toDouble(),
        status: m['status'],
      );
}
