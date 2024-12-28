import 'package:flutter/material.dart';
import 'package:lapboost_admin_app/models/sql_service.dart';
import 'package:mysql1/mysql1.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  late Results suppliers;
  List<ResultRow> suppliersList = <ResultRow>[];
  bool isLoading = true;

  Future<void> _fetchSuppliers() async {
    final conn = await SqlService.getConnection();
    suppliers = await conn.query('''SELECT * FROM suppliers''');
    suppliersList = suppliers.toList();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _deleteSupplier(int supplierId) async {
    final conn = await SqlService.getConnection();
    await conn.query(
      '''
      DELETE FROM suppliers
      WHERE Supplier_ID = ?
      ''',
      [supplierId],
    );
    await _fetchSuppliers();
  }

  Future<void> _addOrUpdateSupplier({
    int? supplierId,
    required String name,
    required String location,
    required String contactPhone,
  }) async {
    final conn = await SqlService.getConnection();
    if (supplierId == null) {
      await conn.query(
        '''
        INSERT INTO suppliers (Supplier_Name, Location, Contact_Phone)
        VALUES (?, ?, ?)
        ''',
        [name, location, contactPhone],
      );
    } else {
      await conn.query(
        '''
        UPDATE suppliers
        SET Supplier_Name = ?, Location = ?, Contact_Phone = ?
        WHERE Supplier_ID = ?
        ''',
        [name, location, contactPhone, supplierId],
      );
    }
    await _fetchSuppliers();
  }

  void _showSupplierDialog({
    int? supplierId,
    String? currentName,
    String? currentLocation,
    String? currentContactPhone,
  }) {
    final nameController = TextEditingController(text: currentName ?? '');
    final locationController =
        TextEditingController(text: currentLocation ?? '');
    final contactPhoneController =
        TextEditingController(text: currentContactPhone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(supplierId == null ? 'Add Supplier' : 'Edit Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Supplier Name'),
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            TextField(
              controller: contactPhoneController,
              decoration: const InputDecoration(labelText: 'Contact Phone'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final location = locationController.text.trim();
              final contactPhone = contactPhoneController.text.trim();

              if (name.isEmpty || location.isEmpty || contactPhone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All fields are required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              await _addOrUpdateSupplier(
                supplierId: supplierId,
                name: name,
                location: location,
                contactPhone: contactPhone,
              );

              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(supplierId == null
                      ? 'Supplier added'
                      : 'Supplier updated'),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    _fetchSuppliers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showSupplierDialog(),
                    child: const Icon(
                      Icons.add,
                      color: Colors.lightBlueAccent,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: suppliersList.length,
                    addAutomaticKeepAlives: false,
                    itemBuilder: (BuildContext context, int index) {
                      final supplier = suppliersList[index];
                      return ListTile(
                        title: Text(supplier['Supplier_Name'] ?? 'Unknown'),
                        subtitle: Text(
                            '${supplier['Location']} | Contact: ${supplier['Contact_Phone'] ?? 'None'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                _showSupplierDialog(
                                  supplierId: supplier['Supplier_ID'],
                                  currentName: supplier['Supplier_Name'],
                                  currentLocation: supplier['Location'],
                                  currentContactPhone:
                                      supplier['Contact_Phone'],
                                );
                              },
                              icon: const Icon(Icons.edit),
                              color: Colors.blue,
                            ),
                            IconButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Supplier'),
                                    content: const Text(
                                        'Are you sure you want to delete this supplier?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _deleteSupplier(
                                      supplier['Supplier_ID']);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Supplier deleted successfully'),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
  }
}
