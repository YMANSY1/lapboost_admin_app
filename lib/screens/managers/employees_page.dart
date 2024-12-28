import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lapboost_admin_app/models/sql_service.dart';
import 'package:mysql1/mysql1.dart';

class EmployeesPage extends StatefulWidget {
  final ResultRow user;

  const EmployeesPage({super.key, required this.user});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  List<Map<String, dynamic>> currentEmployees = [];
  List<Map<String, dynamic>> pastEmployees = [];
  bool isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _startDateController = TextEditingController();
  final _salaryController = TextEditingController();
  final _departmentController = TextEditingController();
  final _workEmailController = TextEditingController();
  final _workPasswordController = TextEditingController();
  final _roleController = TextEditingController();
  final _addressController = TextEditingController(); // Address Controller

  Future<void> _fetchCurrentEmployees() async {
    final conn = await SqlService.getConnection();
    final results = await conn.query('''
  SELECT e.Employee_ID, e.Employee_FirstName, e.Employee_LastName, e.Phone_Number, e.Address, 
         e.Start_Date, e.Date_Left, e.Salary, e.Department, e.Role, e.email, e.password,
         (SELECT COUNT(*)
          FROM orders o
          WHERE o.Employee_ID = e.Employee_ID AND o.Order_Status = 'Received') AS CompletedJobs
  FROM employees e
  WHERE e.Date_Left IS NULL;
''');

    setState(() {
      currentEmployees = results.map((row) => row.fields).toList();
      isLoading = false;
    });
  }

  Future<void> _fetchPastEmployees() async {
    final conn = await SqlService.getConnection();
    final results = await conn.query('''
      SELECT e.Employee_ID, e.Employee_FirstName, e.Employee_LastName, e.Phone_Number, e.Address,
             e.Start_Date, e.Date_Left, e.Salary, e.Department, e.Role, e.email, e.password,
             (SELECT COUNT(*)
              FROM orders o
              WHERE o.Employee_ID = e.Employee_ID AND o.Order_Status = 'Received') AS CompletedJobs
      FROM employees e
      WHERE e.Date_Left IS NOT NULL;
    ''');

    setState(() {
      pastEmployees = results.map((row) => row.fields).toList();
      isLoading = false;
    });
    print(pastEmployees);
  }

  Future<void> _addNewEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    final conn = await SqlService.getConnection();
    // First, insert into the employees table, including the address
    _clearFormFields();
    _fetchCurrentEmployees();
    Navigator.of(context).pop();
  }

  void _clearFormFields() {
    _firstNameController.clear();
    _lastNameController.clear();
    _phoneNumberController.clear();
    _startDateController.clear();
    _salaryController.clear();
    _departmentController.clear();
    _workEmailController.clear();
    _workPasswordController.clear();
    _roleController.clear();
    _addressController.clear(); // Clear address field
  }

  void _showAddEmployeeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Employee'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a first name' : null,
                  ),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a last name' : null,
                  ),
                  TextFormField(
                    controller: _phoneNumberController,
                    decoration:
                        const InputDecoration(labelText: 'Phone Number'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a phone number' : null,
                  ),
                  TextFormField(
                    controller: _startDateController,
                    decoration: const InputDecoration(
                        labelText: 'Start Date (YYYY-MM-DD)'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a start date' : null,
                  ),
                  TextFormField(
                    controller: _salaryController,
                    decoration: const InputDecoration(labelText: 'Salary'),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a salary' : null,
                  ),
                  TextFormField(
                    controller: _departmentController,
                    decoration: const InputDecoration(labelText: 'Department'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a department' : null,
                  ),
                  TextFormField(
                    controller: _roleController,
                    decoration: const InputDecoration(labelText: 'Role'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a role' : null,
                  ),
                  TextFormField(
                    controller: _workEmailController,
                    decoration: const InputDecoration(labelText: 'Work Email'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a work email' : null,
                  ),
                  TextFormField(
                    controller: _workPasswordController,
                    decoration:
                        const InputDecoration(labelText: 'Work Password'),
                    obscureText: true,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a password' : null,
                  ),
                  TextFormField(
                    controller: _addressController, // Address field
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter an address' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _addNewEmployee,
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editEmployee(Map<String, dynamic> employee) async {
    _firstNameController.text = employee['Employee_FirstName'] ?? '';
    _lastNameController.text = employee['Employee_LastName'] ?? '';
    _phoneNumberController.text = employee['Phone_Number'] ?? '';
    _startDateController.text = employee['Start_Date'].toString() ?? '';
    _salaryController.text = employee['Salary'].toString() ?? '';
    _departmentController.text = employee['Department'] ?? '';
    _workEmailController.text = employee['email'] ?? '';
    _workPasswordController.text = employee['password'] ?? '';
    _addressController.text = employee['Address'] ?? '';

    print(employee);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Employee'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a first name' : null,
                  ),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a last name' : null,
                  ),
                  TextFormField(
                    controller: _phoneNumberController,
                    decoration:
                        const InputDecoration(labelText: 'Phone Number'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a phone number' : null,
                  ),
                  TextFormField(
                    controller: _startDateController,
                    decoration: const InputDecoration(
                        labelText: 'Start Date (YYYY-MM-DD)'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a start date' : null,
                  ),
                  TextFormField(
                    controller: _salaryController,
                    decoration: const InputDecoration(labelText: 'Salary'),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a salary' : null,
                  ),
                  TextFormField(
                    controller: _departmentController,
                    decoration: const InputDecoration(labelText: 'Department'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a department' : null,
                  ),
                  TextFormField(
                    controller: _workEmailController,
                    decoration: const InputDecoration(labelText: 'Work Email'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a work email' : null,
                  ),
                  TextFormField(
                    controller: _workPasswordController,
                    decoration:
                        const InputDecoration(labelText: 'Work Password'),
                    obscureText: true,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a password' : null,
                  ),
                  TextFormField(
                    controller: _addressController, // Address field
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter an address' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                final conn = await SqlService.getConnection();
                await conn.query('''
                  UPDATE employees
                  SET Employee_FirstName = ?, Employee_LastName = ?, Phone_Number = ?, Start_Date = ?, Salary = ?, Department = ?, email = ?, password = ?, Address = ?
                  WHERE Employee_ID = ?
                ''', [
                  _firstNameController.text,
                  _lastNameController.text,
                  _phoneNumberController.text,
                  _startDateController.text,
                  double.parse(_salaryController.text),
                  _departmentController.text,
                  _workEmailController.text,
                  _workPasswordController.text,
                  _addressController.text,
                  employee['Employee_ID']
                ]);

                _clearFormFields();
                _fetchCurrentEmployees();
                Navigator.of(context).pop();
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _terminateEmployee(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Do you really want to terminate this employee?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final conn = await SqlService.getConnection();
                await conn.query('''
                  UPDATE employees
                  SET Date_Left = ?
                  WHERE Employee_ID = ?
                ''', [
                  DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  employee['Employee_ID']
                ]);

                Navigator.of(context).pop();
                _fetchCurrentEmployees();
              },
              child: const Text('Terminate'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchCurrentEmployees();
    _fetchPastEmployees();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            const Material(
              color: Colors.white,
              child: TabBar(
                tabs: [
                  Tab(text: 'Current Employees'),
                  Tab(text: 'Past Employees'),
                ],
                indicatorColor: Colors.blue,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddEmployeeDialog,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  backgroundColor: Colors.white, // Light blue accent color
                ),
                icon: const Icon(
                  Icons.add,
                  color: Colors.lightBlueAccent,
                ),
                label: const Text('Add New Employee'),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: currentEmployees.length,
                          itemBuilder: (context, index) {
                            final employee = currentEmployees[index];
                            return ListTile(
                              title: Text(
                                  '${employee['Employee_FirstName']} ${employee['Employee_LastName']}'),
                              subtitle: Text(
                                  'Salary: ${employee['Salary']}EGP | Address: ${employee['Address']} | Completed Jobs: ${employee['CompletedJobs']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      onPressed: () {
                                        _editEmployee(employee);
                                      },
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      )),
                                  IconButton(
                                      onPressed: () async {
                                        _terminateEmployee(employee);
                                      },
                                      icon: const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                      )),
                                ],
                              ),
                            );
                          },
                        ),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: pastEmployees.length,
                          itemBuilder: (context, index) {
                            final employee = pastEmployees[index];
                            return ListTile(
                              title: Text(
                                  '${employee['Employee_FirstName']} ${employee['Employee_LastName']}'),
                              subtitle: Text(
                                  'Salary: ${employee['Salary']}EGP | Address: ${employee['Address']} | Completed Jobs: ${employee['CompletedJobs']}'),
                              trailing: IconButton(
                                  onPressed: () async {
                                    // Show the confirmation dialog
                                    bool isConfirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text('Are you sure?'),
                                              content: Text(
                                                  'Do you want to rehire this employee?'),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop(
                                                        false); // Dismiss the dialog with 'false'
                                                  },
                                                  child: Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop(
                                                        true); // Dismiss the dialog with 'true'
                                                  },
                                                  child: Text('Yes'),
                                                ),
                                              ],
                                            );
                                          },
                                        ) ??
                                        false;

                                    // If confirmed, execute the update
                                    if (isConfirmed) {
                                      try {
                                        final conn =
                                            await SqlService.getConnection();
                                        await conn.query('''
        UPDATE employees
        SET Date_Left = NULL
        WHERE Employee_ID = ?
      ''', [employee['Employee_ID']]);

                                        // Optionally, show a success message using a Scaffold
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Employee rehired successfully!')),
                                        );
                                      } catch (e) {
                                        // Handle error
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error rehiring employee: $e')),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
