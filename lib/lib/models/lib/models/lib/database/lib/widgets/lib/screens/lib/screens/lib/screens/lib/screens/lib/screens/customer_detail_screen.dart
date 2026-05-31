import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/db_helper.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import 'add_customer_screen.dart';
import 'payment_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;
  const CustomerDetailScreen({super.key, required this.customerId});
  @override
  State<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState
    extends State<CustomerDetailScreen> {
  Customer? customer;
  List<Sale> sales = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    customer =
        await DBHelper.instance.getCustomer(widget.customerId);
    sales = await DBHelper.instance
        .getSalesByCustomer(widget.customerId);
    setState(() => isLoading = false);
  }

  Future<void> _shareStatement() async {
    final msg = await DBHelper.instance
        .getCustomerStatement(widget.customerId);
    await Share.share(msg,
        subject: 'Milk Shop Statement - ${customer?.name}');
  }

  Future<void> _sendWhatsApp() async {
    final msg = await DBHelper.instance
        .getCustomerStatement(widget.customerId);
    String phone =
        customer!.phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!phone.startsWith('91')) phone = '91$phone';
    final url =
        'https://wa.me/$phone?text=${Uri.encodeComponent(msg)}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri,
          mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('WhatsApp not found!')));
      }
    }
  }

  Future<void> _sendSMS() async {
    final msg = await DBHelper.instance
        .getCustomerStatement(widget.customerId);
    final uri = Uri(
        scheme: 'sms',
        path: customer!.phone,
        queryParameters: {'body': msg});
    if (await canLaunchUrl(uri)) await launchUrl(uri);
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
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color)),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10)),
    );
  }

  Widget _balBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Column(children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: color)),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (customer == null) {
      return const Scaffold(
          body: Center(child: Text('Customer not found!')));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(customer!.name),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AddCustomerScreen(
                            customer: customer)));
                loadData();
              }),
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: loadData),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info Card ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF1565C0),
                        child: Text(
                          customer!.name[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(customer!.name,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            Text('📱 ${customer!.phone}'),
                            if (customer!.address.isNotEmpty)
                              Text('📍 ${customer!.address}'),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      _balBox('Total Bill',
                          'Rs.${customer!.totalBill.toStringAsFixed(0)}',
                          Colors.blue),
                      const SizedBox(width: 8),
                      _balBox('Paid',
                          'Rs.${customer!.totalPaid.toStringAsFixed(0)}',
                          Colors.green),
                      const SizedBox(width: 8),
                      _balBox(
                          'Due',
                          'Rs.${customer!.balance.toStringAsFixed(0)}',
                          customer!.balance > 0
                              ? Colors.red
                              : Colors.green),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Action Buttons ──
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PaymentScreen(
                            customerId: widget.customerId)));
                loadData();
              },
              icon: const Icon(Icons.payment),
              label: const Text('RECORD PAYMENT'),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sendWhatsApp,
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      minimumSize: const Size(0, 44)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sendSMS,
                  icon: const Icon(Icons.sms, size: 18),
                  label: const Text('SMS'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: const Size(0, 44)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareStatement,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      minimumSize: const Size(0, 44)),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Sale History ──
            Text('📋 Sale History (${sales.length})',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0))),
            const SizedBox(height: 8),
            sales.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('No sales yet.',
                        style: TextStyle(
                            color: Colors.grey.shade600)))
                : Column(
                    children: sales.map((s) {
                      return Dismissible(
                        key: Key('sal_${s.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding:
                              const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius:
                                  BorderRadius.circular(12)),
                          child: const Icon(Icons.delete,
                              color: Colors.white),
                        ),
                        confirmDismiss: (_) => showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Sale?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel')),
                              ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  child: const Text('Delete')),
                            ],
                          ),
                        ),
                        onDismissed: (_) async {
                          await DBHelper.instance
                              .deleteSale(s.id!);
                          loadData();
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(children: [
                              Text(
                                s.milkType == 'Cow'
                                    ? '🐄'
                                    : s.milkType == 'Buffalo'
                                        ? '🐃'
                                        : '🥛',
                                style: const TextStyle(
                                    fontSize: 24),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(s.saleDate,
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.bold)),
                                    Text(
                                        '${s.milkType} | ${s.quantity.toStringAsFixed(1)}L × Rs.${s.price.toStringAsFixed(0)}',
                                        style: TextStyle(
                                            color: Colors
                                                .grey.shade600,
                                            fontSize: 13)),
                                    if (s.status == 'PARTIAL')
                                      Text(
                                          'Paid: Rs.${s.paid.toStringAsFixed(0)} | Due: Rs.${s.due.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              color: Colors.orange,
                                              fontSize: 12)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      'Rs.${s.total.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 16)),
                                  const SizedBox(height: 4),
                                  _statusBadge(s.status),
                                ],
                              ),
                            ]),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 8),
            Center(
                child: Text('⬆️ Swipe left to delete',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12))),
          ],
        ),
      ),
    );
  }
}
