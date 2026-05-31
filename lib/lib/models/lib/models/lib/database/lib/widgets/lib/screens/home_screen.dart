import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/sale.dart';
import '../widgets/summary_card.dart';
import 'add_sale_screen.dart';
import 'add_customer_screen.dart';
import 'customer_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = DBHelper.instance;
  double todayTotal = 0;
  double todayLiters = 0;
  double totalDue = 0;
  int totalCustomers = 0;
  List<Sale> todaySales = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    todayTotal = await db.getTodayTotal();
    todayLiters = await db.getTodayLiters();
    totalDue = await db.getTotalDue();
    totalCustomers = await db.getTotalCustomers();
    todaySales = await db.getTodaySales();
    setState(() => isLoading = false);
  }

  Widget _statusBadge(String status) {
    final color = status == 'PAID'
        ? Colors.green
        : status == 'PARTIAL'
            ? Colors.orange
            : Colors.red;
    final label = status == 'PAID'
        ? '✅ PAID'
        : status == 'PARTIAL'
            ? '🟡 PARTIAL'
            : '❌ DUE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Sale?'),
        content: const Text('This sale entry will be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
  }

  Widget _saleCard(Sale sale) {
    return Dismissible(
      key: Key('sale_${sale.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: Colors.red, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) async {
        await db.deleteSale(sale.id!);
        loadData();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    sale.milkType == 'Cow'
                        ? '🐄'
                        : sale.milkType == 'Buffalo'
                            ? '🐃'
                            : '🥛',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sale.customerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                        '${sale.milkType} | ${sale.quantity.toStringAsFixed(1)}L × Rs.${sale.price.toStringAsFixed(0)}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13)),
                    Text(sale.saleDate,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Rs.${sale.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1565C0))),
                  const SizedBox(height: 4),
                  _statusBadge(sale.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(Widget screen) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => screen));
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text('🥛 Milk Sale Tracker'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadData)
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Summary Cards ──
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            title: 'Today Sales',
                            value: 'Rs.${todayTotal.toStringAsFixed(0)}',
                            icon: Icons.currency_rupee,
                            color: const Color(0xFF1565C0),
                            bgColor: Colors.blue.shade50,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SummaryCard(
                            title: 'Liters',
                            value: '${todayLiters.toStringAsFixed(1)}L',
                            icon: Icons.water_drop,
                            color: Colors.teal,
                            bgColor: Colors.teal.shade50,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SummaryCard(
                            title: 'Total Due',
                            value: 'Rs.${totalDue.toStringAsFixed(0)}',
                            icon: Icons.warning_amber,
                            color: Colors.red,
                            bgColor: Colors.red.shade50,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SummaryCard(
                            title: 'Customers',
                            value: '$totalCustomers',
                            icon: Icons.people,
                            color: Colors.purple,
                            bgColor: Colors.purple.shade50,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Buttons ──
                    ElevatedButton.icon(
                      onPressed: () =>
                          _navigate(const AddSaleScreen()),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('NEW SALE ENTRY',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _navigate(const CustomerListScreen()),
                            icon: const Icon(Icons.people),
                            label: const Text('CUSTOMERS'),
                            style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 48)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _navigate(const AddCustomerScreen()),
                            icon: const Icon(Icons.person_add),
                            label: const Text('ADD CUSTOMER'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6F00),
                              minimumSize: const Size(0, 48),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ── Today Sales ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('📋 Today\'s Sales',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1565C0))),
                        Text('${todaySales.length} entries',
                            style:
                                TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    todaySales.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(32),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              children: [
                                const Text('🥛',
                                    style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 8),
                                Text(
                                    'No sales today!\nTap NEW SALE to add.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 15)),
                              ],
                            ),
                          )
                        : Column(
                            children: todaySales
                                .map((s) => _saleCard(s))
                                .toList()),
                    const SizedBox(height: 12),
                    Center(
                      child: Text('⬆️ Swipe left on sale to delete',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
