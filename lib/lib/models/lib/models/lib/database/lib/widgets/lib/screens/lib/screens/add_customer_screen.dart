import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/customer.dart';

class AddCustomerScreen extends StatefulWidget {
  final Customer? customer;
  const AddCustomerScreen({super.key, this.customer});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCon = TextEditingController();
  final _phoneCon = TextEditingController();
  final _addressCon = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameCon.text = widget.customer!.name;
      _phoneCon.text = widget.customer!.phone;
      _addressCon.text = widget.customer!.address;
    }
  }

  @override
  void dispose() {
    _nameCon.dispose();
    _phoneCon.dispose();
    _addressCon.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final c = Customer(
      id: widget.customer?.id,
      name: _nameCon.text.trim(),
      phone: _phoneCon.text.trim(),
      address: _addressCon.text.trim(),
    );
    if (widget.customer == null) {
      await DBHelper.instance.addCustomer(c);
    } else {
      await DBHelper.instance.updateCustomer(c);
    }
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.customer == null
            ? '✅ Customer added!'
            : '✅ Customer updated!'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              widget.customer == null ? 'Add Customer' : 'Edit Customer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 8),
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF1565C0),
                child:
                    Icon(Icons.person, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCon,
                decoration: const InputDecoration(
                    labelText: 'Customer Name *',
                    prefixIcon: Icon(Icons.person_outline)),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCon,
                decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Phone is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressCon,
                decoration: const InputDecoration(
                    labelText: 'Address (Optional)',
                    prefixIcon: Icon(Icons.location_on_outlined)),
                maxLines: 2,
              ),
              const SizedBox(height: 28),
              _saving
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('SAVE CUSTOMER',
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
