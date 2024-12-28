import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lapboost_admin_app/models/sql_service.dart';
import 'package:mysql1/mysql1.dart';

class AssignedJobsPage extends StatefulWidget {
  final ResultRow user;

  AssignedJobsPage({super.key, required this.user});

  @override
  State<AssignedJobsPage> createState() => _AssignedJobsPageState();
}

class _AssignedJobsPageState extends State<AssignedJobsPage> {
  Future<List<Map<String, dynamic>>> _fetchAssignedJobs() async {
    final conn = await SqlService.getConnection();
    try {
      // Fetch all orders for the technician (employee)
      final orders = await conn.query(
          '''SELECT * FROM orders WHERE Employee_ID = ?''',
          [widget.user['Employee_ID']]);

      List<Map<String, dynamic>> ordersWithDetails = [];

      // For each order, fetch its details
      for (var order in orders) {
        final orderDetails = await conn.query(
            '''SELECT od.Order_ID, od.Order_Part_ID, od.Device_Serial_Number, 
                                                       op.Quantity, op.Part_ID, s.Service_Type, 
                                                       d.Device_Model, d.Device_Manufacturer,
                                                       stk.Part_Name
                                              FROM order_details od
                                              LEFT JOIN ordered_parts op ON od.Order_Part_ID = op.Order_Part_ID
                                              LEFT JOIN services s ON od.Service_ID = s.Service_ID
                                              LEFT JOIN devices d ON od.Device_Serial_Number = d.Device_Serial_Number
                                              LEFT JOIN stock stk ON op.Part_ID = stk.Part_ID
                                              WHERE od.Order_ID = ?''',
            [order['Order_ID']]);

        ordersWithDetails.add({
          'order': order,
          'details': orderDetails.toList(),
        });
      }

      return ordersWithDetails;
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  // Method to update the order status
  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    try {
      final conn = await SqlService.getConnection();
      String dateDelivered = newStatus == 'Received'
          ? ', Date_Delivered= "${DateFormat('yyyy-MM-dd').format(DateTime.now())}"'
          : '';

      await conn.query('''UPDATE orders 
        SET Order_Status = ? $dateDelivered
        WHERE Order_ID = ?''', [newStatus, orderId]);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order status updated successfully!')));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAssignedJobs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          // Filter out orders with the status 'Received'
          final filteredOrders = orders
              .where((order) => order['order']['Order_Status'] != 'Received')
              .toList();

          if (filteredOrders.isEmpty) {
            return const Center(child: Text('No assigned jobs.'));
          }

          return ListView.builder(
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final order = filteredOrders[index]['order'];
              final orderDetails = filteredOrders[index]['details'];

              String orderStatus = order['Order_Status'];
              String buttonText = '';
              String nextStatus = '';
              Color buttonColor = Colors.grey;

              // Set up button text, next status, and button color based on the current status
              switch (orderStatus) {
                case 'To Be Scheduled':
                  buttonText = 'Work Started on Job';
                  nextStatus = 'Scheduled';
                  buttonColor = Colors.orange;
                  break;
                case 'Scheduled':
                  buttonText = 'Send for Delivery';
                  nextStatus = 'Received';
                  buttonColor = Colors.blue;
                  break;
                case 'Received':
                  buttonText = 'Completed';
                  nextStatus = 'Received';
                  buttonColor = Colors.green;
                  break;
                default:
                  buttonText = 'To Be Scheduled';
                  nextStatus = 'Scheduled';
                  buttonColor = Colors.green;
              }

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Card(
                  elevation: 8,
                  child: ExpansionTile(
                    title: Text(
                      'Order #${order['Order_ID']}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Received on ${DateFormat('MMMM dd, yyyy').format(order['Date_Received'])}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Status: $orderStatus',
                          style: TextStyle(fontSize: 14, color: buttonColor),
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
                                : const Icon(Icons.memory,
                                    color: Colors.orange),
                          ),
                          title: Text(detail['Service_Type'] ??
                              '${detail['Part_Name']}'),
                          subtitle: Text(
                            detail['Service_Type'] != null
                                ? 'Device: ${detail['Device_Manufacturer']} ${detail['Device_Model']}, Serial No. ${detail['Device_Serial_Number']}'
                                : 'Part Name: ${detail['Part_Name']}, Quantity: ${detail['Quantity']}',
                          ),
                          trailing: Text(
                              detail['Service_Type'] != null
                                  ? 'Service'
                                  : 'Part',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${order['Total_Amount']} EGP',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: SizedBox(
                          height: 33,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              bool confirmStatusUpdate = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Update Status'),
                                    content: Text(
                                        'Are you sure you want to move this order to $nextStatus? This action will notify this customer and cannot be reversed.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(false);
                                        },
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirmStatusUpdate) {
                                await _updateOrderStatus(
                                    order['Order_ID'], nextStatus);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              backgroundColor: buttonColor,
                            ),
                            child: Text(
                              buttonText,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
