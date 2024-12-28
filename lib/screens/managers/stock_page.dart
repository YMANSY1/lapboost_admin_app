import 'package:flutter/material.dart';
import 'package:lapboost_admin_app/models/sql_service.dart';
import 'package:lapboost_admin_app/screens/managers/supplier_page.dart';
import 'package:mysql1/mysql1.dart';

class StockPage extends StatefulWidget {
  ResultRow user;
  StockPage({super.key, required this.user});

  @override
  State<StockPage> createState() => _StockPageState();
}

List<String> categories = [
  'All',
  'Battery',
  'Charger',
  'Screen',
  'Keyboard',
  'Cooling System',
  'RAM',
  'Storage',
  'Motherboard',
  'Input Device',
  'Accessory',
  'Audio',
  'Structural',
  'Networking',
  'Graphics',
  'Lighting',
  'Tool',
];

List<ResultRow> getFilteredstock(List<ResultRow> stock) {
  // Filter by search query
  var filteredStock = stock.where((item) {
    var partName = item['Part_Name']?.toLowerCase() ?? '';
    return partName.contains(searchQuery.toLowerCase());
  }).toList();

  // Further filter by selected category
  if (selectedCategory != null &&
      selectedCategory!.isNotEmpty &&
      selectedCategory != 'All') {
    filteredStock = filteredStock
        .where((item) => item['Category'] == selectedCategory)
        .toList();
  }

  return filteredStock;
}

String? selectedCategory;
String searchQuery = '';

class _StockPageState extends State<StockPage>
    with SingleTickerProviderStateMixin {
  late Results stock;
  late Results suppliers;
  List<ResultRow> suppliersList = <ResultRow>[];
  List<ResultRow> stockList = <ResultRow>[];
  bool isLoading = true; // Track loading state
  late TabController _tabController; // Tab controller

  Future<void> _fetchStockAndSuppliers() async {
    final conn = await SqlService.getConnection();
    stock = await conn.query('''SELECT * FROM stock''');
    suppliers = await conn.query('''SELECT * FROM suppliers''');
    for (var item in stock) {
      stockList.add(item);
    }
    for (var item in suppliers) {
      suppliersList.add(item);
    }
    setState(() {
      isLoading = false; // Set loading to false once data is fetched
    });
    print(stockList.length);
    print(suppliersList.length);
  }

// Function to get supplier by ID
  ResultRow? getSupplier(List<ResultRow> suppliers, int id) {
    for (var supplier in suppliers) {
      if (supplier['Supplier_ID'] == id) {
        print(supplier);
        return supplier;
      }
    }
    return null;
  }

// Dialog for editing item details
  Widget editItemDialog(ResultRow? item, List<ResultRow> suppliers) {
    final supplier = getSupplier(suppliers, item?['Supplier_ID'] ?? 0);
    // Create controllers for each TextField
    final partNameController = TextEditingController(text: item?['Part_Name']);
    final categoryController = TextEditingController(text: item?['Category']);
    final costPriceController =
        TextEditingController(text: item?['Cost_Price'].toString());
    final marketPriceController =
        TextEditingController(text: item?['Market_Price'].toString());
    final dateBoughtController =
        TextEditingController(text: '${item?['Date_Bought'] ?? ''}');
    final quantityController =
        TextEditingController(text: item?['Quantity_in_Stock'].toString());
    final conditionController =
        TextEditingController(text: item?['Item_Condition']);
    final imageLinkController =
        TextEditingController(text: item?['image_link']);

    final supplierController =
        TextEditingController(text: supplier?['Supplier_Name']);

    final isNew = item == null;

    // Variable to store the selected supplier
    ResultRow? selectedSupplier;

    return AlertDialog(
      title: Text('${item?['Part_Name'] ?? 'Add Item'}'),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Part Name Field
            TextField(
              controller: partNameController,
              decoration: InputDecoration(
                labelText: 'Part Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Category Field
            TextField(
              controller: categoryController,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Cost Price and Market Price Fields
            Row(
              children: [
                Flexible(
                  child: TextField(
                    controller: costPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Cost Price',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: TextField(
                    controller: marketPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Market Price',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date Bought and Quantity Fields
            Row(
              children: [
                Flexible(
                  child: TextField(
                    controller: dateBoughtController,
                    decoration: InputDecoration(
                      labelText: 'Date Bought',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onTap: () async {
                      FocusScope.of(context).requestFocus(FocusNode());
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        dateBoughtController.text =
                            '${pickedDate.toLocal()}'.split(' ')[0];
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Supplier Field (TextField with Autocomplete)
            Autocomplete<ResultRow>(
              initialValue: TextEditingValue(text: supplierController.text),
              onSelected: (ResultRow selected) {
                // When the user selects a supplier
                selectedSupplier = selected;
                supplierController.text = selected['Supplier_Name'];
              },
              optionsBuilder: (TextEditingValue textEditingValue) {
                // Filter suppliers based on user input
                return suppliers.where((supplier) {
                  return supplier['Supplier_Name']
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                }).toList();
              },
              displayStringForOption: (ResultRow option) {
                return option['Supplier_Name'];
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: InputDecoration(
                    labelText: 'Supplier',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Condition Field (Dropdown)
            TextField(
              controller: conditionController,
              decoration: InputDecoration(
                labelText: 'Condition',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Image Link Field
            TextField(
              controller: imageLinkController,
              decoration: InputDecoration(
                labelText: 'Image Link',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Get updated values from the controllers
                  String partName = partNameController.text.trim();
                  String category = categoryController.text.trim();
                  double costPrice =
                      double.tryParse(costPriceController.text.trim()) ?? 0.0;
                  double marketPrice =
                      double.tryParse(marketPriceController.text.trim()) ?? 0.0;
                  String dateBought = dateBoughtController.text.trim();
                  int quantity =
                      int.tryParse(quantityController.text.trim()) ?? 0;
                  String condition = conditionController.text.trim();
                  String imageLink = imageLinkController.text.trim();
                  String supplierName = supplierController.text.trim();

                  // Validate the condition field
                  if (condition != 'Used' && condition != 'New') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Condition must either be New or Used')),
                    );
                    return; // Exit if validation fails
                  }

                  // Get the Supplier ID based on the selected supplier name
                  ResultRow? selected = suppliers.firstWhere(
                    (sup) => sup['Supplier_Name'] == supplierName,
                  );
                  int? supplierId = selected?['Supplier_ID'];

                  if (supplierId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Invalid supplier selected')),
                    );
                    return;
                  }

                  // Update the stock item in the database
                  if (!isNew) {
                    try {
                      final conn = await SqlService.getConnection();

                      // SQL Update query to update the stock item
                      var result = await conn.query(
                        '''
                      UPDATE stock
                      SET Part_Name = ?, Category = ?, Cost_Price = ?, Market_Price = ?, 
                          Date_Bought = ?, Quantity_in_Stock = ?, Item_Condition = ?, 
                          image_link = ?, Supplier_ID = ?
                      WHERE Part_ID = ?
                    ''',
                        [
                          partName,
                          category,
                          costPrice,
                          marketPrice,
                          dateBought,
                          quantity,
                          condition,
                          imageLink,
                          supplierId,
                          item?[
                              'Part_ID'], // Assuming 'Part_ID' is the unique identifier
                        ],
                      );

                      if (result.affectedRows != null &&
                          result.affectedRows! > 0) {
                        // Show success message and update the local list
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Item updated successfully')),
                        );
                        Navigator.pop(context); // Close the dialog
                      } else {
                        // If no rows were affected, show an error
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Update failed')),
                        );
                      }
                    } catch (e) {
                      // Handle any errors
                      print(e);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error updating item')),
                      );
                    }
                  } else {
                    // Insert new stock item
                    final conn = await SqlService.getConnection();
                    await conn.query('''
                    INSERT INTO stock (
                      Part_Name,
                      Category,
                      Cost_Price,
                      Market_Price,
                      Date_Bought,
                      Quantity_in_Stock,
                      Item_Condition,
                      image_link,
                      Supplier_ID
                    ) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                  ''', [
                      partNameController.text,
                      categoryController.text,
                      double.parse(costPriceController.text),
                      double.parse(marketPriceController.text),
                      dateBoughtController.text,
                      int.parse(quantityController.text),
                      conditionController.text,
                      imageLinkController.text,
                      supplierId, // Use Supplier_ID instead of the name
                    ]);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Item added successfully')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this); // Initialize TabController
    _fetchStockAndSuppliers();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar for switching between Inventory and Supplier tabs
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Inventory'),
            Tab(text: 'Suppliers'),
          ],
        ),
        // TabBarView to show the content for each tab
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Inventory Tab Content
              isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator()) // Show loading indicator
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      searchQuery =
                                          value; // Update search query
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Search',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.filter_list),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Select Category'),
                                        content: DropdownButton<String>(
                                          isExpanded: true,
                                          value: selectedCategory,
                                          hint: const Text('Select a category'),
                                          items: categories.map((category) {
                                            return DropdownMenuItem<String>(
                                              value: category,
                                              child: Text(category),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              selectedCategory = value;
                                            });
                                            Navigator.pop(
                                                context); // Close the dialog
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (context) =>
                                      editItemDialog(null, suppliersList));
                            },
                            child: const Icon(
                              Icons.add,
                              color: Colors.lightBlueAccent,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            // Use the length of the filtered stock list
                            itemCount: getFilteredstock(stockList).length,
                            addAutomaticKeepAlives: false,
                            itemBuilder: (BuildContext context, int index) {
                              var stock = getFilteredstock(
                                  stockList); // Get filtered stock
                              final item =
                                  stock[index]; // Use the filtered stock list
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(item['image_link'] ?? ''),
                                ),
                                title: Text(item['Part_Name'] ?? 'Unknown'),
                                subtitle: Text(
                                    item['Quantity_in_Stock'].toString() ??
                                        '0'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return editItemDialog(
                                                  item, suppliersList);
                                            });
                                      },
                                      icon: const Icon(Icons.edit),
                                      color: Colors.blue,
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        final conn =
                                            await SqlService.getConnection();
                                        await conn.query('''
                                        DELETE FROM stock
                                        WHERE Part_ID= ?
                                        ''', [item['Part_ID']]);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Item deleted successfully')));
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
              SupplierPage()
              // Supplier Tab Content (Placeholder for now)
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: ListView.builder(
              //     // Use the length of the filtered stock list
              //     itemCount: suppliersList.length,
              //     addAutomaticKeepAlives: false,
              //     itemBuilder: (BuildContext context, int index) {
              //       final supplier =
              //           suppliersList[index]; // Use the filtered stock list
              //       return ListTile(
              //         title: Text(supplier['Supplier_Name'] ?? 'Unknown'),
              //         subtitle: Text(supplier['Location'].toString()),
              //         trailing: Row(
              //           mainAxisSize: MainAxisSize.min,
              //           children: [
              //             IconButton(
              //               onPressed: () {},
              //               icon: const Icon(Icons.edit),
              //               color: Colors.blue,
              //             ),
              //             IconButton(
              //               onPressed: () {},
              //               icon: const Icon(Icons.delete),
              //               color: Colors.red,
              //             ),
              //           ],
              //         ),
              //       );
              //     },
              //   ),
              // ),
            ],
          ),
        ),
      ],
    );
  }
}
