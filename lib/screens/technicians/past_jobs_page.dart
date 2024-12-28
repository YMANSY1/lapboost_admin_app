import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lapboost_admin_app/models/sql_service.dart';
import 'package:mysql1/mysql1.dart';

class PastJobsPage extends StatefulWidget {
  final ResultRow user;

  const PastJobsPage({super.key, required this.user});

  @override
  State<PastJobsPage> createState() => _PastJobsPageState();
}

class _PastJobsPageState extends State<PastJobsPage> {
  Future<List<Map<String, dynamic>>> _fetchPastJobs() async {
    final conn = await SqlService.getConnection();
    try {
      // Fetch all orders for the technician (employee) with status 'Received'
      final orders = await conn.query(
          '''SELECT * FROM orders WHERE Employee_ID = ? AND Order_Status = 'Received' ''',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Building the UI
        future: _fetchPastJobs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(child: Text('No past jobs found.'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index]['order'];
              final orderDetails = orders[index]['details'];

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
                          'Completed on ${DateFormat('MMMM dd, yyyy').format(order['Date_Delivered'])}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Text(
                          'Status: Received',
                          style: TextStyle(fontSize: 14, color: Colors.green),
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
