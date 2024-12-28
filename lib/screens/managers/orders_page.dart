import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lapboost_admin_app/models/sql_service.dart';
import 'package:mysql1/mysql1.dart';

class OrdersPage extends StatefulWidget {
  final ResultRow user;

  OrdersPage({super.key, required this.user});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _employeesFuture;
  late Future<List<Map<String, dynamic>>> _currentOrdersFuture;
  late Future<List<Map<String, dynamic>>> _pastOrdersFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _employeesFuture = _fetchEmployees(); // Fetch employees on initialization
    _currentOrdersFuture = _fetchOrdersAndDetails(isCurrent: true);
    _pastOrdersFuture = _fetchOrdersAndDetails(isCurrent: false);
  }

  // Fetch employees from the database
  Future<List<Map<String, dynamic>>> _fetchEmployees() async {
    final conn = await SqlService.getConnection();
    try {
      final results = await conn
          .query('SELECT * FROM employees WHERE Role= ?', ['Technician']);
      return results
          .map((row) => {
                'id': row['Employee_ID'],
                'name':
                    '${row['Employee_FirstName']} ${row['Employee_LastName']}'
              })
          .toList();
    } catch (e) {
      print('Error fetching employees: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  // Fetch orders based on the selected status
  Future<List<Map<String, dynamic>>> _fetchOrdersAndDetails(
      {required bool isCurrent}) async {
    final conn = await SqlService.getConnection();
    try {
      final orders = await conn.query('''
        SELECT * FROM orders 
        WHERE Order_Status ${isCurrent ? '!= ?' : '= ?'}
      ''', ['Received']);

      List<Map<String, dynamic>> ordersWithDetails = [];

      for (var order in orders) {
        final orderDetails = await conn.query('''
          SELECT od.Order_ID, od.Order_Part_ID, od.Device_Serial_Number, 
                 op.Quantity, op.Part_ID, s.Service_Type, 
                 d.Device_Model, d.Device_Manufacturer,
                 stk.Part_Name, ord.Customer_ID, cus.email,
                 cus.Customer_FirstName, cus.Customer_LastName
          FROM order_details od
          LEFT JOIN ordered_parts op ON od.Order_Part_ID = op.Order_Part_ID
          LEFT JOIN services s ON od.Service_ID = s.Service_ID
          LEFT JOIN devices d ON od.Device_Serial_Number = d.Device_Serial_Number
          LEFT JOIN stock stk ON op.Part_ID = stk.Part_ID
          LEFT JOIN orders ord ON ord.Order_ID = od.Order_ID
          LEFT JOIN customers cus ON ord.Customer_ID = cus.Customer_ID
          WHERE od.Order_ID = ?
        ''', [order['Order_ID']]);
        print(orderDetails);

        ordersWithDetails.add({
          'order': order,
          'details': orderDetails.toList(),
        });
      }
      print(ordersWithDetails);
      return ordersWithDetails;
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  // Function to update order status
  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    try {
      final conn = await SqlService.getConnection();
      await conn.query('''
        UPDATE orders
        SET Order_Status = ? 
        WHERE Order_ID = ?
      ''', [newStatus, orderId]);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order status updated successfully!')),
      );
      setState(() {}); // Refresh UI after status change
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order status: $e')),
      );
    }
  }

  // Function to assign an employee to an order
  Future<void> _assignEmployeeToOrder(int orderId, int employeeId) async {
    try {
      final conn = await SqlService.getConnection();
      await conn.query('''
        UPDATE orders
        SET Employee_ID = ?
        WHERE Order_ID = ?
      ''', [employeeId, orderId]);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee assigned to the order!')),
      );
      setState(() {}); // Refresh UI after assignment
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error assigning employee: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // TabBar placed directly within the body
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Current Orders'),
                Tab(text: 'Past Orders'),
              ],
              indicatorColor:
                  Colors.blue, // Set the indicator color (highlight)
              labelColor: Colors.black, // Set the label color for selected tab
              unselectedLabelColor: Colors.grey,
            ),
          ),
          // TabBarView to switch between tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Current Orders
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _currentOrdersFuture,
                  builder: (context, snapshot) {
                    return _buildOrderList(snapshot);
                  },
                ),
                // Tab 2: Past Orders
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _pastOrdersFuture,
                  builder: (context, snapshot) {
                    return _buildOrderList(snapshot);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build the order list view
  Widget _buildOrderList(AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    final orders = snapshot.data ?? [];

    if (orders.isEmpty) {
      return const Center(child: Text('No orders found.'));
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index]['order'];
        final orderDetails = orders[index]['details'];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Card(
            elevation: 8,
            child: ExpansionTile(
              title: Text(
                'Order #${order['Order_ID']}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Received on ${DateFormat('MMMM dd, yyyy').format(order['Date_Received'])}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text('Customer Email: ${orderDetails[0]['email']}'),
                  Row(
                    children: [
                      Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: order['Order_Status'] == 'Scheduled'
                              ? Colors.blue
                              : (order['Order_Status'] == 'To Be Scheduled'
                                  ? Colors.orange
                                  : (order['Order_Status'] == 'Received'
                                      ? Colors.green
                                      : (order['Order_Status'] == 'Lost'
                                          ? Colors.red
                                          : Colors.grey))),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order['Order_Status'], // Directly display the status
                        style: TextStyle(
                          color: order['Order_Status'] == 'Scheduled'
                              ? Colors.blue
                              : (order['Order_Status'] == 'To Be Scheduled'
                                  ? Colors.orange
                                  : (order['Order_Status'] == 'Received'
                                      ? Colors.green
                                      : (order['Order_Status'] == 'Lost'
                                          ? Colors.red
                                          : Colors.grey))), // Default color
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              children: [
                for (var detail in orderDetails)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      child: detail['Service_Type'] != null
                          ? const Icon(Icons.design_services,
                              color: Colors.blue)
                          : const Icon(Icons.memory, color: Colors.orange),
                    ),
                    title: Text(
                      detail['Service_Type'] ?? '${detail['Part_Name']}',
                    ),
                    subtitle: Text(
                      detail['Service_Type'] != null
                          ? 'Device: ${detail['Device_Manufacturer']} ${detail['Device_Model']}, Serial No. ${detail['Device_Serial_Number']}'
                          : 'Part Name: ${detail['Part_Name']}, Quantity: ${detail['Quantity']}',
                    ),
                    trailing: Text(
                      detail['Service_Type'] != null ? 'Service' : 'Part',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                // Add the dropdown to change the status here
                ListTile(
                  title: DropdownButton<String>(
                    value: order['Order_Status'],
                    items: ['Received', 'Scheduled', 'To Be Scheduled', 'Lost']
                        .map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (newStatus) async {
                      if (newStatus != null) {
                        // Update order status
                        await _updateOrderStatus(order['Order_ID'], newStatus);

                        // Re-fetch the orders and refresh the Future
                        setState(() {
                          _currentOrdersFuture =
                              _fetchOrdersAndDetails(isCurrent: true);
                          _pastOrdersFuture =
                              _fetchOrdersAndDetails(isCurrent: false);
                        });
                      }
                    },
                  ),
                ),
                order['Order_Status'] != 'Received'
                    ? FutureBuilder<List<Map<String, dynamic>>>(
                        future: _employeesFuture,
                        builder: (context, employeeSnapshot) {
                          if (employeeSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (employeeSnapshot.hasError) {
                            return Center(
                                child: Text(
                                    'Error fetching employees: ${employeeSnapshot.error}'));
                          }

                          final employees = employeeSnapshot.data ?? [];

                          return ListTile(
                            title: Expanded(
                              child: DropdownButton<int>(
                                value: order[
                                    'Employee_ID'], // The employee assigned to the order (if any)
                                hint: const Text('Assign Employee'),
                                items: employees.map((employee) {
                                  return DropdownMenuItem<int>(
                                    value: employee['id'],
                                    child: Text(employee['name']),
                                  );
                                }).toList(),
                                onChanged: (newEmployeeId) async {
                                  if (newEmployeeId != null) {
                                    // Assign employee to the order
                                    await _assignEmployeeToOrder(
                                        order['Order_ID'], newEmployeeId);

                                    // After assigning, refresh the orders and employees data
                                    setState(() {
                                      // Refresh the current orders and employees to reflect the updated state
                                      _currentOrdersFuture =
                                          _fetchOrdersAndDetails(
                                              isCurrent: true);
                                      _pastOrdersFuture =
                                          _fetchOrdersAndDetails(
                                              isCurrent: false);
                                      _employeesFuture = _fetchEmployees();
                                    });
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      )
                    : Container(),
              ],
            ),
          ),
        );
      },
    );
  }
}
