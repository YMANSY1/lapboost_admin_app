import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lapboost_admin_app/screens/managers/main_page.dart';
import 'package:lapboost_admin_app/screens/technicians/technician_main_page.dart';

import '../models/sql_service.dart';

class AuthScreen extends StatefulWidget {
  AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();

  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  var isObscured = true.obs;

  Widget emailField() {
    return TextFormField(
      controller: emailController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Email',
        prefixIcon: Icon(Icons.account_box),
        errorStyle: TextStyle(color: Colors.red),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an email';
        } else if (!RegExp(
                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
            .hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget passwordField() {
    return Obx(() {
      return TextFormField(
        controller: passwordController,
        obscureText: isObscured.value,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            onPressed: () {
              isObscured.value = !(isObscured.value);
            },
            icon: Icon(
              isObscured.value
                  ? Icons.remove_red_eye_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
          errorStyle: const TextStyle(color: Colors.red),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a password';
          }
          return null;
        },
      );
    });
  }

  Widget loginForm() {
    return Column(
      mainAxisSize:
          MainAxisSize.min, // Ensures the form takes minimal vertical space
      children: [
        const Text(
          'Login',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        emailField(),
        const SizedBox(height: 16),
        passwordField(),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final user = await SqlService.getUser(
                emailController.text.trim(),
                passwordController.text.trim(),
              );

              if (user != null) {
                // Navigate to MainPage if user is found
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => user['Role'] == 'Manager'
                          ? MainPage(
                              user: user,
                            )
                          : TechnicianMainPage(
                              user: user,
                            ),
                    ),
                    (route) => false);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unable to find User')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF33ddc5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          child: const Text('Sign in'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to the LapBoost App!'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth:
                  400, // Optional: Limit the max width for better aesthetics
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: loginForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
