import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/customer.dart';

class PaymentScreen extends StatefulWidget {
  final int customerId;
  const PaymentScreen({super.key, required this.customerId});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _amtCon = TextEditingController();
  Customer? customer;

  @override
  void initState() {
    super.initState();
    DBHelper.instance.getCustomer(widget.customerId).then((c) {
      setState(() => customer = c);
    });
  }

  @override
  void dispose() {
    _amtCon.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amt = double.tryParse(_amtCon.text);
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter valid amount!')));
      return;
    }
    await DBHelper.instance.addPayment(widget.customerId, amt);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '✅ Payment Rs.${amt.toStringAsFixed(0)} recorded!'),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer != null) ...[
              Text('👤 ${customer!.name}',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.red.shade200)),
                child: Row(children: [
                  const Icon(Icons.warning_amber,
                      color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                      'Current Due: Rs.${customer!.balance.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
              const SizedBox(height: 32),
            ],
            const Text('Payment Amount (Rs.) *',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _amtCon,
              decoration: InputDecoration(
                hintText: 'Enter amount',
                prefixIcon: const Icon(Icons.currency_rupee),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [50, 100, 200, 500, 1000].map((amt) {
                return ActionChip(
                  label: Text('Rs.$amt'),
                  onPressed: () =>
                      _amtCon.text = amt.toString(),
                  backgroundColor:
                      const Color(0xFF1565C0).withOpacity(0.1),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_circle),
              label: const Text('SAVE PAYMENT',
                  style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
