import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/customer.dart';
import '../models/sale.dart';

class AddSaleScreen extends StatefulWidget {
  const AddSaleScreen({super.key});
  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCon = TextEditingController();
  final _priceCon = TextEditingController();
  final _paidCon = TextEditingController();
  List<Customer> customers = [];
  Customer? selectedCustomer;
  String milkType = 'Cow';
  double totalAmount = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _qtyCon.addListener(_calcTotal);
    _priceCon.addListener(_calcTotal);
  }

  @override
  void dispose() {
    _qtyCon.dispose();
    _priceCon.dispose();
    _paidCon.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    customers = await DBHelper.instance.getAllCustomers();
    setState(() {});
  }

  void _calcTotal() {
    final qty = double.tryParse(_qtyCon.text) ?? 0;
    final price = double.tryParse(_priceCon.text) ?? 0;
    setState(() => totalAmount = qty * price);
  }

  Future<void> _save() async {
    if (selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a customer!')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final qty = double.parse(_qtyCon.text);
    final price = double.parse(_priceCon.text);
    final total = qty * price;
    final paid = double.tryParse(_paidCon.text) ?? 0;
    final status =
        paid >= total ? 'PAID' : paid > 0 ? 'PARTIAL' : 'DUE';
    final sale = Sale(
      customerId: selectedCustomer!.id!,
      saleDate:
          DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      milkType: milkType,
      quantity: qty,
      price: price,
      total: total,
      paid: paid,
      status: status,
    );
    await DBHelper.instance.addSale(sale);
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Sale saved!'),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Sale Entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Customer *',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<Customer>(
                value: selectedCustomer,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.person)),
                hint: const Text('-- Select Customer --'),
                items: customers
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.name} (${c.phone})')))
                    .toList(),
                onChanged: (c) => setState(() => selectedCustomer = c),
              ),
              const SizedBox(height: 16),
              const Text('Milk Type *',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: ['Cow', 'Buffalo', 'Mixed'].map((type) {
                  final icon = type == 'Cow'
                      ? '🐄'
                      : type == 'Buffalo'
                          ? '🐃'
                          : '🥛';
                  return Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => milkType = type),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: milkType == type
                                ? const Color(0xFF1565C0)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Column(children: [
                            Text(icon,
                                style: const TextStyle(fontSize: 22)),
                            Text(type,
                                style: TextStyle(
                                    color: milkType == type
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ]),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qtyCon,
                decoration: const InputDecoration(
                    labelText: 'Quantity (Liters) *',
                    hintText: 'e.g. 2.5',
                    prefixIcon: Icon(Icons.water_drop),
                    suffixText: 'L'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Enter quantity' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceCon,
                decoration: const InputDecoration(
                    labelText: 'Price per Liter *',
                    hintText: 'e.g. 60',
                    prefixIcon: Icon(Icons.currency_rupee),
                    suffixText: 'Rs./L'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Enter price' : null,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: const Color(0xFF1565C0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text('Rs. ${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _paidCon,
                decoration: const InputDecoration(
                    labelText: 'Paid Amount (0 = Due)',
                    hintText: '0',
                    prefixIcon: Icon(Icons.payments_outlined),
                    prefixText: 'Rs. '),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 28),
              _saving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('SAVE SALE',
                          style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
