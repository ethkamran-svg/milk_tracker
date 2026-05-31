import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/customer.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});
  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  List<Customer> all = [];
  List<Customer> filtered = [];
  final _searchCon = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    _searchCon.dispose();
    super.dispose();
  }

  Future<void> load() async {
    all = await DBHelper.instance.getAllCustomers();
    _filter(_searchCon.text);
  }

  void _filter(String q) {
    setState(() {
      filtered = q.isEmpty
          ? all
          : all
              .where((c) =>
                  c.name.toLowerCase().contains(q.toLowerCase()) ||
                  c.phone.contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddCustomerScreen()));
              load();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCon,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Search customer...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCon.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCon.clear();
                          _filter('');
                        })
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('👥',
                            style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        Text(
                          all.isEmpty
                              ? 'No customers yet!\nTap + to add'
                              : 'No results found',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      return Dismissible(
                        key: Key('cust_${c.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
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
                            title: const Text('Delete Customer?'),
                            content: Text(
                                'Delete ${c.name} and all records?'),
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
                              .deleteCustomer(c.id!);
                          load();
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 5),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  const Color(0xFF1565C0),
                              child: Text(
                                c.name[0].toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(c.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text('📱 ${c.phone}'),
                            trailing: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rs.${c.balance.toStringAsFixed(0)}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: c.balance > 0
                                          ? Colors.red
                                          : Colors.green),
                                ),
                                Text(
                                  c.balance > 0
                                      ? 'Due ❌'
                                      : 'Clear ✅',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: c.balance > 0
                                          ? Colors.red
                                          : Colors.green),
                                ),
                              ],
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CustomerDetailScreen(
                                          customerId: c.id!),
                                ),
                              );
                              load();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddCustomerScreen()));
          load();
        },
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
