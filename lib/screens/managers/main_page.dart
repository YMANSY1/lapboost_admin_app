import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lapboost_admin_app/screens/managers/employees_page.dart';
import 'package:lapboost_admin_app/screens/managers/orders_page.dart';
import 'package:lapboost_admin_app/screens/managers/stock_page.dart';
import 'package:lapboost_admin_app/screens/settings_page.dart';
import 'package:mysql1/mysql1.dart';

class MainPage extends StatefulWidget {
  final ResultRow user;

  const MainPage({super.key, required this.user});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // Manage the selected index
  int _selectedIndex = 0;

  // This will hold the dynamic title
  RxString titleText = ''.obs;

  @override
  void initState() {
    super.initState();
    // Initialize the title with the default message
    titleText.value = 'Welcome ${widget.user['Employee_FirstName']}!';
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = <Widget>[
      OrdersPage(user: widget.user),
      EmployeesPage(user: widget.user),
      StockPage(user: widget.user),
      SettingsPage(user: widget.user),
    ];

    // Handle bottom navigation item taps
    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
        switch (index) {
          case 0:
            titleText.value = 'Welcome ${widget.user['Employee_FirstName']}!';
            break;
          case 1:
            titleText.value = 'Employees';
            break;
          case 2:
            titleText.value = 'Stock';
            break;
          case 3:
            titleText.value = 'Settings';
            break;
          default:
            titleText.value = 'Welcome ${widget.user['Employee_Name']}';
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Obx(() => Text(titleText.value)), // Dynamic app bar title
      ),
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Employees',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped, // Switch pages
      ),
    );
  }
}
