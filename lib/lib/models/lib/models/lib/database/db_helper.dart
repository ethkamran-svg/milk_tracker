import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../models/sale.dart';

class DBHelper {
  static Database? _db;
  static final DBHelper instance = DBHelper._();
  DBHelper._();

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'milk_shop.db');
    return openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('''CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT)''');
      await db.execute('''CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        sale_date TEXT,
        milk_type TEXT,
        quantity REAL,
        price REAL,
        total REAL,
        paid REAL,
        status TEXT)''');
      await db.execute('''CREATE TABLE payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        amount REAL,
        pay_date TEXT)''');
    });
  }

  // ── CUSTOMER ──
  Future<int> addCustomer(Customer c) async {
    final db = await database;
    return db.insert('customers', c.toMap()..remove('id'));
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT c.*,
        COALESCE(SUM(s.total),0) as total_bill,
        COALESCE(SUM(s.paid),0)+COALESCE(
          (SELECT SUM(p.amount) FROM payments p WHERE p.customer_id=c.id),0
        ) as total_paid
      FROM customers c
      LEFT JOIN sales s ON c.id=s.customer_id
      GROUP BY c.id ORDER BY c.name''');
    return rows.map((r) => Customer.fromMap(r)).toList();
  }

  Future<Customer?> getCustomer(int id) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT c.*,
        COALESCE(SUM(s.total),0) as total_bill,
        COALESCE(SUM(s.paid),0)+COALESCE(
          (SELECT SUM(p.amount) FROM payments p WHERE p.customer_id=c.id),0
        ) as total_paid
      FROM customers c
      LEFT JOIN sales s ON c.id=s.customer_id
      WHERE c.id=?''', [id]);
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  Future<void> deleteCustomer(int id) async {
    final db = await database;
    await db.delete('sales', where: 'customer_id=?', whereArgs: [id]);
    await db.delete('payments', where: 'customer_id=?', whereArgs: [id]);
    await db.delete('customers', where: 'id=?', whereArgs: [id]);
  }

  Future<int> updateCustomer(Customer c) async {
    final db = await database;
    return db.update('customers', c.toMap(),
        where: 'id=?', whereArgs: [c.id]);
  }

  // ── SALE ──
  Future<int> addSale(Sale s) async {
    final db = await database;
    return db.insert('sales', s.toMap()..remove('id'));
  }

  Future<List<Sale>> getSalesByCustomer(int custId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT s.*, c.name as cust_name
      FROM sales s JOIN customers c ON s.customer_id=c.id
      WHERE s.customer_id=? ORDER BY s.sale_date DESC''', [custId]);
    return rows.map((r) => Sale.fromMap(r)).toList();
  }

  Future<List<Sale>> getTodaySales() async {
    final db = await database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final rows = await db.rawQuery('''
      SELECT s.*, c.name as cust_name
      FROM sales s JOIN customers c ON s.customer_id=c.id
      WHERE s.sale_date LIKE ? ORDER BY s.sale_date DESC''', ['$today%']);
    return rows.map((r) => Sale.fromMap(r)).toList();
  }

  Future<List<Sale>> getSalesByDate(String date) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT s.*, c.name as cust_name
      FROM sales s JOIN customers c ON s.customer_id=c.id
      WHERE s.sale_date LIKE ? ORDER BY s.sale_date DESC''', ['$date%']);
    return rows.map((r) => Sale.fromMap(r)).toList();
  }

  Future<void> deleteSale(int id) async {
    final db = await database;
    await db.delete('sales', where: 'id=?', whereArgs: [id]);
  }

  // ── PAYMENT ──
  Future<int> addPayment(int custId, double amount) async {
    final db = await database;
    return db.insert('payments', {
      'customer_id': custId,
      'amount': amount,
      'pay_date': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
    });
  }

  // ── DASHBOARD ──
  Future<double> getTodayTotal() async {
    final db = await database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final r = await db.rawQuery(
        "SELECT COALESCE(SUM(total),0) as v FROM sales WHERE sale_date LIKE ?",
        ['$today%']);
    return (r.first['v'] as num).toDouble();
  }

  Future<double> getTodayLiters() async {
    final db = await database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final r = await db.rawQuery(
        "SELECT COALESCE(SUM(quantity),0) as v FROM sales WHERE sale_date LIKE ?",
        ['$today%']);
    return (r.first['v'] as num).toDouble();
  }

  Future<double> getTotalDue() async {
    final db = await database;
    final r = await db.rawQuery('''
      SELECT COALESCE(SUM(total),0)-COALESCE(SUM(paid),0)-
      COALESCE((SELECT SUM(amount) FROM payments),0) as v FROM sales''');
    return (r.first['v'] as num).toDouble();
  }

  Future<int> getTotalCustomers() async {
    final db = await database;
    final r =
        await db.rawQuery("SELECT COUNT(*) as v FROM customers");
    return (r.first['v'] as num).toInt();
  }

  // ── SHARE STATEMENT ──
  Future<String> getCustomerStatement(int custId) async {
    final customer = await getCustomer(custId);
    if (customer == null) return '';
    final sales = await getSalesByCustomer(custId);
    final sb = StringBuffer();
    sb.writeln('MILK SHOP - ACCOUNT STATEMENT');
    sb.writeln('=' * 32);
    sb.writeln('Customer : ${customer.name}');
    sb.writeln('Phone    : ${customer.phone}');
    if (customer.address.isNotEmpty) {
      sb.writeln('Address  : ${customer.address}');
    }
    sb.writeln('=' * 32);
    sb.writeln('SALE HISTORY:');
    sb.writeln();
    for (final s in sales) {
      final icon =
          s.status == 'PAID' ? '[PAID]' : s.status == 'PARTIAL' ? '[PARTIAL]' : '[DUE]';
      sb.writeln('$icon ${s.saleDate}');
      sb.writeln(
          '  ${s.milkType} | ${s.quantity.toStringAsFixed(1)}L x Rs.${s.price.toStringAsFixed(0)} = Rs.${s.total.toStringAsFixed(0)}');
      if (s.status == 'PARTIAL') {
        sb.writeln(
            '  Paid: Rs.${s.paid.toStringAsFixed(0)} | Due: Rs.${s.due.toStringAsFixed(0)}');
      }
      sb.writeln();
    }
    sb.writeln('=' * 32);
    sb.writeln('Total Bill : Rs.${customer.totalBill.toStringAsFixed(0)}');
    sb.writeln('Total Paid : Rs.${customer.totalPaid.toStringAsFixed(0)}');
    sb.writeln('Balance Due: Rs.${customer.balance.toStringAsFixed(0)}');
    sb.writeln('=' * 32);
    sb.writeln(customer.balance > 0
        ? 'Please clear your pending dues.'
        : 'All dues cleared. Thank you!');
    return sb.toString();
  }
}
