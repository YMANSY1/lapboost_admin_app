import 'package:flutter/material.dart';
import 'package:lapboost_admin_app/models/sql_service.dart';
import 'package:mysql1/mysql1.dart';

import 'auth_screen.dart';

class SettingsPage extends StatefulWidget {
  ResultRow user; // Pass the employee's email as an argument.

  SettingsPage({super.key, required this.user});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      final currentPassword = _currentPasswordController.text;
      final newPassword = _newPasswordController.text;

      final conn = await SqlService.getConnection();
      await conn.query('''
      UPDATE employees
      SET password= ?
      WHERE Employee_ID= ?
      ''', [newPassword, widget.user['Employee_ID']]);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => AuthScreen()),
          (route) => false);

      // Clear the text fields after updating the password.
      _currentPasswordController.clear();
      _newPasswordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.user['Role'] == 'Technician'
          ? AppBar(
              title: const Text('Settings'),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'Theme & Language',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              // Theme selection
              ListTile(
                title: const Text('Theme'),
                trailing: DropdownButton<String>(
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'Light',
                      child: Text('Light'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Dark',
                      child: Text('Dark'),
                    ),
                  ],
                  onChanged: (value) {},
                  hint: const Text('Select theme'),
                ),
              ),
              // Language selection
              ListTile(
                title: const Text('Language'),
                trailing: DropdownButton<String>(
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'English',
                      child: Text('English'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Arabic',
                      child: Text('Arabic'),
                    ),
                  ],
                  onChanged: (value) {},
                  hint: const Text('Select language'),
                ),
              ),
              const Divider(),
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'Account Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              // Email display
              TextField(
                controller: TextEditingController(text: widget.user['email']),
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              // Current password field
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  } else if (value != widget.user['password']) {
                    return 'Incorrect password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // New password field
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  } else if (value == widget.user['password']) {
                    return 'Please choose a different password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Update password button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _updatePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Save Account Data',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logged out successfully'),
                          ),
                        );
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => AuthScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
